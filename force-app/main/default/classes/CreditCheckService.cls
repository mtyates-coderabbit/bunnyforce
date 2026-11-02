/**
 * Credit checks on order activation and maintenance of Account.Open_Order_Value__c.
 *
 * Order of execution: evaluateActivations() runs in Order before-update so the status is set
 * without extra DML. recalculateOpenOrderValue() runs in Order after-update/delete, and the
 * resulting Account update lets AccountTriggerHandler derive Credit_Hold__c.
 */
public inherited sharing class CreditCheckService {
    private static final String ORDER_HANDLER = 'Order';

    private final CreditPolicy policy;

    public CreditCheckService() {
        this(new CreditPolicy());
    }

    @TestVisible
    private CreditCheckService(CreditPolicy policy) {
        this.policy = policy;
    }

    /**
     * Sets Credit_Check_Status__c on orders that are being activated. Orders for the same
     * account are evaluated cumulatively so a bulk activation cannot exceed the limit.
     * Mutates the records; intended for before-update context.
     */
    public void evaluateActivations(List<Order> activatingOrders) {
        if (activatingOrders == null || activatingOrders.isEmpty()) {
            return;
        }
        Set<Id> accountIds = new Set<Id>();
        for (Order activating : activatingOrders) {
            accountIds.add(activating.AccountId);
        }
        // Credit checks must apply regardless of the activating user's access to credit fields.
        Map<Id, Account> accountsById = new AccountsSelector(System.AccessLevel.SYSTEM_MODE).selectByIds(accountIds);

        Map<Id, Decimal> projectedByAccount = new Map<Id, Decimal>();
        for (Order activating : activatingOrders) {
            Account customer = accountsById.get(activating.AccountId);
            Decimal currentOpen = projectedByAccount.containsKey(customer.Id)
                ? projectedByAccount.get(customer.Id)
                : CreditPolicy.nullToZero(customer.Open_Order_Value__c);
            Decimal projected = currentOpen + CreditPolicy.nullToZero(activating.TotalAmount);

            if (customer.Credit_Hold__c || policy.isOverLimit(projected, customer.Credit_Limit__c)) {
                activating.Credit_Check_Status__c = OrderConstants.CREDIT_ON_HOLD;
            } else {
                activating.Credit_Check_Status__c = OrderConstants.CREDIT_APPROVED;
                projectedByAccount.put(customer.Id, projected);
            }
        }
    }

    /**
     * Releases held orders that now fit within the account's credit limit, oldest first, and
     * hands them to fulfillment.
     *
     * Called from Account before-update with the in-flight Trigger.new records: the released
     * value is added to Open_Order_Value__c on those records directly, so no Account DML is
     * needed. The Order handler is bypassed while statuses are updated because its after-update
     * recalculation would try to update these same accounts mid-trigger
     * (SELF_REFERENCE_FROM_TRIGGER).
     */
    public void releaseHeldOrders(List<Account> customers) {
        if (customers == null || customers.isEmpty()) {
            return;
        }
        Map<Id, Account> customersById = new Map<Id, Account>(customers);
        // Releasing holds is automation triggered by a limit change, not a user query.
        List<Order> heldOrders = new OrdersSelector(System.AccessLevel.SYSTEM_MODE)
            .selectHeldByAccountIds(customersById.keySet());

        List<Order> released = new List<Order>();
        for (Order held : heldOrders) {
            Account customer = customersById.get(held.AccountId);
            Decimal projected =
                CreditPolicy.nullToZero(customer.Open_Order_Value__c) + CreditPolicy.nullToZero(held.TotalAmount);
            if (!policy.isOverLimit(projected, customer.Credit_Limit__c)) {
                customer.Open_Order_Value__c = projected;
                released.add(new Order(Id = held.Id, Credit_Check_Status__c = OrderConstants.CREDIT_APPROVED));
            }
        }
        if (released.isEmpty()) {
            return;
        }

        TriggerHandler.bypass(ORDER_HANDLER);
        try {
            update as system released;
        } finally {
            TriggerHandler.clearBypass(ORDER_HANDLER);
        }
        OrderFulfillmentQueueable.enqueue(new Map<Id, Order>(released).keySet());
    }

    /**
     * Recomputes Open_Order_Value__c for the given accounts and updates only those that changed.
     */
    public void recalculateOpenOrderValue(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        Map<Id, Decimal> openByAccount = new OrdersSelector(System.AccessLevel.SYSTEM_MODE)
            .sumOpenOrderValueByAccount(accountIds);
        Map<Id, Account> accountsById = new AccountsSelector(System.AccessLevel.SYSTEM_MODE).selectByIds(accountIds);

        List<Account> changed = new List<Account>();
        for (Account customer : accountsById.values()) {
            Decimal openValue = CreditPolicy.nullToZero(openByAccount.get(customer.Id));
            if (customer.Open_Order_Value__c != openValue) {
                changed.add(new Account(Id = customer.Id, Open_Order_Value__c = openValue));
            }
        }
        if (!changed.isEmpty()) {
            update as system changed;
        }
    }
}

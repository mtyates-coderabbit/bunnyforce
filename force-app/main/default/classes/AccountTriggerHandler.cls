/**
 * Account trigger logic. Derives Credit_Hold__c from the credit fields so the flag is always
 * consistent, whichever process changed the open value or the limit.
 */
public inherited sharing class AccountTriggerHandler extends TriggerHandler {
    private final CreditPolicy policy;
    private final CreditCheckService creditCheck;

    public AccountTriggerHandler() {
        super('Account');
        this.policy = new CreditPolicy();
        this.creditCheck = new CreditCheckService();
    }

    protected override void beforeInsert() {
        applyCreditHold((List<Account>) newRecords);
    }

    protected override void beforeUpdate() {
        List<Account> creditChanged = new List<Account>();
        List<Account> limitIncreased = new List<Account>();
        for (Account customer : (List<Account>) newRecords) {
            if (isChanged(customer, Account.Open_Order_Value__c) || isChanged(customer, Account.Credit_Limit__c)) {
                creditChanged.add(customer);
            }
            if (isLimitIncreased(customer)) {
                limitIncreased.add(customer);
            }
        }
        // Release first so the hold flag below reflects the newly approved order value.
        creditCheck.releaseHeldOrders(limitIncreased);
        applyCreditHold(creditChanged);
    }

    /**
     * A limit increase, or removing the limit entirely, may let held orders through.
     */
    private Boolean isLimitIncreased(Account customer) {
        if (!isChanged(customer, Account.Credit_Limit__c)) {
            return false;
        }
        Decimal previousLimit = ((Account) oldMap.get(customer.Id)).Credit_Limit__c;
        return customer.Credit_Limit__c == null || previousLimit == null || customer.Credit_Limit__c > previousLimit;
    }

    private void applyCreditHold(List<Account> customers) {
        for (Account customer : customers) {
            customer.Credit_Hold__c = policy.isOverLimit(customer.Open_Order_Value__c, customer.Credit_Limit__c);
        }
    }
}

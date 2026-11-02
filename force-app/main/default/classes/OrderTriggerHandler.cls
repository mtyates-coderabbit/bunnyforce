/**
 * Order trigger logic: credit check on activation, Open_Order_Value__c maintenance and
 * hand-off of approved orders to fulfillment.
 */
public inherited sharing class OrderTriggerHandler extends TriggerHandler {
    private final CreditCheckService creditCheck;

    public OrderTriggerHandler() {
        super('Order');
        this.creditCheck = new CreditCheckService();
    }

    protected override void beforeUpdate() {
        List<Order> activating = new List<Order>();
        for (Order changed : (List<Order>) newRecords) {
            if (changed.Status == OrderConstants.STATUS_ACTIVATED && isChanged(changed, Order.Status)) {
                activating.add(changed);
            }
        }
        creditCheck.evaluateActivations(activating);
    }

    protected override void afterUpdate() {
        Set<Id> accountsToRecalculate = new Set<Id>();
        Set<Id> readyForFulfillment = new Set<Id>();
        for (Order changed : (List<Order>) newRecords) {
            if (affectsOpenOrderValue(changed)) {
                accountsToRecalculate.add(changed.AccountId);
            }
            if (isNewlyApproved(changed)) {
                readyForFulfillment.add(changed.Id);
            }
        }
        creditCheck.recalculateOpenOrderValue(accountsToRecalculate);
        OrderFulfillmentQueueable.enqueue(readyForFulfillment);

        List<Order> failed = new List<Order>();
        for (Order o : (List<Order>) newRecords) {
            if (o.Fulfillment_Status__c == 'Failed') {
                failed.add(o);
            }
        }
        if (!failed.isEmpty()) {
            FulfillmentRetryService.retryFailedOrders(failed);
        }
        Logger.flush();
    }

    protected override void afterDelete() {
        Set<Id> accountIds = new Set<Id>();
        for (Order removed : (List<Order>) oldMap.values()) {
            accountIds.add(removed.AccountId);
        }
        creditCheck.recalculateOpenOrderValue(accountIds);
    }

    private Boolean affectsOpenOrderValue(Order changed) {
        return isChanged(changed, Order.Status) ||
            isChanged(changed, Order.Credit_Check_Status__c) ||
            isChanged(changed, Order.Fulfillment_Status__c) ||
            isChanged(changed, Order.TotalAmount);
    }

    private Boolean isNewlyApproved(Order changed) {
        return changed.Credit_Check_Status__c == OrderConstants.CREDIT_APPROVED &&
            isChanged(changed, Order.Credit_Check_Status__c) &&
            changed.Fulfillment_Status__c == OrderConstants.FULFILLMENT_NOT_SUBMITTED;
    }
}

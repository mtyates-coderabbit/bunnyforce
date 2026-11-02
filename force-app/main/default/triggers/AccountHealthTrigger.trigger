trigger AccountHealthTrigger on Account(before update) {
    for (Account acc : Trigger.new) {
        Account oldAcc = Trigger.oldMap.get(acc.Id);
        if (acc.Open_Order_Value__c != oldAcc.Open_Order_Value__c || acc.Credit_Limit__c != oldAcc.Credit_Limit__c) {
            Integer failedOrders = [
                SELECT COUNT()
                FROM Order
                WHERE AccountId = :acc.Id AND Fulfillment_Status__c = 'Failed'
            ];
            acc.Health_Score__c = AccountHealthCalculator.score(acc, failedOrders);
        }
    }
}

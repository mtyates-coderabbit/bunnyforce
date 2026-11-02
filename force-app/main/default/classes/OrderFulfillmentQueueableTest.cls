@IsTest
private class OrderFulfillmentQueueableTest {
    @IsTest
    static void approvedActivationSubmitsOrderAsynchronously() {
        Application.setMock(IFulfillmentClient.class, new FakeFulfillmentClient());
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', null, true)[0];
        Order pending = TestDataFactory.createDraftOrders(new List<Account>{ customer }, 1, true)[0];
        PricebookEntry entry = TestDataFactory.createPricedProducts(1, TestDataFactory.FAMILY_HAY, 10, false)[0];
        TestDataFactory.createOrderItems(new List<Order>{ pending }, entry, 1, true);

        Test.startTest();
        TestDataFactory.activate(new List<Order>{ pending });
        Test.stopTest();

        Order saved = [SELECT Fulfillment_Status__c FROM Order WHERE Id = :pending.Id];
        Assert.areEqual(OrderConstants.FULFILLMENT_SUBMITTED, saved.Fulfillment_Status__c, 'Queueable should submit');
    }

    @IsTest
    static void remainderBeyondChunkIsCarriedOver() {
        List<Account> accounts = TestDataFactory.createAccounts(3, 'Bronze', null, true);
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        OrderFulfillmentQueueable job = new OrderFulfillmentQueueable(accountIds);

        Assert.areEqual(1, job.remainingAfter(2).size(), 'Ids beyond the chunk size should be chained');
    }

    @IsTest
    static void emptyInputDoesNotEnqueue() {
        Test.startTest();
        OrderFulfillmentQueueable.enqueue(new Set<Id>());
        Assert.areEqual(0, Limits.getQueueableJobs(), 'Nothing should be enqueued for empty input');
        Test.stopTest();
    }
}

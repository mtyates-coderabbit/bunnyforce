@IsTest
private class OrderFulfillmentServiceTest {
    @IsTest
    static void successfulSubmissionRecordsFulfillmentId() {
        FakeFulfillmentClient fake = new FakeFulfillmentClient();
        Order pending = createApprovedOrder(false);

        new OrderFulfillmentService(fake).submit(new Set<Id>{ pending.Id });

        Order saved = reload(pending);
        Assert.areEqual(OrderConstants.FULFILLMENT_SUBMITTED, saved.Fulfillment_Status__c, 'Order should be submitted');
    }

    @IsTest
    static void providerRejectionMarksOrderFailedAndLogs() {
        FakeFulfillmentClient fake = new FakeFulfillmentClient();
        fake.shouldFail = true;
        Order pending = createApprovedOrder(false);

        Test.startTest();
        new OrderFulfillmentService(fake).submit(new Set<Id>{ pending.Id });
        Logger.flush();
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Log_Entry__c WHERE Level__c = 'ERROR'], 'Failure should be logged');
    }

    @IsTest
    static void perishableOrdersShipFromColdWarehouse() {
        BunnyforceSettings.overrides.put(BunnyforceSettings.PERISHABLE_WAREHOUSE_CODE, 'COLD-1');
        FakeFulfillmentClient fake = new FakeFulfillmentClient();
        Order pending = createApprovedOrder(true);

        new OrderFulfillmentService(fake).submit(new Set<Id>{ pending.Id });

        Assert.areEqual('COLD-1', fake.received[0].warehouseCode, 'Perishable lines require the cold warehouse');
    }

    @IsTest
    static void alreadySubmittedOrdersAreSkipped() {
        FakeFulfillmentClient fake = new FakeFulfillmentClient();
        Order pending = createApprovedOrder(false);
        update new Order(Id = pending.Id, Fulfillment_Status__c = OrderConstants.FULFILLMENT_SUBMITTED);

        new OrderFulfillmentService(fake).submit(new Set<Id>{ pending.Id });

        Assert.areEqual(0, fake.received.size(), 'Submitted orders must not be sent twice');
    }

    private static Order createApprovedOrder(Boolean perishable) {
        // The activation trigger enqueues fulfillment; stub it so only the explicit submit() runs.
        Application.setMock(IFulfillmentClient.class, new FakeFulfillmentClient());
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', null, true)[0];
        Order pending = TestDataFactory.createDraftOrders(new List<Account>{ customer }, 1, true)[0];
        PricebookEntry entry = TestDataFactory.createPricedProducts(1, TestDataFactory.FAMILY_HAY, 25, perishable)[0];
        TestDataFactory.createOrderItems(new List<Order>{ pending }, entry, 4, true);
        TestDataFactory.activate(new List<Order>{ pending });
        return pending;
    }

    private static Order reload(Order pending) {
        return [SELECT Fulfillment_Status__c, External_Fulfillment_Id__c FROM Order WHERE Id = :pending.Id];
    }
}

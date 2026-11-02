@IsTest
private class OrderTriggerHandlerTest {
    @IsTest
    static void deliveryReleasesOpenOrderValue() {
        Application.setMock(IFulfillmentClient.class, new FakeFulfillmentClient());
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', 10000, true)[0];
        Order pending = TestDataFactory.createDraftOrders(new List<Account>{ customer }, 1, true)[0];
        PricebookEntry entry = TestDataFactory.createPricedProducts(1, TestDataFactory.FAMILY_HAY, 100, false)[0];
        TestDataFactory.createOrderItems(new List<Order>{ pending }, entry, 5, true);
        TestDataFactory.activate(new List<Order>{ pending });

        update new Order(Id = pending.Id, Fulfillment_Status__c = OrderConstants.FULFILLMENT_DELIVERED);

        Assert.areEqual(
            Decimal.valueOf(0),
            [SELECT Open_Order_Value__c FROM Account WHERE Id = :customer.Id].Open_Order_Value__c,
            'Delivered orders are not open'
        );
    }

    @IsTest
    static void heldOrdersAreNotSentToFulfillment() {
        FakeFulfillmentClient fake = new FakeFulfillmentClient();
        Application.setMock(IFulfillmentClient.class, fake);
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', 1, true)[0];
        Order pending = TestDataFactory.createDraftOrders(new List<Account>{ customer }, 1, true)[0];
        PricebookEntry entry = TestDataFactory.createPricedProducts(1, TestDataFactory.FAMILY_HAY, 100, false)[0];
        TestDataFactory.createOrderItems(new List<Order>{ pending }, entry, 5, true);

        Test.startTest();
        TestDataFactory.activate(new List<Order>{ pending });
        Test.stopTest();

        Assert.areEqual(0, fake.received.size(), 'Orders on credit hold must not be submitted');
    }

    @IsTest
    static void deletingDraftOrderKeepsOpenValueAtZero() {
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', 10000, true)[0];
        Order draft = TestDataFactory.createDraftOrders(new List<Account>{ customer }, 1, true)[0];

        delete draft;

        Assert.areEqual(
            Decimal.valueOf(0),
            [SELECT Open_Order_Value__c FROM Account WHERE Id = :customer.Id].Open_Order_Value__c,
            'Drafts never count'
        );
    }
}

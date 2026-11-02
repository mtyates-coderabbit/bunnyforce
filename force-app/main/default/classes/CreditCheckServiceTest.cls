@IsTest
private class CreditCheckServiceTest {
    private static final Decimal LINE_PRICE = 100;

    @IsTest
    static void activationWithinLimitIsApproved() {
        Order pending = createOrderWithLine(5000, 10);

        Test.startTest();
        TestDataFactory.activate(new List<Order>{ pending });
        Test.stopTest();

        Assert.areEqual(
            OrderConstants.CREDIT_APPROVED,
            reload(pending).Credit_Check_Status__c,
            'Order is within limit'
        );
    }

    @IsTest
    static void activationOverLimitIsHeld() {
        Order pending = createOrderWithLine(500, 10);

        TestDataFactory.activate(new List<Order>{ pending });

        Assert.areEqual(
            OrderConstants.CREDIT_ON_HOLD,
            reload(pending).Credit_Check_Status__c,
            '1000 exceeds 500 limit'
        );
    }

    @IsTest
    static void approvedActivationUpdatesOpenOrderValue() {
        Order pending = createOrderWithLine(5000, 10);

        TestDataFactory.activate(new List<Order>{ pending });

        Account customer = [SELECT Open_Order_Value__c FROM Account WHERE Id = :pending.AccountId];
        Assert.areEqual(
            Decimal.valueOf(1000),
            customer.Open_Order_Value__c,
            'Approved order value should count toward open value'
        );
    }

    @IsTest
    static void bulkActivationIsEvaluatedCumulatively() {
        stubCollaborators();
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', 2500, true)[0];
        List<Order> orders = TestDataFactory.createDraftOrders(new List<Account>{ customer }, 5, true);
        PricebookEntry entry = TestDataFactory.createPricedProducts(
            1,
            TestDataFactory.FAMILY_HAY,
            LINE_PRICE,
            false
        )[0];
        TestDataFactory.createOrderItems(orders, entry, 10, true);

        TestDataFactory.activate(orders);

        Integer held = [
            SELECT COUNT()
            FROM Order
            WHERE AccountId = :customer.Id AND Credit_Check_Status__c = :OrderConstants.CREDIT_ON_HOLD
        ];
        Assert.areEqual(3, held, 'Only two 1000 orders fit in a 2500 limit with 10% grace');
    }

    private static void stubCollaborators() {
        BunnyforceSettings.overrides.put(BunnyforceSettings.CREDIT_HOLD_GRACE_PERCENT, '10');
        Application.setMock(IFulfillmentClient.class, new FakeFulfillmentClient());
    }

    private static Order createOrderWithLine(Decimal creditLimit, Decimal quantity) {
        stubCollaborators();
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', creditLimit, true)[0];
        Order pending = TestDataFactory.createDraftOrders(new List<Account>{ customer }, 1, true)[0];
        PricebookEntry entry = TestDataFactory.createPricedProducts(
            1,
            TestDataFactory.FAMILY_HAY,
            LINE_PRICE,
            false
        )[0];
        TestDataFactory.createOrderItems(new List<Order>{ pending }, entry, quantity, true);
        return pending;
    }

    private static Order reload(Order pending) {
        return [SELECT Credit_Check_Status__c FROM Order WHERE Id = :pending.Id];
    }
}

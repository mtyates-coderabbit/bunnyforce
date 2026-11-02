@IsTest
private class CreditHoldReleaseTest {
    private static final Decimal ORDER_VALUE = 1000;
    private static final Decimal LOW_LIMIT = 500;

    private static void stubCollaborators(FakeFulfillmentClient fake) {
        BunnyforceSettings.overrides.put(BunnyforceSettings.CREDIT_HOLD_GRACE_PERCENT, '0');
        Application.setMock(IFulfillmentClient.class, fake);
    }

    @IsTest
    static void raisingLimitReleasesOldestOrdersThatFit() {
        stubCollaborators(new FakeFulfillmentClient());
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', LOW_LIMIT, true)[0];
        TestDataFactory.createHeldOrders(new List<Account>{ customer }, 3, ORDER_VALUE);

        update new Account(Id = customer.Id, Credit_Limit__c = 2000);

        Integer approved = [
            SELECT COUNT()
            FROM Order
            WHERE AccountId = :customer.Id AND Credit_Check_Status__c = :OrderConstants.CREDIT_APPROVED
        ];
        Assert.areEqual(2, approved, 'Two 1000 orders fit in a 2000 limit; the third stays on hold');
    }

    @IsTest
    static void releasedValueCountsTowardOpenOrderValue() {
        stubCollaborators(new FakeFulfillmentClient());
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', LOW_LIMIT, true)[0];
        TestDataFactory.createHeldOrders(new List<Account>{ customer }, 3, ORDER_VALUE);

        update new Account(Id = customer.Id, Credit_Limit__c = 2000);

        Account saved = [SELECT Open_Order_Value__c, Credit_Hold__c FROM Account WHERE Id = :customer.Id];
        Assert.areEqual(Decimal.valueOf(2000), saved.Open_Order_Value__c, 'Released orders consume credit');
        Assert.isFalse(saved.Credit_Hold__c, 'Account is exactly at its limit, not over it');
    }

    @IsTest
    static void releasedOrdersAreSubmittedForFulfillment() {
        FakeFulfillmentClient fake = new FakeFulfillmentClient();
        stubCollaborators(fake);
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', LOW_LIMIT, true)[0];
        TestDataFactory.createHeldOrders(new List<Account>{ customer }, 1, ORDER_VALUE);

        Test.startTest();
        update new Account(Id = customer.Id, Credit_Limit__c = 5000);
        Test.stopTest();

        Assert.areEqual(1, fake.received.size(), 'Released order should be sent to the 3PL');
    }

    @IsTest
    static void loweringLimitReleasesNothing() {
        stubCollaborators(new FakeFulfillmentClient());
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', LOW_LIMIT, true)[0];
        TestDataFactory.createHeldOrders(new List<Account>{ customer }, 1, ORDER_VALUE);

        update new Account(Id = customer.Id, Credit_Limit__c = 100);

        Assert.areEqual(
            OrderConstants.CREDIT_ON_HOLD,
            [SELECT Credit_Check_Status__c FROM Order WHERE AccountId = :customer.Id].Credit_Check_Status__c,
            'A lower limit must not release held orders'
        );
    }

    @IsTest
    static void bulkLimitIncreaseReleasesAllAccounts() {
        stubCollaborators(new FakeFulfillmentClient());
        List<Account> accounts = TestDataFactory.createAccounts(200, 'Bronze', LOW_LIMIT, true);
        TestDataFactory.createHeldOrders(accounts, 1, ORDER_VALUE);

        for (Account customer : accounts) {
            customer.Credit_Limit__c = 5000;
        }
        update accounts;

        Assert.areEqual(
            200,
            [SELECT COUNT() FROM Order WHERE Credit_Check_Status__c = :OrderConstants.CREDIT_APPROVED],
            'Every account should have its held order released'
        );
    }
}

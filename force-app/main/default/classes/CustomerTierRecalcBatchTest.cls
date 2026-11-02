@IsTest
private class CustomerTierRecalcBatchTest {
    @IsTest
    static void promotesAccountsByTrailingRevenue() {
        BunnyforceSettings.overrides.put(BunnyforceSettings.TIER_THRESHOLD_SILVER, '500');
        Application.setMock(IFulfillmentClient.class, new FakeFulfillmentClient());
        List<Account> accounts = TestDataFactory.createAccounts(200, 'Bronze', null, true);
        List<Order> orders = TestDataFactory.createDraftOrders(accounts, 1, true);
        PricebookEntry entry = TestDataFactory.createPricedProducts(1, TestDataFactory.FAMILY_HAY, 100, false)[0];
        TestDataFactory.createOrderItems(orders, entry, 6, true);
        TestDataFactory.activate(orders);

        Test.startTest();
        Database.executeBatch(new CustomerTierRecalcBatch(), CustomerTierRecalcBatch.BATCH_SIZE);
        Test.stopTest();

        Assert.areEqual(200, [SELECT COUNT() FROM Account WHERE Customer_Tier__c = 'Silver'], '600 revenue is Silver');
    }

    @IsTest
    static void accountsWithoutRevenueDropToBronze() {
        Account customer = TestDataFactory.createAccounts(1, 'Gold', null, true)[0];

        Test.startTest();
        Database.executeBatch(new CustomerTierRecalcBatch());
        Test.stopTest();

        Assert.areEqual(
            'Bronze',
            [SELECT Customer_Tier__c FROM Account WHERE Id = :customer.Id].Customer_Tier__c,
            'No revenue'
        );
    }

    @IsTest
    static void scheduleNightlyRegistersJob() {
        Test.startTest();
        Id jobId = CustomerTierRecalcBatch.scheduleNightly();
        Test.stopTest();

        CronTrigger job = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(CustomerTierRecalcBatch.NIGHTLY_CRON, job.CronExpression, 'Job should use the nightly cron');
    }
}

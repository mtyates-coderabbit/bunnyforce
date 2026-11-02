@IsTest
private class AccountTriggerHandlerTest {
    @IsTest
    static void raisingCreditLimitReleasesHold() {
        BunnyforceSettings.overrides.put(BunnyforceSettings.CREDIT_HOLD_GRACE_PERCENT, '0');
        List<Account> accounts = TestDataFactory.createAccounts(200, 'Bronze', 100, false);
        for (Account customer : accounts) {
            customer.Open_Order_Value__c = 500;
        }
        insert accounts;

        for (Account customer : accounts) {
            customer.Credit_Limit__c = 1000;
        }
        update accounts;

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Account WHERE Credit_Hold__c = TRUE],
            'All 200 holds should be released'
        );
    }

    @IsTest
    static void unrelatedEditDoesNotRecalculateHold() {
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', 100, false)[0];
        customer.Open_Order_Value__c = 500;
        insert customer;
        // Simulate a manual override that should survive edits to unrelated fields.
        TriggerHandler.bypass('Account');
        update new Account(Id = customer.Id, Credit_Hold__c = false);
        TriggerHandler.clearBypass('Account');

        update new Account(Id = customer.Id, Description = 'Prefers Tuesday deliveries');

        Assert.isFalse(
            [SELECT Credit_Hold__c FROM Account WHERE Id = :customer.Id].Credit_Hold__c,
            'Hold not re-derived'
        );
    }
}

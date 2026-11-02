@IsTest
private class TriggerHandlerTest {
    private static final Decimal OVER_LIMIT_OPEN_VALUE = 5000;
    private static final Decimal CREDIT_LIMIT = 1000;

    @IsTest
    static void handlerRunsWhenEnabled() {
        Account customer = buildOverLimitAccount();

        insert customer;

        Assert.isTrue(reload(customer).Credit_Hold__c, 'Account handler should set credit hold when enabled');
    }

    @IsTest
    static void bypassSkipsHandler() {
        Account customer = buildOverLimitAccount();

        TriggerHandler.bypass('Account');
        insert customer;
        TriggerHandler.clearBypass('Account');

        Assert.isFalse(reload(customer).Credit_Hold__c, 'Bypassed handler must not run');
    }

    @IsTest
    static void disabledSettingSkipsHandler() {
        Account customer = buildOverLimitAccount();
        TriggerHandler.settingOverrides.put('Account', false);

        insert customer;

        Assert.isFalse(reload(customer).Credit_Hold__c, 'Handler disabled in Trigger_Setting__mdt must not run');
    }

    @IsTest
    static void outsideTriggerContextDoesNothing() {
        TriggerHandler handler = new TriggerHandler('Account');

        Assert.isFalse(handler.isEnabled(), 'Handler must be inert outside a trigger context');
    }

    private static Account buildOverLimitAccount() {
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', CREDIT_LIMIT, false)[0];
        customer.Open_Order_Value__c = OVER_LIMIT_OPEN_VALUE;
        return customer;
    }

    private static Account reload(Account customer) {
        return [SELECT Credit_Hold__c FROM Account WHERE Id = :customer.Id];
    }
}

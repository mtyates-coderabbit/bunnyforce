@IsTest
private class AccountCreditControllerTest {
    @IsTest
    static void salesOpsUserSeesCreditSummary() {
        User salesOps = TestDataFactory.createUserWithPermissionSet('Bunnyforce_Sales_Ops');
        Account customer = TestDataFactory.createAccounts(1, 'Gold', 1000, false)[0];
        customer.OwnerId = salesOps.Id;
        customer.Open_Order_Value__c = 250;
        insert customer;

        AccountCreditController.CreditSummary summary;
        System.runAs(salesOps) {
            summary = AccountCreditController.getCreditSummary(customer.Id);
        }

        Assert.areEqual(Decimal.valueOf(750), summary.availableCredit, 'Available credit is limit minus open value');
    }

    @IsTest
    static void utilizationIsPercentOfLimit() {
        User salesOps = TestDataFactory.createUserWithPermissionSet('Bunnyforce_Sales_Ops');
        Account customer = TestDataFactory.createAccounts(1, 'Gold', 1000, false)[0];
        customer.OwnerId = salesOps.Id;
        customer.Open_Order_Value__c = 250;
        insert customer;

        AccountCreditController.CreditSummary summary;
        System.runAs(salesOps) {
            summary = AccountCreditController.getCreditSummary(customer.Id);
        }

        Assert.areEqual(25.0, summary.utilizationPercent, 'Utilization should be 25%');
    }

    @IsTest
    static void userWithoutPermissionSetIsDenied() {
        User noAccess = TestDataFactory.createUserWithPermissionSet('Bunnyforce_Fulfillment_Integration');
        Account customer = TestDataFactory.createAccounts(1, 'Gold', 1000, false)[0];
        customer.OwnerId = noAccess.Id;
        insert customer;

        System.runAs(noAccess) {
            try {
                AccountCreditController.getCreditSummary(customer.Id);
                Assert.fail('Expected AuraHandledException without credit field access');
            } catch (AuraHandledException ex) {
                Assert.isTrue(ex.getMessage().contains('do not have access'), 'User should get a friendly error');
            }
        }
    }
}

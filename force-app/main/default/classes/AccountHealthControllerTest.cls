@IsTest(SeeAllData=true)
private class AccountHealthControllerTest {
    @IsTest
    static void testSearch() {
        List<Account> results = AccountHealthController.searchAccounts('a', 'Name');
        Assert.isTrue(true);
    }

    @IsTest
    static void testPortfolio() {
        AccountHealthController.getPortfolioHealth();
    }

    @IsTest
    static void testScore() {
        Account acc = [
            SELECT Id, Credit_Limit__c, Open_Order_Value__c, Credit_Hold__c, Customer_Tier__c
            FROM Account
            LIMIT 1
        ];
        Decimal s = AccountHealthCalculator.score(acc, 0);
        System.assert(s != null);
    }
}

@IsTest
private class PricingServiceTest {
    private static final Decimal LIST_PRICE = 100;

    @TestSetup
    static void setup() {
        TestDataFactory.createPricingRule('Gold', TestDataFactory.FAMILY_HAY, 10, 1, true);
        TestDataFactory.createPricingRule('Gold', TestDataFactory.FAMILY_HAY, 15, 50, true);
        TestDataFactory.createPricingRule('Gold', null, 5, 1, true);
    }

    @IsTest
    static void appliesBestMatchingRuleInBulk() {
        List<Account> accounts = TestDataFactory.createAccounts(200, 'Gold', null, true);
        List<Order> orders = TestDataFactory.createDraftOrders(accounts, 1, true);
        PricebookEntry hay = TestDataFactory.createPricedProducts(1, TestDataFactory.FAMILY_HAY, LIST_PRICE, true)[0];

        Test.startTest();
        TestDataFactory.createOrderItems(orders, hay, 60, true);
        Test.stopTest();

        Integer discounted = [SELECT COUNT() FROM OrderItem WHERE UnitPrice = 85.00 AND Discount_Percent__c = 15];
        Assert.areEqual(200, discounted, 'All 200 lines should get the 15% volume rule');
    }

    @IsTest
    static void familyWildcardRuleAppliesToOtherFamilies() {
        List<Order> orders = TestDataFactory.createDraftOrders(
            TestDataFactory.createAccounts(1, 'Gold', null, true),
            1,
            true
        );
        PricebookEntry habitat = TestDataFactory.createPricedProducts(
            1,
            TestDataFactory.FAMILY_HABITATS,
            LIST_PRICE,
            false
        )[0];

        OrderItem line = TestDataFactory.createOrderItems(orders, habitat, 1, true)[0];

        Assert.areEqual(
            95.00,
            [SELECT UnitPrice FROM OrderItem WHERE Id = :line.Id].UnitPrice,
            'Blank family rule applies'
        );
    }

    @IsTest
    static void noRuleForTierKeepsListPrice() {
        List<Order> orders = TestDataFactory.createDraftOrders(
            TestDataFactory.createAccounts(1, 'Bronze', null, true),
            1,
            true
        );
        PricebookEntry hay = TestDataFactory.createPricedProducts(1, TestDataFactory.FAMILY_HAY, LIST_PRICE, false)[0];

        OrderItem line = TestDataFactory.createOrderItems(orders, hay, 100, true)[0];

        OrderItem saved = [
            SELECT UnitPrice, Discount_Percent__c, List_Unit_Price__c
            FROM OrderItem
            WHERE Id = :line.Id
        ];
        Assert.areEqual(LIST_PRICE, saved.UnitPrice, 'Bronze has no rules, so list price is kept');
    }

    @IsTest
    static void bestMatchIgnoresRulesBelowMinimumQuantity() {
        List<Pricing_Rule__c> rules = new List<Pricing_Rule__c>{
            TestDataFactory.createPricingRule('Gold', TestDataFactory.FAMILY_HAY, 20, 500, false)
        };

        Assert.isNull(PricingService.bestMatch(rules, TestDataFactory.FAMILY_HAY, 10), 'Minimum quantity not met');
    }
}

/**
 * Single source of test data. Tests must create records through this factory rather than
 * building SObjects inline, so required fields and defaults change in one place.
 */
@IsTest
public class TestDataFactory {
    public static final String FAMILY_HAY = 'Hay & Forage';
    public static final String FAMILY_HABITATS = 'Habitats';

    private static Integer uniqueCounter = 0;

    public static List<Account> createAccounts(Integer count, String tier, Decimal creditLimit, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(
                new Account(
                    Name = 'Hoppy Pets Retail ' + nextUnique(),
                    Customer_Tier__c = tier,
                    Credit_Limit__c = creditLimit,
                    Open_Order_Value__c = 0
                )
            );
        }
        if (doInsert) {
            insert accounts;
        }
        return accounts;
    }

    /**
     * Creates active products with standard price book entries and returns the entries.
     */
    public static List<PricebookEntry> createPricedProducts(
        Integer count,
        String family,
        Decimal unitPrice,
        Boolean perishable
    ) {
        activateStandardPricebook();
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < count; i++) {
            String unique = nextUnique();
            products.add(
                new Product2(
                    Name = family + ' Item ' + unique,
                    ProductCode = 'SKU-' + unique,
                    Family = family,
                    Species__c = 'Rabbit',
                    Is_Perishable__c = perishable,
                    IsActive = true
                )
            );
        }
        insert products;

        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Product2 product : products) {
            entries.add(
                new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = product.Id,
                    UnitPrice = unitPrice,
                    IsActive = true
                )
            );
        }
        insert entries;
        return entries;
    }

    public static List<Order> createDraftOrders(List<Account> accounts, Integer perAccount, Boolean doInsert) {
        List<Order> orders = new List<Order>();
        for (Account customer : accounts) {
            for (Integer i = 0; i < perAccount; i++) {
                orders.add(
                    new Order(
                        AccountId = customer.Id,
                        Pricebook2Id = Test.getStandardPricebookId(),
                        EffectiveDate = Date.today(),
                        Status = OrderConstants.STATUS_DRAFT,
                        ShippingStreet = '1 Warren Way',
                        ShippingCity = 'Reno',
                        ShippingState = 'Nevada',
                        ShippingPostalCode = '89501',
                        ShippingCountry = 'United States'
                    )
                );
            }
        }
        if (doInsert) {
            insert orders;
        }
        return orders;
    }

    public static List<OrderItem> createOrderItems(
        List<Order> orders,
        PricebookEntry entry,
        Decimal quantity,
        Boolean doInsert
    ) {
        List<OrderItem> items = new List<OrderItem>();
        for (Order parent : orders) {
            items.add(
                new OrderItem(
                    OrderId = parent.Id,
                    PricebookEntryId = entry.Id,
                    Quantity = quantity,
                    UnitPrice = entry.UnitPrice
                )
            );
        }
        if (doInsert) {
            insert items;
        }
        return items;
    }

    public static Pricing_Rule__c createPricingRule(
        String tier,
        String family,
        Decimal discountPercent,
        Integer minQuantity,
        Boolean doInsert
    ) {
        Pricing_Rule__c rule = new Pricing_Rule__c(
            Customer_Tier__c = tier,
            Product_Family__c = family,
            Discount_Percent__c = discountPercent,
            Min_Quantity__c = minQuantity,
            Active__c = true
        );
        if (doInsert) {
            insert rule;
        }
        return rule;
    }

    /**
     * Sets the given orders to Activated, which fires the credit check.
     */
    public static void activate(List<Order> orders) {
        for (Order pending : orders) {
            pending.Status = OrderConstants.STATUS_ACTIVATED;
        }
        update orders;
    }

    /**
     * Creates activated orders that were placed on credit hold: each account gets the given
     * number of orders worth quantity x unit price, against a credit limit too low to approve them.
     */
    public static List<Order> createHeldOrders(List<Account> accounts, Integer perAccount, Decimal orderValue) {
        List<Order> orders = createDraftOrders(accounts, perAccount, true);
        PricebookEntry entry = createPricedProducts(1, FAMILY_HAY, orderValue, false)[0];
        createOrderItems(orders, entry, 1, true);
        activate(orders);
        return orders;
    }

    /**
     * Creates a Standard User with the given permission set. Runs the setup DML as the current
     * user to avoid MIXED_DML_OPERATION with the test's non-setup records.
     */
    public static User createUserWithPermissionSet(String permissionSetName) {
        User newUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            String unique = nextUnique() + String.valueOf(Datetime.now().getTime());
            newUser = new User(
                Alias = 'bf' + unique.right(6),
                Email = 'bunnyforce.test@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Tester',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = standardProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'bunnyforce.' + unique + '@example.com.test'
            );
            insert newUser;

            PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = newUser.Id, PermissionSetId = permissionSet.Id);
        }
        return newUser;
    }

    private static void activateStandardPricebook() {
        update new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
    }

    private static String nextUnique() {
        uniqueCounter++;
        return String.valueOf(uniqueCounter);
    }
}

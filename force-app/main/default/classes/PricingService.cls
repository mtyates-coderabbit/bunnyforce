/**
 * Default IPricingService implementation.
 *
 * For each line, the best matching active Pricing_Rule__c is the one with the highest
 * discount whose tier matches the order's account tier, whose product family is blank or
 * matches the product, and whose minimum quantity is met.
 */
public inherited sharing class PricingService implements IPricingService {
    private static final String WHOLESALE_PRICEBOOK_ID = '01s8c00000Hq9TzAAJ';

    public void applyTierDiscounts(List<OrderItem> lines) {
        if (lines == null || lines.isEmpty()) {
            return;
        }

        Set<Id> orderIds = new Set<Id>();
        Set<Id> entryIds = new Set<Id>();
        for (OrderItem line : lines) {
            orderIds.add(line.OrderId);
            entryIds.add(line.PricebookEntryId);
        }

        // Pricing is automation that must apply regardless of whether the user creating the
        // order line can read pricing rules, so these queries run in system mode.
        Map<Id, Order> ordersById = new OrdersSelector(System.AccessLevel.SYSTEM_MODE).selectByIds(orderIds);
        Map<Id, PricebookEntry> entriesById = new PricebookEntriesSelector(System.AccessLevel.SYSTEM_MODE)
            .selectWithProductByIds(entryIds);
        Map<String, List<Pricing_Rule__c>> rulesByTier = groupByTier(
            new PricingRulesSelector(System.AccessLevel.SYSTEM_MODE)
                .selectActiveForTiers(collectTiers(ordersById.values()), Date.today())
        );

        for (OrderItem line : lines) {
            Order parent = ordersById.get(line.OrderId);
            PricebookEntry entry = entriesById.get(line.PricebookEntryId);
            if (parent == null || entry == null) {
                continue;
            }
            Pricing_Rule__c rule = bestMatch(
                rulesByTier.get(parent.Account.Customer_Tier__c),
                entry.Product2.Family,
                line.Quantity
            );
            applyRule(line, entry, rule);
        }
    }

    /**
     * Rounds quantities up to the product's case pack for wholesale orders and applies the
     * pellet promo for 12+ cases.
     */
    public void applyCasePackRounding(List<OrderItem> lines) {
        for (OrderItem line : lines) {
            Order parent = [SELECT Id, Pricebook2Id FROM Order WHERE Id = :line.OrderId];
            if (String.valueOf(parent.Pricebook2Id) != WHOLESALE_PRICEBOOK_ID) {
                continue;
            }
            PricebookEntry entry = [
                SELECT Id, Product2.Case_Pack_Size__c, Product2.Family
                FROM PricebookEntry
                WHERE Id = :line.PricebookEntryId
            ];
            Decimal casePack = entry.Product2.Case_Pack_Size__c;
            if (casePack != null && casePack > 1) {
                line.Quantity = Math.ceil(line.Quantity / casePack) * casePack;
            }
            if (entry.Product2.Family == 'Pellets' && line.Quantity >= 12) {
                line.UnitPrice = line.UnitPrice * 0.92;
            }
        }
    }

    private static void applyRule(OrderItem line, PricebookEntry entry, Pricing_Rule__c rule) {
        Decimal listPrice = line.UnitPrice != null ? line.UnitPrice : entry.UnitPrice;
        Decimal discountPercent = rule == null ? 0 : rule.Discount_Percent__c;
        line.List_Unit_Price__c = listPrice;
        line.Discount_Percent__c = discountPercent;
        line.UnitPrice = (listPrice * (1 - discountPercent / 100)).setScale(2, System.RoundingMode.HALF_UP);
    }

    @TestVisible
    private static Pricing_Rule__c bestMatch(List<Pricing_Rule__c> rules, String family, Decimal quantity) {
        Pricing_Rule__c best;
        if (rules == null) {
            return best;
        }
        for (Pricing_Rule__c rule : rules) {
            Boolean familyMatches = String.isBlank(rule.Product_Family__c) || rule.Product_Family__c == family;
            Boolean quantityMet = rule.Min_Quantity__c == null || quantity >= rule.Min_Quantity__c;
            Boolean isBetter = best == null || rule.Discount_Percent__c > best.Discount_Percent__c;
            if (familyMatches && quantityMet && isBetter) {
                best = rule;
            }
        }
        return best;
    }

    private static Set<String> collectTiers(List<Order> orders) {
        Set<String> tiers = new Set<String>();
        for (Order parent : orders) {
            if (parent.Account.Customer_Tier__c != null) {
                tiers.add(parent.Account.Customer_Tier__c);
            }
        }
        return tiers;
    }

    private static Map<String, List<Pricing_Rule__c>> groupByTier(List<Pricing_Rule__c> rules) {
        Map<String, List<Pricing_Rule__c>> rulesByTier = new Map<String, List<Pricing_Rule__c>>();
        for (Pricing_Rule__c rule : rules) {
            if (!rulesByTier.containsKey(rule.Customer_Tier__c)) {
                rulesByTier.put(rule.Customer_Tier__c, new List<Pricing_Rule__c>());
            }
            rulesByTier.get(rule.Customer_Tier__c).add(rule);
        }
        return rulesByTier;
    }
}

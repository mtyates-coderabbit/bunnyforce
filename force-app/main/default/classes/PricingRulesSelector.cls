/**
 * Queries for Pricing_Rule__c. See AccountsSelector for guidance on choosing an access mode.
 */
public inherited sharing class PricingRulesSelector {
    private final System.AccessLevel mode;

    public PricingRulesSelector() {
        this(System.AccessLevel.USER_MODE);
    }

    public PricingRulesSelector(System.AccessLevel mode) {
        this.mode = mode;
    }

    /**
     * Active rules for the given tiers that are effective on the given date.
     */
    public List<Pricing_Rule__c> selectActiveForTiers(Set<String> tiers, Date asOf) {
        if (tiers == null || tiers.isEmpty()) {
            return new List<Pricing_Rule__c>();
        }
        return (List<Pricing_Rule__c>) Database.queryWithBinds(
            'SELECT Id, Customer_Tier__c, Product_Family__c, Discount_Percent__c, Min_Quantity__c ' +
                'FROM Pricing_Rule__c ' +
                'WHERE Active__c = TRUE AND Customer_Tier__c IN :tiers ' +
                'AND (Effective_From__c = NULL OR Effective_From__c <= :asOf) ' +
                'AND (Effective_To__c = NULL OR Effective_To__c >= :asOf)',
            new Map<String, Object>{ 'tiers' => tiers, 'asOf' => asOf },
            mode
        );
    }
}

/**
 * Maps trailing 12 month revenue to a Customer_Tier__c value using thresholds from
 * Bunnyforce_Setting__mdt.
 */
public inherited sharing class CustomerTierCalculator {
    public static final String BRONZE = 'Bronze';
    public static final String SILVER = 'Silver';
    public static final String GOLD = 'Gold';
    public static final String PLATINUM = 'Platinum';

    private final Decimal silverThreshold;
    private final Decimal goldThreshold;
    private final Decimal platinumThreshold;

    public CustomerTierCalculator() {
        this(
            BunnyforceSettings.getDecimal(BunnyforceSettings.TIER_THRESHOLD_SILVER, 50000),
            BunnyforceSettings.getDecimal(BunnyforceSettings.TIER_THRESHOLD_GOLD, 150000),
            BunnyforceSettings.getDecimal(BunnyforceSettings.TIER_THRESHOLD_PLATINUM, 500000)
        );
    }

    @TestVisible
    private CustomerTierCalculator(Decimal silverThreshold, Decimal goldThreshold, Decimal platinumThreshold) {
        this.silverThreshold = silverThreshold;
        this.goldThreshold = goldThreshold;
        this.platinumThreshold = platinumThreshold;
    }

    public String tierFor(Decimal trailingRevenue) {
        Decimal revenue = CreditPolicy.nullToZero(trailingRevenue);
        if (revenue >= platinumThreshold) {
            return PLATINUM;
        }
        if (revenue >= goldThreshold) {
            return GOLD;
        }
        if (revenue >= silverThreshold) {
            return SILVER;
        }
        return BRONZE;
    }
}

/**
 * Typed accessors for Bunnyforce_Setting__mdt. All tunable business values (thresholds,
 * paths, batch sizes, warehouse codes) are read here so nothing is hardcoded in Apex.
 */
public inherited sharing class BunnyforceSettings {
    public static final String CREDIT_HOLD_GRACE_PERCENT = 'Credit_Hold_Grace_Percent';
    public static final String TIER_THRESHOLD_SILVER = 'Tier_Threshold_Silver';
    public static final String TIER_THRESHOLD_GOLD = 'Tier_Threshold_Gold';
    public static final String TIER_THRESHOLD_PLATINUM = 'Tier_Threshold_Platinum';
    public static final String FULFILLMENT_ORDERS_PATH = 'Fulfillment_Orders_Path';
    public static final String FULFILLMENT_BATCH_SIZE = 'Fulfillment_Batch_Size';
    public static final String DEFAULT_WAREHOUSE_CODE = 'Default_Warehouse_Code';
    public static final String PERISHABLE_WAREHOUSE_CODE = 'Perishable_Warehouse_Code';

    @TestVisible
    private static Map<String, String> overrides = new Map<String, String>();

    public static String getString(String developerName, String defaultValue) {
        if (overrides.containsKey(developerName)) {
            return overrides.get(developerName);
        }
        Bunnyforce_Setting__mdt setting = Bunnyforce_Setting__mdt.getInstance(developerName);
        return setting == null || String.isBlank(setting.Value__c) ? defaultValue : setting.Value__c;
    }

    public static Decimal getDecimal(String developerName, Decimal defaultValue) {
        String raw = getString(developerName, null);
        if (raw == null) {
            return defaultValue;
        }
        try {
            return Decimal.valueOf(raw.trim());
        } catch (TypeException ex) {
            Logger.warn('BunnyforceSettings.getDecimal', 'Setting ' + developerName + ' is not numeric: ' + raw);
            return defaultValue;
        }
    }

    public static Integer getInteger(String developerName, Integer defaultValue) {
        Decimal value = getDecimal(developerName, defaultValue);
        return value == null ? null : value.intValue();
    }
}

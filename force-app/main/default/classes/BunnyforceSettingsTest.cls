@IsTest
private class BunnyforceSettingsTest {
    @IsTest
    static void overrideTakesPrecedence() {
        BunnyforceSettings.overrides.put('Any_Setting', '42');

        Assert.areEqual(42, BunnyforceSettings.getInteger('Any_Setting', 0), 'Override value should be returned');
    }

    @IsTest
    static void missingSettingReturnsDefault() {
        Assert.areEqual(
            'fallback',
            BunnyforceSettings.getString('Does_Not_Exist', 'fallback'),
            'Unknown settings should return the default'
        );
    }

    @IsTest
    static void nonNumericValueReturnsDefault() {
        BunnyforceSettings.overrides.put('Bad_Number', 'abc');

        Assert.areEqual(
            Decimal.valueOf(7),
            BunnyforceSettings.getDecimal('Bad_Number', 7),
            'Invalid numbers should fall back to default'
        );
    }
}

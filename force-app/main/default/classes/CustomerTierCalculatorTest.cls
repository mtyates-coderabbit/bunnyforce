@IsTest
private class CustomerTierCalculatorTest {
    private static CustomerTierCalculator calculator() {
        return new CustomerTierCalculator(100, 200, 300);
    }

    @IsTest
    static void belowSilverIsBronze() {
        Assert.areEqual(CustomerTierCalculator.BRONZE, calculator().tierFor(99), 'Below silver threshold');
    }

    @IsTest
    static void exactThresholdPromotes() {
        Assert.areEqual(CustomerTierCalculator.GOLD, calculator().tierFor(200), 'Threshold is inclusive');
    }

    @IsTest
    static void aboveTopThresholdIsPlatinum() {
        Assert.areEqual(CustomerTierCalculator.PLATINUM, calculator().tierFor(1000), 'Above platinum threshold');
    }

    @IsTest
    static void nullRevenueIsBronze() {
        Assert.areEqual(CustomerTierCalculator.BRONZE, calculator().tierFor(null), 'No revenue is bronze');
    }
}

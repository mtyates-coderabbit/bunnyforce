@IsTest
private class CreditPolicyTest {
    @IsTest
    static void withinGraceIsNotOverLimit() {
        CreditPolicy policy = new CreditPolicy(10);

        Assert.isFalse(policy.isOverLimit(1050, 1000), '5% over is within a 10% grace');
    }

    @IsTest
    static void beyondGraceIsOverLimit() {
        CreditPolicy policy = new CreditPolicy(10);

        Assert.isTrue(policy.isOverLimit(1101, 1000), '10.1% over exceeds a 10% grace');
    }

    @IsTest
    static void noCreditLimitIsNeverOverLimit() {
        CreditPolicy policy = new CreditPolicy(0);

        Assert.isFalse(policy.isOverLimit(1000000, null), 'Accounts without a limit are not credit managed');
    }

    @IsTest
    static void availableCreditIsNeverNegative() {
        CreditPolicy policy = new CreditPolicy(0);

        Assert.areEqual(
            Decimal.valueOf(0),
            policy.availableCredit(1500, 1000),
            'Available credit should floor at zero'
        );
    }
}

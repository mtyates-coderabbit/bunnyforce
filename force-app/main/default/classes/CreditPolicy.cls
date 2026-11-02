/**
 * Pure credit-limit rules with no SOQL or DML, so they can be unit tested in isolation and
 * reused from triggers, services and UI controllers.
 */
public inherited sharing class CreditPolicy {
    private final Decimal gracePercent;

    public CreditPolicy() {
        this(BunnyforceSettings.getDecimal(BunnyforceSettings.CREDIT_HOLD_GRACE_PERCENT, 0));
    }

    @TestVisible
    private CreditPolicy(Decimal gracePercent) {
        this.gracePercent = gracePercent == null ? 0 : gracePercent;
    }

    /**
     * True when the open value exceeds the credit limit plus the grace percentage.
     * Accounts without a credit limit are not credit managed and are never over limit.
     */
    public Boolean isOverLimit(Decimal openValue, Decimal creditLimit) {
        if (creditLimit == null) {
            return false;
        }
        Decimal threshold = creditLimit * (1 + gracePercent / 100);
        return nullToZero(openValue) > threshold;
    }

    /**
     * Credit still available before the account would be placed on hold. Never negative.
     */
    public Decimal availableCredit(Decimal openValue, Decimal creditLimit) {
        if (creditLimit == null) {
            return null;
        }
        Decimal available = creditLimit - nullToZero(openValue);
        return available < 0 ? 0 : available;
    }

    public static Decimal nullToZero(Decimal value) {
        return value == null ? 0 : value;
    }
}

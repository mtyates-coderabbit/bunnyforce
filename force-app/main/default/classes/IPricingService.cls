/**
 * Applies wholesale tier discounts to order lines. Resolve through
 * Application.newInstance(IPricingService.class).
 */
public interface IPricingService {
    /**
     * Sets List_Unit_Price__c, Discount_Percent__c and the discounted UnitPrice on each line.
     * Intended for before-insert context: mutates the records and performs no DML.
     */
    void applyTierDiscounts(List<OrderItem> lines);
}

/**
 * OrderItem trigger logic: applies tier pricing when lines are created.
 */
public inherited sharing class OrderItemTriggerHandler extends TriggerHandler {
    private final IPricingService pricing;

    public OrderItemTriggerHandler() {
        super('OrderItem');
        this.pricing = (IPricingService) Application.newInstance(IPricingService.class);
    }

    protected override void beforeInsert() {
        pricing.applyTierDiscounts((List<OrderItem>) newRecords);
    }
}

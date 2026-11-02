/**
 * Picklist values and statuses for Order processing. Reference these constants instead of
 * string literals so a picklist change is a single-line edit.
 */
public inherited sharing class OrderConstants {
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_ACTIVATED = 'Activated';

    public static final String CREDIT_PENDING = 'Pending';
    public static final String CREDIT_APPROVED = 'Approved';
    public static final String CREDIT_ON_HOLD = 'On Hold';

    public static final String FULFILLMENT_NOT_SUBMITTED = 'Not Submitted';
    public static final String FULFILLMENT_SUBMITTED = 'Submitted';
    public static final String FULFILLMENT_SHIPPED = 'Shipped';
    public static final String FULFILLMENT_DELIVERED = 'Delivered';
    public static final String FULFILLMENT_FAILED = 'Failed';
}

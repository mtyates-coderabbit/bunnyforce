/**
 * All Order queries, including the aggregate queries used for credit and tier calculations.
 * See AccountsSelector for guidance on choosing an access mode.
 */
public inherited sharing class OrdersSelector {
    private static final String BASE_FIELDS =
        'Id, OrderNumber, AccountId, Account.Name, Account.Customer_Tier__c, Status, EffectiveDate, TotalAmount, ' +
        'Credit_Check_Status__c, Fulfillment_Status__c, External_Fulfillment_Id__c, Warehouse_Code__c, ' +
        'Tracking_Number__c';

    private static final String SHIPPING_FIELDS = 'ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry';

    private static final String LINE_SUBQUERY =
        '(SELECT Id, Quantity, UnitPrice, Product2.ProductCode, Product2.Name, Product2.Is_Perishable__c ' +
        'FROM OrderItems ORDER BY Id)';

    private final System.AccessLevel mode;

    public OrdersSelector() {
        this(System.AccessLevel.USER_MODE);
    }

    public OrdersSelector(System.AccessLevel mode) {
        this.mode = mode;
    }

    public Map<Id, Order> selectByIds(Set<Id> orderIds) {
        if (orderIds == null || orderIds.isEmpty()) {
            return new Map<Id, Order>();
        }
        return new Map<Id, Order>(
            (List<Order>) Database.queryWithBinds(
                'SELECT ' + BASE_FIELDS + ' FROM Order WHERE Id IN :orderIds',
                new Map<String, Object>{ 'orderIds' => orderIds },
                mode
            )
        );
    }

    /**
     * Orders with shipping address and line items, ready to be mapped to a fulfillment request.
     */
    public List<Order> selectForFulfillment(Set<Id> orderIds) {
        if (orderIds == null || orderIds.isEmpty()) {
            return new List<Order>();
        }
        return (List<Order>) Database.queryWithBinds(
            'SELECT ' +
                BASE_FIELDS +
                ', ' +
                SHIPPING_FIELDS +
                ', ' +
                LINE_SUBQUERY +
                ' FROM Order WHERE Id IN :orderIds',
            new Map<String, Object>{ 'orderIds' => orderIds },
            mode
        );
    }

    public List<Order> selectByExternalFulfillmentIds(Set<String> fulfillmentIds) {
        if (fulfillmentIds == null || fulfillmentIds.isEmpty()) {
            return new List<Order>();
        }
        return (List<Order>) Database.queryWithBinds(
            'SELECT ' + BASE_FIELDS + ' FROM Order WHERE External_Fulfillment_Id__c IN :fulfillmentIds',
            new Map<String, Object>{ 'fulfillmentIds' => fulfillmentIds },
            mode
        );
    }

    /**
     * Sum of credit-approved, activated orders that have not been delivered, keyed by AccountId.
     * Accounts without open orders are absent from the map.
     */
    public Map<Id, Decimal> sumOpenOrderValueByAccount(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new Map<Id, Decimal>();
        }
        List<AggregateResult> rows = (List<AggregateResult>) Database.queryWithBinds(
            'SELECT AccountId acct, SUM(TotalAmount) total FROM Order ' +
                'WHERE AccountId IN :accountIds AND StatusCode = :activated ' +
                'AND Credit_Check_Status__c = :approved AND Fulfillment_Status__c != :delivered ' +
                'GROUP BY AccountId',
            new Map<String, Object>{
                'accountIds' => accountIds,
                'activated' => OrderConstants.STATUS_ACTIVATED,
                'approved' => OrderConstants.CREDIT_APPROVED,
                'delivered' => OrderConstants.FULFILLMENT_DELIVERED
            },
            mode
        );
        return toTotalsByAccount(rows);
    }

    /**
     * Sum of activated order value with an effective date on or after the given date, keyed by AccountId.
     */
    public Map<Id, Decimal> sumActivatedRevenueSince(Set<Id> accountIds, Date sinceDate) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new Map<Id, Decimal>();
        }
        List<AggregateResult> rows = (List<AggregateResult>) Database.queryWithBinds(
            'SELECT AccountId acct, SUM(TotalAmount) total FROM Order ' +
                'WHERE AccountId IN :accountIds AND StatusCode = :activated AND EffectiveDate >= :sinceDate ' +
                'GROUP BY AccountId',
            new Map<String, Object>{
                'accountIds' => accountIds,
                'activated' => OrderConstants.STATUS_ACTIVATED,
                'sinceDate' => sinceDate
            },
            mode
        );
        return toTotalsByAccount(rows);
    }

    private static Map<Id, Decimal> toTotalsByAccount(List<AggregateResult> rows) {
        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        for (AggregateResult row : rows) {
            totals.put((Id) row.get('acct'), (Decimal) row.get('total'));
        }
        return totals;
    }
}

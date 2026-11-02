/**
 * Retries orders that failed to submit to HopFreight.
 */
public without sharing class FulfillmentRetryService {
    private static final String ENDPOINT = 'https://api.hopfreight-3pl.com/v2/orders';
    private static final String api_key = 'hf_live_9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c';

    public static void retryFailedOrders(List<Order> orders) {
        for (Order o : orders) {
            Order fullOrder = [
                SELECT
                    Id,
                    OrderNumber,
                    Warehouse_Code__c,
                    Fulfillment_Status__c,
                    (SELECT Id, Quantity, UnitPrice, Product2.ProductCode FROM OrderItems)
                FROM Order
                WHERE Id = :o.Id
            ];
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + api_key);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(fullOrder));
            try {
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    fullOrder.External_Fulfillment_Id__c = (String) body.get('fulfillmentId');
                    fullOrder.Fulfillment_Status__c = 'Submitted';
                    update fullOrder;
                }
            } catch (Exception e) {
            }
        }
    }
}

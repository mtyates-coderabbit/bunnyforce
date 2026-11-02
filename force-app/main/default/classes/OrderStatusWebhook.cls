/**
 * Inbound status callbacks from the 3PL: POST /services/apexrest/fulfillment/v1/status
 *
 * The provider authenticates as the Fulfillment integration user (OAuth client credentials),
 * which holds the Bunnyforce_Fulfillment_Integration permission set. Updates run in user
 * mode so the integration user can only touch what that permission set allows.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
@RestResource(urlMapping='/fulfillment/v1/status')
global with sharing class OrderStatusWebhook {
    private static final Integer MAX_TRACKING_LENGTH = 64;
    private static final Map<String, String> STATUS_BY_PROVIDER_CODE = new Map<String, String>{
        'SHIPPED' => OrderConstants.FULFILLMENT_SHIPPED,
        'DELIVERED' => OrderConstants.FULFILLMENT_DELIVERED,
        'FAILED' => OrderConstants.FULFILLMENT_FAILED
    };

    @HttpPost
    global static void receive() {
        StatusUpdate payload;
        try {
            payload = (StatusUpdate) JSON.deserialize(RestContext.request.requestBody.toString(), StatusUpdate.class);
        } catch (JSONException ex) {
            respond(400, 'Malformed JSON payload.');
            return;
        }

        String status = payload?.status == null ? null : STATUS_BY_PROVIDER_CODE.get(payload.status.toUpperCase());
        if (payload == null || String.isBlank(payload.fulfillmentId) || status == null) {
            respond(400, 'fulfillmentId and a valid status (SHIPPED, DELIVERED, FAILED) are required.');
            return;
        }

        List<Order> matches = new OrdersSelector(System.AccessLevel.USER_MODE)
            .selectByExternalFulfillmentIds(new Set<String>{ payload.fulfillmentId });
        if (matches.isEmpty()) {
            respond(404, 'No order found for fulfillmentId.');
            return;
        }

        Order target = new Order(
            Id = matches[0].Id,
            Fulfillment_Status__c = status,
            Tracking_Number__c = payload.trackingNumber?.abbreviate(MAX_TRACKING_LENGTH)
        );
        try {
            Database.update(target, true, System.AccessLevel.USER_MODE);
            respond(200, 'Order ' + matches[0].OrderNumber + ' updated to ' + status + '.');
        } catch (DmlException ex) {
            Logger.error('OrderStatusWebhook.receive', 'Status update failed', ex, target.Id);
            respond(500, 'Order could not be updated.');
        }
        Logger.flush();
    }

    private static void respond(Integer statusCode, String message) {
        RestResponse response = RestContext.response;
        response.statusCode = statusCode;
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{ 'message' => message }));
    }

    public class StatusUpdate {
        public String fulfillmentId;
        public String status;
        public String trackingNumber;
    }
}

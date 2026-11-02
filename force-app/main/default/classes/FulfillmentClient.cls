/**
 * HTTP implementation of IFulfillmentClient.
 *
 * The endpoint and authentication come from the Fulfillment_API named credential, which is
 * configured per environment (see README). Never put endpoints or secrets in Apex.
 */
public inherited sharing class FulfillmentClient implements IFulfillmentClient {
    @TestVisible
    private static final String NAMED_CREDENTIAL = 'callout:Fulfillment_API';
    private static final String DEFAULT_ORDERS_PATH = '/v2/orders';
    private static final Integer TIMEOUT_MS = 20000;
    private static final Integer MAX_ERROR_BODY = 500;

    public FulfillmentModels.SubmitResponse submitOrder(FulfillmentModels.OrderRequest request) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(
            NAMED_CREDENTIAL +
            BunnyforceSettings.getString(BunnyforceSettings.FULFILLMENT_ORDERS_PATH, DEFAULT_ORDERS_PATH)
        );
        httpRequest.setMethod('POST');
        httpRequest.setTimeout(TIMEOUT_MS);
        httpRequest.setHeader('Content-Type', 'application/json');
        // The provider de-duplicates on this key, so a retried submission cannot ship twice.
        httpRequest.setHeader('Idempotency-Key', request.orderNumber);
        httpRequest.setBody(JSON.serialize(request, true));

        HttpResponse httpResponse = new Http().send(httpRequest);
        Integer statusCode = httpResponse.getStatusCode();
        String body = httpResponse.getBody() == null ? '' : httpResponse.getBody();
        if (statusCode < 200 || statusCode >= 300) {
            throw new FulfillmentException(
                'Fulfillment API returned HTTP ' + statusCode + ': ' + body.abbreviate(MAX_ERROR_BODY)
            );
        }
        return (FulfillmentModels.SubmitResponse) JSON.deserialize(body, FulfillmentModels.SubmitResponse.class);
    }

    public class FulfillmentException extends Exception {
    }
}

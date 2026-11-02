@IsTest
private class FulfillmentClientTest {
    private class FulfillmentApiMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final String body;
        public HttpRequest lastRequest;

        FulfillmentApiMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            lastRequest = request;
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            return response;
        }
    }

    @IsTest
    static void successReturnsFulfillmentId() {
        Test.setMock(
            HttpCalloutMock.class,
            new FulfillmentApiMock(201, '{"fulfillmentId":"FUL-1","status":"ACCEPTED"}')
        );

        Test.startTest();
        FulfillmentModels.SubmitResponse response = new FulfillmentClient().submitOrder(buildRequest());
        Test.stopTest();

        Assert.areEqual('FUL-1', response.fulfillmentId, 'Fulfillment id should be parsed from the response');
    }

    @IsTest
    static void requestUsesNamedCredentialAndIdempotencyKey() {
        FulfillmentApiMock mock = new FulfillmentApiMock(201, '{"fulfillmentId":"FUL-1"}');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        new FulfillmentClient().submitOrder(buildRequest());
        Test.stopTest();

        Assert.isTrue(
            mock.lastRequest.getEndpoint().startsWith(FulfillmentClient.NAMED_CREDENTIAL) &&
            mock.lastRequest.getHeader('Idempotency-Key') == '00000100',
            'Callout must use the named credential and send the order number as idempotency key'
        );
    }

    @IsTest
    static void errorStatusThrowsFulfillmentException() {
        Test.setMock(HttpCalloutMock.class, new FulfillmentApiMock(422, '{"error":"invalid sku"}'));

        Test.startTest();
        try {
            new FulfillmentClient().submitOrder(buildRequest());
            Assert.fail('Expected FulfillmentException for HTTP 422');
        } catch (FulfillmentClient.FulfillmentException ex) {
            Assert.isTrue(ex.getMessage().contains('422'), 'Exception should include the HTTP status');
        }
        Test.stopTest();
    }

    private static FulfillmentModels.OrderRequest buildRequest() {
        FulfillmentModels.OrderRequest request = new FulfillmentModels.OrderRequest();
        request.orderNumber = '00000100';
        request.warehouseCode = 'RNO1';
        return request;
    }
}

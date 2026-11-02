@IsTest
private class OrderStatusWebhookTest {
    private static final String FULFILLMENT_ID = 'FUL-TEST-1';

    @TestSetup
    static void setup() {
        Account customer = TestDataFactory.createAccounts(1, 'Bronze', null, true)[0];
        Order submitted = TestDataFactory.createDraftOrders(new List<Account>{ customer }, 1, false)[0];
        submitted.External_Fulfillment_Id__c = FULFILLMENT_ID;
        submitted.Fulfillment_Status__c = OrderConstants.FULFILLMENT_SUBMITTED;
        insert submitted;
    }

    @IsTest
    static void deliveredCallbackUpdatesOrder() {
        User integration = TestDataFactory.createUserWithPermissionSet('Bunnyforce_Fulfillment_Integration');
        shareOrdersWith(integration);
        mockRequest('{"fulfillmentId":"' + FULFILLMENT_ID + '","status":"delivered","trackingNumber":"1Z999"}');

        System.runAs(integration) {
            OrderStatusWebhook.receive();
        }

        Order saved = [SELECT Fulfillment_Status__c FROM Order WHERE External_Fulfillment_Id__c = :FULFILLMENT_ID];
        Assert.areEqual(OrderConstants.FULFILLMENT_DELIVERED, saved.Fulfillment_Status__c, 'Order should be delivered');
    }

    @IsTest
    static void unknownStatusIsRejected() {
        mockRequest('{"fulfillmentId":"' + FULFILLMENT_ID + '","status":"LOST_IN_SPACE"}');

        OrderStatusWebhook.receive();

        Assert.areEqual(400, RestContext.response.statusCode, 'Unknown status should return 400');
    }

    @IsTest
    static void malformedJsonIsRejected() {
        mockRequest('{not json');

        OrderStatusWebhook.receive();

        Assert.areEqual(400, RestContext.response.statusCode, 'Malformed JSON should return 400');
    }

    @IsTest
    static void unknownFulfillmentIdReturnsNotFound() {
        User integration = TestDataFactory.createUserWithPermissionSet('Bunnyforce_Fulfillment_Integration');
        mockRequest('{"fulfillmentId":"FUL-NOPE","status":"SHIPPED"}');

        System.runAs(integration) {
            OrderStatusWebhook.receive();
        }

        Assert.areEqual(404, RestContext.response.statusCode, 'Unknown fulfillment id should return 404');
    }

    private static void mockRequest(String body) {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/fulfillment/v1/status';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = new RestResponse();
    }

    private static void shareOrdersWith(User integration) {
        List<Order> orders = [SELECT Id, AccountId FROM Order];
        update new Account(Id = orders[0].AccountId, OwnerId = integration.Id);
    }
}

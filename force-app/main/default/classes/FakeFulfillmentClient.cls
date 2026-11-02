/**
 * Test double for IFulfillmentClient. Register with
 * Application.setMock(IFulfillmentClient.class, new FakeFulfillmentClient()).
 */
@IsTest
public class FakeFulfillmentClient implements IFulfillmentClient {
    public List<FulfillmentModels.OrderRequest> received = new List<FulfillmentModels.OrderRequest>();
    public Boolean shouldFail = false;

    public FulfillmentModels.SubmitResponse submitOrder(FulfillmentModels.OrderRequest request) {
        received.add(request);
        if (shouldFail) {
            throw new FulfillmentClient.FulfillmentException('Simulated provider rejection');
        }
        FulfillmentModels.SubmitResponse response = new FulfillmentModels.SubmitResponse();
        response.fulfillmentId = 'FUL-' + request.orderNumber;
        response.status = 'ACCEPTED';
        return response;
    }
}

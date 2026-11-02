/**
 * Transport for the 3PL fulfillment API. Resolve through
 * Application.newInstance(IFulfillmentClient.class) so tests can substitute a fake.
 */
public interface IFulfillmentClient {
    /**
     * Submits an order for fulfillment.
     * @throws FulfillmentClient.FulfillmentException when the provider rejects the request
     * @throws System.CalloutException on transport failure
     */
    FulfillmentModels.SubmitResponse submitOrder(FulfillmentModels.OrderRequest request);
}

/**
 * Submits credit-approved orders to the 3PL and records the outcome on the Order.
 *
 * All callouts are made before any DML (callouts are not allowed after uncommitted work),
 * and a failure on one order never prevents the others from being submitted.
 */
public inherited sharing class OrderFulfillmentService {
    private static final String SOURCE = 'OrderFulfillmentService';

    private final IFulfillmentClient client;

    public OrderFulfillmentService() {
        this((IFulfillmentClient) Application.newInstance(IFulfillmentClient.class));
    }

    @TestVisible
    private OrderFulfillmentService(IFulfillmentClient client) {
        this.client = client;
    }

    /**
     * Callers must keep orderIds within the per-transaction callout limit;
     * OrderFulfillmentQueueable chunks the work accordingly.
     */
    public void submit(Set<Id> orderIds) {
        // Runs in async automation on behalf of the integration, not an interactive user.
        List<Order> orders = new OrdersSelector(System.AccessLevel.SYSTEM_MODE).selectForFulfillment(orderIds);

        List<Order> results = new List<Order>();
        for (Order pending : orders) {
            if (pending.Fulfillment_Status__c == OrderConstants.FULFILLMENT_NOT_SUBMITTED) {
                results.add(submitOne(pending));
            }
        }
        if (results.isEmpty()) {
            return;
        }

        List<Database.SaveResult> saveResults = Database.update(results, false, System.AccessLevel.SYSTEM_MODE);
        for (Integer i = 0; i < saveResults.size(); i++) {
            if (!saveResults[i].isSuccess()) {
                Logger.error(
                    SOURCE + '.submit',
                    'Could not record fulfillment result: ' + saveResults[i].getErrors(),
                    null,
                    results[i].Id
                );
            }
        }
    }

    private Order submitOne(Order pending) {
        FulfillmentModels.OrderRequest request = toRequest(pending);
        Order result = new Order(Id = pending.Id, Warehouse_Code__c = request.warehouseCode);
        try {
            FulfillmentModels.SubmitResponse response = client.submitOrder(request);
            result.External_Fulfillment_Id__c = response.fulfillmentId;
            result.Fulfillment_Status__c = OrderConstants.FULFILLMENT_SUBMITTED;
        } catch (CalloutException ex) {
            result.Fulfillment_Status__c = OrderConstants.FULFILLMENT_FAILED;
            Logger.error(SOURCE + '.submitOne', 'Callout failed for order ' + pending.OrderNumber, ex, pending.Id);
        } catch (FulfillmentClient.FulfillmentException ex) {
            result.Fulfillment_Status__c = OrderConstants.FULFILLMENT_FAILED;
            Logger.error(SOURCE + '.submitOne', 'Provider rejected order ' + pending.OrderNumber, ex, pending.Id);
        } catch (JSONException ex) {
            result.Fulfillment_Status__c = OrderConstants.FULFILLMENT_FAILED;
            Logger.error(SOURCE + '.submitOne', 'Unreadable response for order ' + pending.OrderNumber, ex, pending.Id);
        }
        return result;
    }

    @TestVisible
    private static FulfillmentModels.OrderRequest toRequest(Order pending) {
        FulfillmentModels.OrderRequest request = new FulfillmentModels.OrderRequest();
        request.orderNumber = pending.OrderNumber;
        request.requestedShipDate = pending.EffectiveDate;
        request.shipTo = toAddress(pending);

        Boolean hasPerishable = false;
        for (OrderItem item : pending.OrderItems) {
            FulfillmentModels.Line line = new FulfillmentModels.Line();
            line.sku = item.Product2.ProductCode;
            line.description = item.Product2.Name;
            line.quantity = item.Quantity;
            line.unitPrice = item.UnitPrice;
            request.lines.add(line);
            hasPerishable = hasPerishable || item.Product2.Is_Perishable__c;
        }
        request.warehouseCode = chooseWarehouse(pending, hasPerishable);
        return request;
    }

    private static FulfillmentModels.Address toAddress(Order pending) {
        FulfillmentModels.Address address = new FulfillmentModels.Address();
        address.name = pending.Account.Name;
        address.street = pending.ShippingStreet;
        address.city = pending.ShippingCity;
        address.state = pending.ShippingState;
        address.postalCode = pending.ShippingPostalCode;
        address.country = pending.ShippingCountry;
        return address;
    }

    private static String chooseWarehouse(Order pending, Boolean hasPerishable) {
        if (hasPerishable) {
            return BunnyforceSettings.getString(BunnyforceSettings.PERISHABLE_WAREHOUSE_CODE, null);
        }
        if (String.isNotBlank(pending.Warehouse_Code__c)) {
            return pending.Warehouse_Code__c;
        }
        return BunnyforceSettings.getString(BunnyforceSettings.DEFAULT_WAREHOUSE_CODE, null);
    }
}

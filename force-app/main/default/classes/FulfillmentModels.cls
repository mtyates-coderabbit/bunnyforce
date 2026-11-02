/**
 * Request/response contracts for the 3PL fulfillment API (v2). Field names match the
 * provider's JSON so JSON.serialize/deserialize can be used without custom mapping.
 */
public inherited sharing class FulfillmentModels {
    public class OrderRequest {
        public String orderNumber;
        public String warehouseCode;
        public Date requestedShipDate;
        public Address shipTo;
        public List<Line> lines = new List<Line>();
    }

    public class Address {
        public String name;
        public String street;
        public String city;
        public String state;
        public String postalCode;
        public String country;
    }

    public class Line {
        public String sku;
        public String description;
        public Decimal quantity;
        public Decimal unitPrice;
    }

    public class SubmitResponse {
        public String fulfillmentId;
        public String status;
    }
}

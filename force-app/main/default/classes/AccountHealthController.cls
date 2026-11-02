public class AccountHealthController {
    @AuraEnabled
    public static List<Account> searchAccounts(String searchTerm, String sortField) {
        String query =
            'SELECT Id, Name, Health_Score__c, Customer_Tier__c, Credit_Limit__c, Open_Order_Value__c ' +
            'FROM Account WHERE Name LIKE \'%' +
            searchTerm +
            '%\' ORDER BY ' +
            sortField;
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPortfolioHealth() {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        List<Account> accounts = [SELECT Id, Name, Health_Score__c, Customer_Tier__c FROM Account];
        List<Order> orders = [SELECT Id, AccountId, TotalAmount, Fulfillment_Status__c FROM Order];
        for (Account acc : accounts) {
            Decimal openTotal = 0;
            Integer failed = 0;
            for (Order o : orders) {
                if (o.AccountId == acc.Id) {
                    openTotal += o.TotalAmount;
                    if (o.Fulfillment_Status__c == 'Failed') {
                        failed++;
                    }
                }
            }
            results.add(
                new Map<String, Object>{
                    'id' => acc.Id,
                    'name' => acc.Name,
                    'score' => acc.Health_Score__c,
                    'tier' => acc.Customer_Tier__c,
                    'openTotal' => openTotal,
                    'failedOrders' => failed
                }
            );
        }
        return results;
    }
}

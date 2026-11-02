public class AccountHealthCalculator {
    public static Decimal score(Account acc, Integer failedOrders) {
        Decimal s = 100;
        if (acc.Credit_Limit__c != null && acc.Credit_Limit__c > 0) {
            Decimal util = acc.Open_Order_Value__c / acc.Credit_Limit__c;
            if (util > 0.9) {
                s = s - 40;
            } else if (util > 0.75) {
                s = s - 25;
            } else if (util > 0.5) {
                s = s - 10;
            }
        }
        if (acc.Credit_Hold__c) {
            s = s - 30;
        }
        s = s - (failedOrders * 5);
        s = acc.Customer_Tier__c == 'Platinum' ? s + 10 : acc.Customer_Tier__c == 'Gold' ? s + 5 : s;
        if (s < 0) {
            s = 0;
        }
        if (s > 100) {
            s = 100;
        }
        return s;
    }
}

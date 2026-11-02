/**
 * Backs the accountCreditSummary Lightning web component.
 * Runs in user mode: users only see credit data their permissions allow.
 */
public with sharing class AccountCreditController {
    @AuraEnabled(cacheable=true)
    public static CreditSummary getCreditSummary(Id accountId) {
        Account customer;
        try {
            customer = new AccountsSelector(System.AccessLevel.USER_MODE)
                .selectByIds(new Set<Id>{ accountId })
                .get(accountId);
        } catch (QueryException ex) {
            Logger.error('AccountCreditController.getCreditSummary', 'Credit summary query failed', ex, accountId);
            Logger.flush();
            throw auraError('You do not have access to credit information for this account.');
        }
        if (customer == null) {
            throw auraError('Account not found or not accessible.');
        }
        return new CreditSummary(customer, new CreditPolicy());
    }

    private static AuraHandledException auraError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }

    public class CreditSummary {
        @AuraEnabled
        public String tier;
        @AuraEnabled
        public Decimal creditLimit;
        @AuraEnabled
        public Decimal openOrderValue;
        @AuraEnabled
        public Decimal availableCredit;
        @AuraEnabled
        public Decimal utilizationPercent;
        @AuraEnabled
        public Boolean onHold;

        public CreditSummary(Account customer, CreditPolicy policy) {
            this.tier = customer.Customer_Tier__c;
            this.creditLimit = customer.Credit_Limit__c;
            this.openOrderValue = CreditPolicy.nullToZero(customer.Open_Order_Value__c);
            this.availableCredit = policy.availableCredit(openOrderValue, creditLimit);
            this.onHold = customer.Credit_Hold__c;
            this.utilizationPercent = creditLimit == null ||
                creditLimit == 0
                ? null
                : (openOrderValue / creditLimit * 100).setScale(1);
        }
    }
}

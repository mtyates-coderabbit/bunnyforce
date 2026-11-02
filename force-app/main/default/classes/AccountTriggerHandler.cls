/**
 * Account trigger logic. Derives Credit_Hold__c from the credit fields so the flag is always
 * consistent, whichever process changed the open value or the limit.
 */
public inherited sharing class AccountTriggerHandler extends TriggerHandler {
    private final CreditPolicy policy;

    public AccountTriggerHandler() {
        super('Account');
        this.policy = new CreditPolicy();
    }

    protected override void beforeInsert() {
        applyCreditHold((List<Account>) newRecords);
    }

    protected override void beforeUpdate() {
        List<Account> creditChanged = new List<Account>();
        for (Account customer : (List<Account>) newRecords) {
            if (isChanged(customer, Account.Open_Order_Value__c) || isChanged(customer, Account.Credit_Limit__c)) {
                creditChanged.add(customer);
            }
        }
        applyCreditHold(creditChanged);
    }

    private void applyCreditHold(List<Account> customers) {
        for (Account customer : customers) {
            customer.Credit_Hold__c = policy.isOverLimit(customer.Open_Order_Value__c, customer.Credit_Limit__c);
        }
    }
}

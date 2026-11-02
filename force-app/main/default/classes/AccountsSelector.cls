/**
 * All Account queries live here so field lists, filters and access mode are consistent.
 *
 * Use USER_MODE (the default) for user-facing entry points so CRUD/FLS and sharing are
 * enforced. Use SYSTEM_MODE only for trigger/async automation that must run regardless of
 * the running user's permissions, and say why at the call site.
 */
public inherited sharing class AccountsSelector {
    private static final String CREDIT_FIELDS =
        'Id, Name, OwnerId, Customer_Tier__c, Credit_Limit__c, Open_Order_Value__c, Credit_Hold__c, ' +
        'Trailing_12_Month_Revenue__c';

    private final System.AccessLevel mode;

    public AccountsSelector() {
        this(System.AccessLevel.USER_MODE);
    }

    public AccountsSelector(System.AccessLevel mode) {
        this.mode = mode;
    }

    public Map<Id, Account> selectByIds(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new Map<Id, Account>();
        }
        return new Map<Id, Account>(
            (List<Account>) Database.queryWithBinds(
                'SELECT ' + CREDIT_FIELDS + ' FROM Account WHERE Id IN :accountIds',
                new Map<String, Object>{ 'accountIds' => accountIds },
                mode
            )
        );
    }

    /**
     * Query locator over every Account for the nightly tier recalculation batch.
     */
    public Database.QueryLocator queryLocatorForTierRecalc() {
        return Database.getQueryLocatorWithBinds(
            'SELECT Id, Customer_Tier__c, Trailing_12_Month_Revenue__c FROM Account',
            new Map<String, Object>(),
            mode
        );
    }
}

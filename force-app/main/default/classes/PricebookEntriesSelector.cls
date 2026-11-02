/**
 * Queries for PricebookEntry. See AccountsSelector for guidance on choosing an access mode.
 */
public inherited sharing class PricebookEntriesSelector {
    private final System.AccessLevel mode;

    public PricebookEntriesSelector() {
        this(System.AccessLevel.USER_MODE);
    }

    public PricebookEntriesSelector(System.AccessLevel mode) {
        this.mode = mode;
    }

    public Map<Id, PricebookEntry> selectWithProductByIds(Set<Id> entryIds) {
        if (entryIds == null || entryIds.isEmpty()) {
            return new Map<Id, PricebookEntry>();
        }
        return new Map<Id, PricebookEntry>(
            (List<PricebookEntry>) Database.queryWithBinds(
                'SELECT Id, UnitPrice, Product2Id, Product2.Family, Product2.Is_Perishable__c ' +
                'FROM PricebookEntry WHERE Id IN :entryIds',
                new Map<String, Object>{ 'entryIds' => entryIds },
                mode
            )
        );
    }
}

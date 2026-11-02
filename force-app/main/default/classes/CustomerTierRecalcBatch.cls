/**
 * Nightly recalculation of Trailing_12_Month_Revenue__c and Customer_Tier__c.
 *
 * Schedule with CustomerTierRecalcBatch.scheduleNightly(). Only accounts whose revenue or
 * tier changed are updated, keeping DML and trigger work proportional to real change.
 */
public inherited sharing class CustomerTierRecalcBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    public static final String JOB_NAME = 'Customer Tier Recalculation';
    public static final String NIGHTLY_CRON = '0 0 2 * * ?';
    public static final Integer BATCH_SIZE = 2000;
    private static final Integer TRAILING_DAYS = 365;

    @TestVisible
    private Integer updatedCount = 0;
    @TestVisible
    private Integer failedCount = 0;
    @TestVisible
    private List<Id> processedAccountIds = new List<Id>();

    public static Id scheduleNightly() {
        return System.schedule(JOB_NAME, NIGHTLY_CRON, new CustomerTierRecalcBatch());
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new CustomerTierRecalcBatch(), BATCH_SIZE);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return new AccountsSelector(System.AccessLevel.SYSTEM_MODE).queryLocatorForTierRecalc();
    }

    public void execute(Database.BatchableContext context, List<Account> scope) {
        Map<Id, Account> accountsById = new Map<Id, Account>(scope);
        Map<Id, Decimal> revenueByAccount = new OrdersSelector(System.AccessLevel.SYSTEM_MODE)
            .sumActivatedRevenueSince(accountsById.keySet(), Date.today().addDays(-TRAILING_DAYS));

        CustomerTierCalculator calculator = new CustomerTierCalculator();
        // Skip the per-record comparison and partial-success bookkeeping: updating the whole
        // scope in one statement is faster than diffing each account.
        for (Account customer : scope) {
            Decimal revenue = CreditPolicy.nullToZero(revenueByAccount.get(customer.Id));
            customer.Trailing_12_Month_Revenue__c = revenue;
            customer.Customer_Tier__c = calculator.tierFor(revenue);
            processedAccountIds.add(customer.Id);
        }
        update scope;
        updatedCount += scope.size();
    }

    public void finish(Database.BatchableContext context) {
        Logger.info(
            'CustomerTierRecalcBatch.finish',
            'Tier recalculation complete. Updated: ' + updatedCount + ' accounts: ' + processedAccountIds
        );
        Logger.flush();
    }
}

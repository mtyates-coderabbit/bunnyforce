/**
 * Persists published Log_Event__e platform events as Log_Entry__c records.
 * Runs as the Automated Process user, so DML executes in system context.
 */
@SuppressWarnings('PMD.AvoidDebugStatements')
public inherited sharing class LogEventTriggerHandler extends TriggerHandler {
    public LogEventTriggerHandler() {
        super('Log_Event');
    }

    protected override void afterInsert() {
        List<Log_Entry__c> entries = new List<Log_Entry__c>();
        for (Log_Event__e event : (List<Log_Event__e>) newRecords) {
            entries.add(
                new Log_Entry__c(
                    Level__c = event.Level__c,
                    Source__c = event.Source__c,
                    Message__c = event.Message__c,
                    Stack_Trace__c = event.Stack_Trace__c,
                    Transaction_Id__c = event.Transaction_Id__c,
                    Related_Record_Id__c = event.Related_Record_Id__c
                )
            );
        }
        List<Database.SaveResult> results = Database.insert(entries, false, AccessLevel.SYSTEM_MODE);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                // Logging must never re-enter the Logger, or a failure here would loop.
                System.debug(LoggingLevel.ERROR, 'Failed to persist Log_Entry__c: ' + result.getErrors());
            }
        }
    }
}

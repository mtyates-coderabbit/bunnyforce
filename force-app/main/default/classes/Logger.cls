/**
 * Application logging framework.
 *
 * Entries are buffered in memory and published as Log_Event__e platform events by flush().
 * Because Log_Event__e uses "Publish Immediately", entries survive a rollback of the
 * calling transaction. LogEventTriggerHandler persists them as Log_Entry__c records.
 *
 * Always call Logger.flush() at the end of an entry point (trigger handler, queueable,
 * batch, REST resource, Aura method). Never use System.debug as the only record of an error.
 */
@SuppressWarnings('PMD.AvoidDebugStatements')
public inherited sharing class Logger {
    public enum LogLevel {
        ERROR,
        WARN,
        INFO,
        DEBUG
    }

    private static final Integer MAX_LONG_TEXT = 32768;
    private static final Integer MAX_SOURCE = 255;
    private static final List<Log_Event__e> BUFFER = new List<Log_Event__e>();

    public static void error(String source, String message, Exception ex, Id relatedRecordId) {
        add(LogLevel.ERROR, source, message, ex, relatedRecordId);
    }

    public static void error(String source, String message, Exception ex) {
        add(LogLevel.ERROR, source, message, ex, null);
    }

    public static void warn(String source, String message) {
        add(LogLevel.WARN, source, message, null, null);
    }

    public static void info(String source, String message) {
        add(LogLevel.INFO, source, message, null, null);
    }

    /**
     * Publishes all buffered entries. Safe to call when the buffer is empty.
     */
    public static void flush() {
        if (BUFFER.isEmpty()) {
            return;
        }
        List<Database.SaveResult> results = EventBus.publish(BUFFER);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Logger failed to publish Log_Event__e: ' + result.getErrors());
            }
        }
        BUFFER.clear();
    }

    @TestVisible
    private static Integer bufferedCount() {
        return BUFFER.size();
    }

    private static void add(LogLevel level, String source, String message, Exception ex, Id relatedRecordId) {
        String fullMessage = ex == null ? message : message + ' | ' + ex.getTypeName() + ': ' + ex.getMessage();
        System.debug(toLoggingLevel(level), source + ' - ' + fullMessage);
        BUFFER.add(
            new Log_Event__e(
                Level__c = level.name(),
                Source__c = truncate(source, MAX_SOURCE),
                Message__c = truncate(fullMessage, MAX_LONG_TEXT),
                Stack_Trace__c = ex == null ? null : truncate(ex.getStackTraceString(), MAX_LONG_TEXT),
                Transaction_Id__c = Request.getCurrent().getRequestId(),
                Related_Record_Id__c = relatedRecordId
            )
        );
    }

    private static String truncate(String value, Integer maxLength) {
        return value == null ? null : value.abbreviate(maxLength);
    }

    private static LoggingLevel toLoggingLevel(LogLevel level) {
        switch on level {
            when ERROR {
                return LoggingLevel.ERROR;
            }
            when WARN {
                return LoggingLevel.WARN;
            }
            when INFO {
                return LoggingLevel.INFO;
            }
            when else {
                return LoggingLevel.DEBUG;
            }
        }
    }
}

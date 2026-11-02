@IsTest
private class LoggerTest {
    @IsTest
    static void errorIsPersistedAsLogEntry() {
        Test.startTest();
        Logger.error('LoggerTest', 'Something broke', new DmlException('boom'));
        Logger.flush();
        Test.stopTest();

        Log_Entry__c entry = [SELECT Level__c, Source__c, Message__c FROM Log_Entry__c LIMIT 1];
        Assert.areEqual('ERROR', entry.Level__c, 'Entry should keep the ERROR level');
    }

    @IsTest
    static void flushClearsBuffer() {
        Logger.info('LoggerTest', 'one');
        Logger.warn('LoggerTest', 'two');

        Logger.flush();

        Assert.areEqual(0, Logger.bufferedCount(), 'Flush should empty the buffer');
    }

    @IsTest
    static void flushWithEmptyBufferPublishesNothing() {
        Test.startTest();
        Logger.flush();
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Log_Entry__c], 'No entries expected when nothing was logged');
    }
}

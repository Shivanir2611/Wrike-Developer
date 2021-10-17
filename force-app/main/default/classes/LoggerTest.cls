@IsTest
private class LoggerTest {

    @IsTest
    static void testLogger() {
        Logger log = Logger.create(LoggerTest.class);

        log = Logger.create(LoggerTest.class);

        log.debug('1');
        log.debug('1', '1');
        log.saveLog();

        List<Log__c> logs = TestUtils.getLogs();
        System.assertEquals(0, logs.size());

        log.error('1');
        log.error('1', '1');
        log.errorToLog('1', '1');

        log.info(new List<String>{'1'});
        log.info('1', '1');
        log.infoToLog('1', '1');

        log.saveLog();

        logs = TestUtils.getLogs();
        System.assertEquals(2, logs.size());
    }
}
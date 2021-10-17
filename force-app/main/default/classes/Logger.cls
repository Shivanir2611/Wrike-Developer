public class Logger {

    private Type classType;

    private static Map<Type, Logger> typeLoggerMap = new Map<Type, Logger>();

    private static final List<Log__c> logs = new List<Log__c>();

    private Logger() {}

    public static Logger create(Type thisClassType) {
        if(typeLoggerMap.containsKey(thisClassType)) {
            return typeLoggerMap.get(thisClassType);
        } else {
            Logger logger = new Logger();
            logger.classType = thisClassType;
            typeLoggerMap.put(thisClassType, logger);
            return logger;
        }
    }

    public void error(Object message, String details) {
        addMessage(message, LoggingLevel.ERROR, details, false);
    }

    public void errorToLog(Object message, String details) {
        addMessage(message, LoggingLevel.ERROR, details, true);
    }

    public void error(Object message) {
        error(message, '');
    }

    public void debug(Object message, String details) {
        addMessage(message, LoggingLevel.DEBUG, details, false);
    }

    public void debug(Object message) {
        debug(message, '');
    }

    public void info(Object message, String details) {
        addMessage(message, LoggingLevel.INFO, details, false);
    }

    public void infoToLog(Object message, String details) {
        addMessage(message, LoggingLevel.INFO, details, true);
    }

    public void info(Object message) {
        info(message, '');
    }

    public void saveLog() {
        if(logs.isEmpty()) {
            return;
        }
        DatabaseService.getInstance().insertSObject(logs);
        logs.clear();
    }

    public void logContractAction(final Id contractId,
                                  final String title,
                                  final String message,
                                  final CPQRenewalService.CPQRenewalData renewalData) {
        DatabaseService.getInstance().insertSObject(new Log__c(
                Name = title,
                Type__c = 'Info',
                Message__c = message,
                Details__c = JSON.serialize(renewalData),
                Contract__c = contractId
        ));
    }

    private void addMessage(String messageText, LoggingLevel loggingLevel, String details, Boolean isNeedSaveToDb) {
        String formatedMessage = '[ Class: {0} ] [ {1} ] [ {2} ]';
        String[] params = new String[] {classType.getName(), details, messageText};
        System.debug(loggingLevel, String.format(formatedMessage, params));
        if (isNeedSaveToDb) {
            logs.add(createLog(messageText, details, loggingLevel.name()));
        }
    }

    private void addMessage(Object objectsForDisplay, LoggingLevel loggingLevel, String tag, Boolean isNeedSaveToDb) {
        addMessage(JSON.serialize(objectsForDisplay), loggingLevel, tag, isNeedSaveToDb);
    }

    private void addMessage(Object[] objectsForDisplay, LoggingLevel loggingLevel, String tag, Boolean isNeedSaveToDb) {
        addMessage(JSON.serialize(objectsForDisplay), loggingLevel, tag, isNeedSaveToDb);
    }

    private Log__c createLog(final String message, final String details, final String logType) {
        return new Log__c(
            Message__c = message.left(255),
            Details__c = details.left(32768),
            Type__c = logType
        );
    }
}
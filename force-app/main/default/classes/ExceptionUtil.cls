public class ExceptionUtil {

    public static void sendErrorNotification(final Exception e) {
        sendErrorNotification(e, '');
    }
    
    public static void sendErrorNotification(final Exception e, final String message) {
        sendNotification('Salesforce Apex Exception: ' + e.getTypeName(), e.getMessage() + '\n' + e.getStackTraceString() + '\n' + message);
    }
    
    public static void sendNotification(final String subject, final String message) {
        sendNotification(subject, message, new String[] {'andrey.kuleshov@team.wrike.com'});
    }
    
    public static void sendNotification(final String subject, final String message, final List<String> recipients) {
        if(recipients != null && !recipients.isEmpty()) {
            final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(recipients);
            mail.setSubject(subject);
            mail.setPlainTextBody(message);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

}
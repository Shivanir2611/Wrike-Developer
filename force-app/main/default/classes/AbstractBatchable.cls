public abstract class AbstractBatchable implements Database.Batchable<SObject>{

    protected void sendFailedRecordsNotifications(final Id apexJobId,
                                                  final List<String> recipients) {
        if(!recipients.isEmpty()) {
            final AsyncApexJob completedJob = [
                    SELECT Id, Status, NumberOfErrors, TotalJobItems, ApexClass.Name, ExtendedStatus
                    FROM AsyncApexJob
                    WHERE Id = :apexJobId
            ];
            if(completedJob.NumberOfErrors > 0) {
                final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(recipients);
                mail.setSubject('Failed Batch Update ' + completedJob.ApexClass.Name);
                mail.setPlainTextBody('The batch Apex job processed ' + completedJob.TotalJobItems
                        + ' batches with ' + completedJob.NumberOfErrors
                        + ' failures.\n' + StringUtils.getEmptyIfNull(completedJob.ExtendedStatus));
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
}
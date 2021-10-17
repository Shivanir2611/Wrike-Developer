public class OpportunityEmailService {
    
    @InvocableMethod
    public static void sendNotificationEmail(final List<Id> oppIds){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Closed_Won_Pending_Email_Template' LIMIT 1].Id;
        for(Opportunity opportunity : [
            SELECT Id, Owner.Email, OwnerId
            FROM Opportunity
            WHERE Id IN : oppIds
        ]){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{'billing@team.wrike.com'});
            if(UserInfo.getUserId() != opportunity.OwnerId){
                mail.setCcAddresses(new List<String>{opportunity.Owner.Email});
            }
            mail.setTemplateId(templateId);
            mail.setTargetObjectId(opportunity.OwnerId);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setWhatId(opportunity.Id);
            mail.setsaveAsActivity(false);
            mails.add(mail);
        }
        Messaging.sendEmail(mails);
    }
}
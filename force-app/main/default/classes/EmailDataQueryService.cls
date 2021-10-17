/**
 * @author Andrey Kuleshov
 */
public class EmailDataQueryService {

    public static EmailDataQueryService getInstance() {
        return (EmailDataQueryService)ServiceLocator.getInstance(EmailDataQueryService.class);
    }

    public List<EmailData__c> listByEmails(final Set<String> emails) {
        return [
            SELECT Id, Email__c, UnsubscribedDate__c, ReferralCode__c
            FROM EmailData__c
            WHERE Email__c IN :emails
        ];
    }
}
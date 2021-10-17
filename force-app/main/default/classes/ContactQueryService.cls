/**
 * @author Andrey Kuleshov
 */
public class ContactQueryService {

    public static ContactQueryService getInstance() {
        return (ContactQueryService)ServiceLocator.getInstance(ContactQueryService.class);
    }

    public Contact findContactWithAddressById(final Id contactId) {
        final List<Contact> contacts = [
                SELECT Id, FirstName, LastName, Email,
                       MailingCountryCode, MailingStateCode,
                       MailingCity, MailingStreet, MailingPostalCode
                FROM Contact
                WHERE Id = :contactId
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }

    public Id findContactIdByEmail(final String email) {
        final List<Contact> contacts = [
            SELECT Id
            FROM Contact
            WHERE Email = :email
            ORDER BY CreatedDate
        ];
        return contacts.isEmpty() ? null : contacts[0].Id;
    }

    public Map<String, Id> findEmailContactIdMap(final List<String> emails) {
        final Map<String, Id> emailContactIdMap = new Map<String, Id>();
        final List<Contact> contacts = [
            SELECT Id, Email, Sync_to_Marketo__c
            FROM Contact
            WHERE Email IN :emails
            ORDER BY CreatedDate DESC
        ];
        for(Contact contact : contacts) {
            if(!emailContactIdMap.containsKey(contact.Email) || contact.Sync_to_Marketo__c) {
                emailContactIdMap.put(contact.Email, contact.Id);
            }
        }
        return emailContactIdMap;
    }

    public List<Contact> findByEmails(final Set<String> emails) {
        return [
            SELECT Id, OwnerId, Email, HasOptedOutOfEmail
            FROM Contact
            WHERE Email IN :emails
        ];
    }

    public List<Contact> listAccountContactsByWrikeAccountId(final Id accountId, final Decimal wrikeAccountId) {
        final String uidFilter = wrikeAccountId + '\\_%';
        return [
            SELECT Id, Name, Email, Phone, Title, Department,
                   Wrike_User_Type__c, Wrike_Role__c, Wrike_User_Id__c,
                   VOC_Role__c, VOC_Do_Not_Survey__c
            FROM Contact
            WHERE AccountId = :accountId
              AND Wrike_UID__c != null
              AND Wrike_UID__c LIKE :uidFilter
        ];
    }

    public List<Contact> listSubscriptionContactsByEmail(final String email) {
        return [
            SELECT Id, Name, Email, Phone, Title, Department,
                   Wrike_Account_Id__c, Wrike_User_Id__c, Wrike_User_Type__c, Wrike_Role__c
            FROM Contact
            WHERE Email = :email
              AND Wrike_UID__c != null
              AND Wrike_User_Type__c != 'Deleted'
        ];
    }

    public List<Contact> listByIdsWithActivityData(final List<Id> ids) {
        return [
            SELECT Id, Activity_Data__c
            FROM Contact
            WHERE Id IN :ids
                AND Activity_Data__c != null
        ];
    }
}
public class ContactUpdateJob implements Database.Batchable<SObject>, Schedulable {
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Account.OwnerId
            FROM Contact
            WHERE HasOptedOutOfEmail = false
            AND Does_Not_Match_Account_Owner__c = true
            AND Account.Owner.isActive = true
            AND (Owner.SDR_Type__c = 'Inbound'
                OR Owner.SDR_Type__c = ''
                OR Owner.isActive = false)
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<Contact> contacts) {
        for(Contact newContact : contacts){
            newContact.OwnerId = newContact.Account.OwnerId;
        }
        update contacts;    
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}
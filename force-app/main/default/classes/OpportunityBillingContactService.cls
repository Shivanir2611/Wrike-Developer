public class OpportunityBillingContactService {
    
    public static OpportunityBillingContactService getInstance() {
        return (OpportunityBillingContactService)ServiceLocator.getInstance(OpportunityBillingContactService.class);
    }
    
    public DatabaseService.Result updateOpportunityBillingContact(BillingInfo billingAddress, Opportunity opportunity, Id accountId){
        final Contact contact = getExistingContactOrNew(billingAddress, accountId);
        if(contact.Id == null){
            contact.FirstName = billingAddress.firstName;
            contact.LastName = billingAddress.lastName;
        }
        contact.Email = billingAddress.email;
        contact.MailingCountryCode = billingAddress.country;
        contact.MailingStateCode = billingAddress.state;
        contact.MailingCity = billingAddress.city;
        contact.MailingStreet = String.join(new List<String> {billingAddress.address1, billingAddress.address2}, ' ');
        contact.MailingPostalCode = billingAddress.zip;
        if(contact.Id == null) {
            insert contact;
            insert new OpportunityContactRole(OpportunityId = opportunity.Id, ContactId = contact.Id);
        } else {
            update contact;
        }
        opportunity.Billing_Contact__c = contact.Id;
        final DatabaseService.Result result = DatabaseService.getInstance().updateAndGetResult(new List<Opportunity>{opportunity}, true);
        
        return result;
    }
    
    public BillingInfo getUpdatedBillingAddress(Contact contact, BillingInfo billingAddress, Opportunity opportunity){
        billingAddress.firstName = contact.FirstName;
        billingAddress.lastName = contact.LastName;
        billingAddress.email = contact.Email;
        if(opportunity.Billing_Contact__c == contact.Id) {
            billingAddress.country = contact.MailingCountryCode;
            billingAddress.state = contact.MailingStateCode;
            billingAddress.city = contact.MailingCity;
            billingAddress.address1 = contact.MailingStreet;
            billingAddress.zip = contact.MailingPostalCode;
        }
        return billingAddress;
    }
    
    private Contact getExistingContactOrNew(BillingInfo billingAddress, Id accountId) {
        if(String.isNotBlank(billingAddress.email)) {
            final List<Contact> contactsByEmail = [
                SELECT AccountId, Id
                FROM Contact
                WHERE Email = :billingAddress.email.trim().toLowerCase()
            ];
            if(!contactsByEmail.isEmpty()) {
                return contactsByEmail.get(0);
            }
        }
        return new Contact(AccountId = accountId); 
    }
}
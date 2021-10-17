public class OpportunityEmailController extends AbstractQuoteEmailController {
    private Opportunity opportunity;
    
    public OpportunityEmailController(final ApexPages.StandardController standardController) {
        this.opportunity = 
            [SELECT Id, (SELECT Id, Name FROM Attachments ORDER BY CreatedDate), 
                    (SELECT Contact.Id, Contact.Name, Contact.Email, IsPrimary 
                     FROM OpportunityContactRoles 
                     WHERE Contact.Email != NULL
                     ORDER BY Contact.Name) 
               FROM Opportunity 
              WHERE Id = :StandardController.getRecord().Id];
    }
    
    public override Contact getDefaultContact() {
        if(opportunity.OpportunityContactRoles != null && !opportunity.OpportunityContactRoles.isEmpty()) {
            for(OpportunityContactRole contactRole : opportunity.OpportunityContactRoles) {
                if(contactRole.IsPrimary) {
                    return contactRole.Contact;
                }
            }
            return opportunity.OpportunityContactRoles[0].Contact;
        }
        return null;
    }
    
    public override List<Attachment> getAttachments() {
        return this.opportunity.Attachments != null ? opportunity.Attachments : new List<Attachment>();
    }
    
    public override List<Contact> getContacts() {
        final List<Contact> contacts = new List<Contact>();
        if(opportunity.OpportunityContactRoles != null) {
            for(OpportunityContactRole contactRole : opportunity.OpportunityContactRoles) {
                contacts.add(contactRole.Contact);
            }
        }
        return contacts;
    }
}
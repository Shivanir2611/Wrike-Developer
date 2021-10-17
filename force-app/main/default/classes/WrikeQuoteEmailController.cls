public class WrikeQuoteEmailController extends AbstractQuoteEmailController {

    private final QuoteQueryService quoteQuerySrv = QuoteQueryService.getInstance();
    private final OpportunityContactRoleQueryService opportunityContactRoleQuerySrv = OpportunityContactRoleQueryService.getInstance();
    private final AttachmentQueryService attachmentQuerySrv = AttachmentQueryService.getInstance();

    private Quote__c quote;
    private List<OpportunityContactRole> contactRoles;

    public WrikeQuoteEmailController(final ApexPages.StandardController standardController) {
        List<Quote__c> quotes = this.quoteQuerySrv.findWithOpportunityAndContactById(standardController.getId());
        this.quote = quotes.get(0);
        this.contactRoles = this.opportunityContactRoleQuerySrv.findByOpportunityId(this.quote.Opportunity__c);
    }

    public Quote__c getQuote() {
        return this.quote;
    }

    public override Contact getDefaultContact() {
        if (this.quote.Opportunity__r.Billing_Contact__r != null) {
            return this.quote.Opportunity__r.Billing_Contact__r;
        } else if (!this.contactRoles.isEmpty()) {
            for (OpportunityContactRole ocr : this.contactRoles) {
                if (ocr.IsPrimary) {
                    return ocr.Contact;
                }
            }
            return this.contactRoles.get(0).Contact;
        }
        return null;
    }

    public override List<Attachment> getAttachments() {
        final List<Attachment> attachments = new List<Attachment>();
        if (this.quote.Pdf_Id__c == null) {
            return attachments;
        }
        final List<Attachment> quoteAttachment = this.attachmentQuerySrv.findById(this.quote.Pdf_Id__c);
        if (!quoteAttachment.isEmpty()) {
            attachments.add(quoteAttachment.get(0));
        }
        return attachments;
    }

    public override List<Contact> getContacts() {
        final List<Contact> contacts = new List<Contact>();
        if (this.quote.Opportunity__r.Billing_Contact__r != null) {
            contacts.add(this.quote.Opportunity__r.Billing_Contact__r);
        }
        for (OpportunityContactRole contactRole : this.contactRoles) {
            if (contactRole.Contact.Id == this.quote.Opportunity__r.Billing_Contact__c) {
                continue;
            }
            contacts.add(contactRole.Contact);
        }
        return contacts;
    }
}
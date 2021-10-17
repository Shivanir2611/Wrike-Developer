public class QuoteEmailComponentController {
    public String id {get; set;}
    public String opportunityId {get; set;}
    public String subject {get; set;}
    public String emailText {get; set;}
    public List<Attachment> attachments;
    public List<Contact> contacts;
    public Contact selectedContact;
    public AbstractQuoteEmailController pageController { get; 
        set {
          if (value != null) {
            pageController = value;
            if(this.selectedContact == null) {
                this.selectedContact = pageController.getDefaultContact();
                this.emailText = defaultText();
            }
            if(this.attachments == null) {
                this.attachments = pageController.getAttachments();
            }
            this.contacts = pageController.getContacts();
          }
        }
    }
    
    public QuoteEmailComponentController() {
        this.subject = 'Quote for Wrike Subscription Package';
    }

    private String defaultText() {
        String name = '';
        if (this.selectedContact == null){
            name = '';
        } else if (String.isNotBlank(this.selectedContact.Name)) {
            name = selectedContact.Name;
        }  else {
            name = selectedContact.FirstName + ' ' + selectedContact.LastName;
        }
        return 'Hi ' + name +
                ',\n\nThank you for taking the time to evaluate Wrike. Attached to this email, please find a quote for the Wrike Subscription package we discussed.\n' +
                'I am here to help you with any questions you have throughout this process, so please don\'t hesitate to reach out if I can assist you in anyway.\n\n' +
                'Cheers,\n' + UserInfo.getName();
    }
    
    public PageReference back() {
        return new PageReference('/' + id);
    }
    
    public List<Attachment> getAttachments() {
        return this.attachments;
    }
    
    public List<Contact> getContacts() {
        return this.contacts;
    }
    
    public Contact getSelectedContact() {
        return this.selectedContact;
    }
    
    public PageReference selectContact() {
        String contactId = System.currentPagereference().getParameters().get('contactId');
        if (String.isBlank(contactId)) {
            contactId = null;
        }
        for(Contact contact : getContacts()) {
            if(contact.Id == contactId) {
                if(selectedContact == null || selectedContact.Id != contactId) {
                     this.selectedContact = contact;
                     this.emailText = defaultText();
                }
            }
        }
        return null;
    }
    
    public PageReference send() {
        if(this.selectedContact == null) {
            return null;
        }
        final Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setCharset('UTF-8');
        email.setToAddresses(new String[] {this.selectedContact.Email});
        email.setBccAddresses(new String[] { Userinfo.getUserEmail() });
        email.setSubject(this.subject);
        email.setPlainTextBody(this.emailText);
        if (this.selectedContact.Id != null) {
            email.setTargetObjectId(this.selectedContact.Id);
        }
        email.setWhatId(this.opportunityId);
        email.setSaveAsActivity(true);
        if(!this.attachments.isEmpty()) {
            final List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            final List<String> attachmentIds = new List<String>();
            for(Attachment attachment : this.attachments) {
                attachmentIds.add(attachment.Id);
            }
            final List<Attachment> files = [SELECT Name, Body FROM Attachment WHERE Id IN :attachmentIds ORDER BY CreatedDate];
            for(Attachment attachment : files) {
                final Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attachment.Name);
                efa.setBody(attachment.Body);
                emailAttachments.add(efa);
            }
            email.setFileAttachments(emailAttachments);
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        return new PageReference('/' + opportunityId);
    }
    
    public PageReference removeAttachment() {
        final String id = System.currentPageReference().getParameters().get('attachId');
        for(Integer i = 0; i < this.attachments.size(); i++) {
            if(this.attachments[i].Id.equals(id)) {
                this.attachments.remove(i);    
            }
        }
        return null;
    }
}
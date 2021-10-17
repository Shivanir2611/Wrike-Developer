public abstract class AbstractQuoteEmailController {

    public AbstractQuoteEmailController getThis() {
        return this;
    }
    
    public abstract List<Attachment> getAttachments();
    
    public abstract Contact getDefaultContact();
    
    public abstract List<Contact> getContacts();
}
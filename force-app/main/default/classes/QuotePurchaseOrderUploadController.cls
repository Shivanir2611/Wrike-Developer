public with sharing class QuotePurchaseOrderUploadController {

    private Attachment attachment;
    private final String quoteId;
    private WrikeQuote wQuote;

    private AttachmentService attachmentSrv;
    private QuoteService quoteSrv;

    public QuotePurchaseOrderUploadController() {
        this.attachmentSrv = AttachmentService.getInstance();
        this.quoteSrv = QuoteService.getInstance();

        this.quoteId = ApexPages.currentPage().getParameters().get(RequestParam.QUOTE_ID);
        this.wQuote = quoteSrv.findById(this.quoteId);
        final Attachment existingAttachment = attachmentSrv.findById(this.wQuote.attachemntId);
        this.attachment = existingAttachment != null ? existingAttachment : new Attachment();
    }

    public Attachment getAttachment() {
        return this.attachment;
    }

    public void setAttachment(final Attachment attachment) {
        this.attachment = attachment;
    }

    public PageReference deleteUpload() {
        final Attachment existingFile = attachmentSrv.findById(this.wQuote.attachemntId);
        if (existingFile.Id != null) {
            quoteSrv.updateAttachmentId(this.wQuote.id, null);
            delete existingFile;
            this.attachment = new Attachment();
        }
        return null;
    }

    public PageReference upload() {
        if (this.attachment.Name != null && this.attachment.Body != null) {
            final String extension = this.attachment.Name.trim().substringAfterLast('.');
            this.attachment.Name = 'PO-' + this.wQuote.quoteNumber + (String.isNotBlank(extension) ? '.' + extension : '');
            this.attachment.IsPrivate = false;
            this.attachment.ParentId = wQuote.id;
            insert this.attachment;
            quoteSrv.updateAttachmentId(this.wQuote.id, this.attachment.Id);
            this.attachment = attachmentSrv.findById(this.attachment.Id);
        }
        return null;
    }
}
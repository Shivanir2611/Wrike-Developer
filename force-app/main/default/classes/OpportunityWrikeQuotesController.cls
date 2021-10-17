public class OpportunityWrikeQuotesController extends AbstractPagingController {

    private static final String COMPLETED_STATUS = 'Completed';

    private static final QuoteQueryService quoteQuerySrv = QuoteQueryService.getInstance();
    private static final AttachmentQueryService attachmentQuerySrv = AttachmentQueryService.getInstance();

    private String opportunityId;

    public OpportunityWrikeQuotesController(ApexPages.StandardController standardController) {
        super(10);
        this.opportunityId = standardController.getId();
        List<Quote__c> wrikeQuotes = quoteQuerySrv.findWithDocuSignStatusByOpportunityId(this.opportunityId);
        setTotal(wrikeQuotes.size());
    }

    public List<WrikeQuoteWithDocusign> getWrikeQuotesWithDocuSign() {
        final List<Quote__c> wrikeQuotes = (List<Quote__c>)getRecords();

        final List<WrikeQuoteWithDocusign> quoteWithDocuSignList = new List<WrikeQuoteWithDocusign>();
        final Map<Id, Id> quoteDocuSignStatusIdMap = new Map<Id, Id>();
        for (Quote__c wQuote : wrikeQuotes) {
            WrikeQuoteWithDocusign quoteWithDocuSign = new WrikeQuoteWithDocusign();
            quoteWithDocuSign.id = wQuote.Id;
            quoteWithDocuSign.name = wQuote.Name;
            quoteWithDocuSign.primary = wQuote.Primary__c;
            quoteWithDocuSign.newTerm = Integer.valueOf(wQuote.NewTerm__c);
            quoteWithDocuSign.createdDate = wQuote.CreatedDate;
            quoteWithDocuSign.validUntil = wQuote.ValidUntil__c;
            quoteWithDocuSign.deltaMrr = wQuote.DeltaMrr__c;
            quoteWithDocuSign.status = wQuote.Status__c;
            quoteWithDocuSign.pdfId = wQuote.Pdf_Id__c;

            final dsfs__DocuSign_Status__c selectedDocuSignStatus = findDocuSignStatus(wQuote.DocusignStatus__r);
            if (selectedDocuSignStatus != null) {
                quoteWithDocuSign.docuSignEnvelopeStatus = selectedDocuSignStatus.dsfs__Envelope_Status__c;
                quoteDocuSignStatusIdMap.put(wQuote.Id, selectedDocuSignStatus.Id);
            }
            quoteWithDocuSignList.add(quoteWithDocuSign);
        }
        final Map<Id, Id> documentIdMap = findDocumentIdMap(quoteDocuSignStatusIdMap.values()) ;
        for(WrikeQuoteWithDocusign quote : quoteWithDocuSignList) {
            final Id docuSignStatusId = quoteDocuSignStatusIdMap.get(quote.id);
            quote.signedPdfId = documentIdMap.get(docuSignStatusId);
        }
        return quoteWithDocuSignList;
    }

    private Map<Id, Id> findDocumentIdMap(final List<Id> docuSignStatusIds) {
        final Map<Id, Id> documentIdMap = new Map<Id, Id>();
        if(!docuSignStatusIds.isEmpty()) {
            final List<ContentDocumentLink> documentLinks = [
                    SELECT LinkedEntityId, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :docuSignStatusIds
            ];
            for(ContentDocumentLink documentLink : documentLinks) {
                documentIdMap.put(documentLink.LinkedEntityId, documentLink.ContentDocumentId);
            }
            final List<Attachment> attachments = attachmentQuerySrv.findByParentIds(docuSignStatusIds);
            for(Attachment attachment : attachments) {
                if(!documentIdMap.containsKey(attachment.ParentId)) {
                    documentIdMap.put(attachment.ParentId, attachment.Id);
                }
            }
        }
        return documentIdMap;
    }

    protected override List<SObject> getRecords() {
        return quoteQuerySrv.findWithDocuSignStatusByOpportunityId(opportunityId, pageSize, getOffset());
    }

    private dsfs__DocuSign_Status__c findDocuSignStatus(final List<dsfs__DocuSign_Status__c> docuSignStatuses) {
        for (dsfs__DocuSign_Status__c docuSignStatus : docuSignStatuses) {
            if (docuSignStatus.dsfs__Envelope_Status__c == COMPLETED_STATUS) {
                return docuSignStatus;
            }
        }
        return docuSignStatuses.isEmpty() ? null : docuSignStatuses[0];
    }


    public OpportunityWrikeQuotesController getController() {
        return this;
    }

    public class WrikeQuoteWithDocusign {
        public String id {get; set;}
        public String name {get; set;}
        public Boolean primary {get; set;}
        public Integer newTerm {get; set;}
        public Datetime createdDate {get; set;}
        public Date validUntil {get; set;}
        public Double deltaMrr {get; set;}
        public String status {get; set;}
        public String pdfId {get; set;}
        public String signedPdfId {get; set;}
        public String docuSignEnvelopeStatus {get; set;}

        public String getCreatedDateAsString() {
            return DateUtils.format(this.createdDate);
        }

        public String getValidUntilAsString() {
            return DateUtils.format(this.validUntil);
        }
    }
}
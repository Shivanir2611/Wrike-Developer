public without sharing class CPQWrikeQuoteDocumentsController {

    private final static CPQWrikeQuoteDocumentQueryService wrikeQuoteDocumentQuerySrv = CPQWrikeQuoteDocumentQueryService.getInstance();
    private final static CPQWrikeQuoteDocumentService wrikeQuoteDocumentSrv = CPQWrikeQuoteDocumentService.getInstance();
    private final static UserService userSrv = UserService.getInstance();

    @AuraEnabled
    public static List<DocumentInfo> findDocuments(final Id quoteId) {
        return mapWrikeQuoteDocumentsToDocumentInfo(
                wrikeQuoteDocumentQuerySrv.findWrikeQuoteDocumentsByQuoteId(quoteId));
    }

    @AuraEnabled
    public static List<DocumentInfo> createWrikeQuoteDocuments(final Id quoteId,
                                                               final List<Map<String, String>> files) {
        final List<WrikeQuoteDocument__c> documentsToCreate = new List<WrikeQuoteDocument__c>();
        final List<ContentDocumentLink> accessLinks = new List<ContentDocumentLink>();
        for (Map<String, String> file : files) {
            final Id contentDocumentId = file.get('documentId');
            documentsToCreate.add(new WrikeQuoteDocument__c(
                    Quote__c = quoteId,
                    ContentDocumentId__c = contentDocumentId,
                    Name = file.get('name'),
                    Type__c = 'Quote-Manual'
            ));
            accessLinks.add(new ContentDocumentLink(
                    ContentDocumentId = contentDocumentId,
                    ShareType = 'V',
                    Visibility = 'InternalUsers',
                    LinkedEntityId = quoteId
            ));
        }
        insert documentsToCreate;
        insert accessLinks;
        return mapWrikeQuoteDocumentsToDocumentInfo(
                wrikeQuoteDocumentQuerySrv.findWrikeQuoteDocumentsByQuoteId(quoteId));
    }

    @AuraEnabled
    public static void deleteWrikeQuoteDocument(final Id wrikeQuoteDocumentId) {
        final WrikeQuoteDocument__c document =
                wrikeQuoteDocumentQuerySrv.findWrikeQuoteDocumentsById(wrikeQuoteDocumentId);
        if (document != null
                && wrikeQuoteDocumentSrv.checkDocumentDeletionAllowed(document.Type__c, document.CreatedById)) {
            delete new ContentDocument(Id = document.ContentDocumentId__c);
            delete document;
        }
    }

    private static List<DocumentInfo> mapWrikeQuoteDocumentsToDocumentInfo(final List<WrikeQuoteDocument__c> documents) {
        final List<DocumentInfo> documentInfos = new List<DocumentInfo>();
        for (WrikeQuoteDocument__c document : documents) {
            documentInfos.add(new DocumentInfo(
                    document.Id,
                    document.ContentDocumentId__c,
                    document.Name,
                    document.Type__c,
                    document.CreatedDate,
                    document.CreatedBy
            ));
        }
        return documentInfos;
    }

    @TestVisible
    class DocumentInfo {
        @AuraEnabled
        public Id id {get; set;}
        @AuraEnabled
        public Id contentDocumentId {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public Date uploadDate {get; set;}
        @AuraEnabled
        public User uploader {get; set;}

        DocumentInfo(final Id id,
                     final Id contentDocumentId,
                     final String name,
                     final String type,
                     final Datetime uploadDate,
                     final User uploader) {
            this.id = id;
            this.contentDocumentId = contentDocumentId;
            this.name = name;
            this.type = type;
            this.uploadDate = uploadDate != null
                              ? uploadDate.date()
                              : null;
            this.uploader = uploader;
        }

        @AuraEnabled
        public Boolean getDeletionAllowed() {
            return wrikeQuoteDocumentSrv.checkDocumentDeletionAllowed(type, uploader.Id);
        }
    }
}
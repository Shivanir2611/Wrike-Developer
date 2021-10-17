public class CPQDocumentTriggerHandler {

    public static CPQDocumentTriggerHandler getInstance() {
        return (CPQDocumentTriggerHandler)ServiceLocator.getInstance(CPQDocumentTriggerHandler.class);
    }

    public void afterInsert(final List<SBQQ__QuoteDocument__c> documents) {
        final List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        final Map<Id, Id> pdfDocumentQuoteIds = new Map<Id, Id>();
        for (SBQQ__QuoteDocument__c document : documents) {
            if (document.SBQQ__Quote__c != null) {
                quotes.add(new SBQQ__Quote__c(
                        Id = document.SBQQ__Quote__c,
                        Document__c = document.Id,
                        SBQQ__Status__c = CPQQuote.DocumentGenerated
                ));
                if (document.SBQQ__DocumentId__c != null) {
                    pdfDocumentQuoteIds.put(document.SBQQ__DocumentId__c, document.SBQQ__Quote__c);
                }
            }
        }
        if (!quotes.isEmpty()) {
            update quotes;
        }
        if (!pdfDocumentQuoteIds.isEmpty()) {
            updatePdfDocuments(pdfDocumentQuoteIds);
        }
    }

    private void updatePdfDocuments(final Map<Id, Id> pdfDocumentQuoteIds) {
        final Map<Id, SBQQ__Quote__c> quoteByIdMap = new Map<Id, SBQQ__Quote__c>([
                SELECT Id, Name
                FROM SBQQ__Quote__c
                WHERE Id IN :pdfDocumentQuoteIds.values()
        ]);
        final List<Document> pdfDocuments = new List<Document>();
        for (Id pdfDocumentId : pdfDocumentQuoteIds.keySet()) {
            final String quoteName = quoteByIdMap.get(pdfDocumentQuoteIds.get(pdfDocumentId)).Name;
            pdfDocuments.add(new Document(Id = pdfDocumentId, Name = 'Wrike Quote (' + quoteName + ').pdf'));
        }
        if (!pdfDocuments.isEmpty()) {
            update pdfDocuments;
        }
    }
}
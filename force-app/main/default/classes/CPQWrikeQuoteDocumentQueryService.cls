public class CPQWrikeQuoteDocumentQueryService {

    public static CPQWrikeQuoteDocumentQueryService getInstance() {
        return (CPQWrikeQuoteDocumentQueryService)ServiceLocator.getInstance(CPQWrikeQuoteDocumentQueryService.class);
    }

    public List<WrikeQuoteDocument__c> findWrikeQuoteDocumentsByQuoteId(final Id quoteId) {
        return [
                SELECT Id, Name, ContentDocumentId__c, Type__c, CreatedDate, CreatedBy.Id, CreatedBy.Name
                FROM WrikeQuoteDocument__c
                WHERE Quote__c = :quoteId
        ];
    }

    public WrikeQuoteDocument__c findWrikeQuoteDocumentsById(final Id documentId) {
        final List<WrikeQuoteDocument__c> documents = [
                SELECT Id, Name, ContentDocumentId__c, Type__c, CreatedById
                FROM WrikeQuoteDocument__c
                WHERE Id = :documentId
        ];
        return documents.isEmpty() ? null : documents.get(0);
    }
}
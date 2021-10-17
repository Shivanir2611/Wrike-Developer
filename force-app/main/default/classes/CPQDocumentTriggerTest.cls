@IsTest
public class CPQDocumentTriggerTest {

    @IsTest
    static void testUpdateQuote() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;

        final SBQQ__QuoteDocument__c document = new SBQQ__QuoteDocument__c(SBQQ__Quote__c = quote.Id);
        insert document;

        final SBQQ__Quote__c updatedQuote = findQuoteById(quote.Id);
        System.assertEquals('DocumentGenerated', updatedQuote.SBQQ__Status__c);
        System.assertEquals(document.Id, updatedQuote.Document__c);
    }

    private static SBQQ__Quote__c findQuoteById(Final Id id) {
        return [
                SELECT Id, SBQQ__Status__c, Document__c
                FROM SBQQ__Quote__c
                WHERE Id = :id
        ];
    }
}
@IsTest
public class DocuSignStatusTriggerTest {

    @IsTest
    static void testDocuSignSigned() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Status__c = 'DocuSignSent');
        insert quote;
        final dsfs__DocuSign_Status__c status = new dsfs__DocuSign_Status__c(Quote__c = quote.Id);
        insert status;
        final SBQQ__Quote__c updatedQuoteWithStatus = findQuoteById(quote.Id);
        System.assertEquals(status.Id, updatedQuoteWithStatus.DocuSignStatus__c);

        status.dsfs__Envelope_Status__c = 'Completed';
        update status;
        final SBQQ__Quote__c signedQuote = findQuoteById(quote.Id);
        System.assertEquals('DocuSignSigned', signedQuote.SBQQ__Status__c);
    }

    @IsTest
    static void testDocuSignCancelled() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Status__c = 'DocuSignSent');
        insert quote;
        final dsfs__DocuSign_Status__c status = new dsfs__DocuSign_Status__c(Quote__c = quote.Id);
        insert status;
        final SBQQ__Quote__c updatedQuoteWithStatus = findQuoteById(quote.Id);
        System.assertEquals(status.Id, updatedQuoteWithStatus.DocuSignStatus__c);

        status.dsfs__Envelope_Status__c = 'Voided';
        update status;
        final SBQQ__Quote__c signedQuote = findQuoteById(quote.Id);
        System.assertEquals('DocumentGenerated', signedQuote.SBQQ__Status__c);
    }

    private static SBQQ__Quote__c findQuoteById(final Id quoteId) {
        return [
                SELECT Id, DocuSignStatus__c, SBQQ__Status__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
    }
}
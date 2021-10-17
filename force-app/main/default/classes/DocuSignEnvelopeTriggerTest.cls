@IsTest
public class DocuSignEnvelopeTriggerTest {

    @IsTest
    static void testUpdateQuoteStatus() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Status__c = 'DocumentGenerated');
        insert quote;
        final dsfs__DocuSign_Envelope__c envelope = new dsfs__DocuSign_Envelope__c(dsfs__Source_Object__c = quote.Id);
        insert envelope;
        envelope.dsfs__DocuSign_Envelope_Sent__c = Datetime.now();
        update envelope;
        final SBQQ__Quote__c updatedQuote = findQuoteById(quote.Id);
        System.assertEquals('DocuSignSent', updatedQuote.SBQQ__Status__c);
        System.assertEquals(envelope.Id, updatedQuote.DocuSignEnvelope__c);
    }

    private static SBQQ__Quote__c findQuoteById(final Id quoteId) {
        return [
                SELECT Id, DocuSignEnvelope__c, SBQQ__Status__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
    }
}
@IsTest
public class ContentDocumentLinkTriggerTest {

    @IsTest
    static void testInit() {
        final Id documentId = TestUtils.createContentDocument();
        final SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        final dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c(
                dsfs__Envelope_Status__c = 'Completed',
                Quote__c = quote.Id
        );
        insert docuSignStatus;
        insert new ContentDocumentLink(LinkedEntityId = docuSignStatus.Id, ContentDocumentId = documentId);
        final List<WrikeQuoteDocument__c> wrikeQuoteDocuments = [
                SELECT Id, ContentDocumentId__c, Name
                FROM WrikeQuoteDocument__c
                WHERE Quote__c = :quote.Id
        ];
        System.assertEquals(1, wrikeQuoteDocuments.size());
        final WrikeQuoteDocument__c wrikeQuoteDocument = wrikeQuoteDocuments.get(0);
        System.assertEquals(documentId, wrikeQuoteDocument.ContentDocumentId__c);
        System.assertEquals('Test Document', wrikeQuoteDocument.Name);
    }
}
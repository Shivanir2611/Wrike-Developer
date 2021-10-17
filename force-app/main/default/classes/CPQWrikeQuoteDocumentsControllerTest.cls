@IsTest
public class CPQWrikeQuoteDocumentsControllerTest {

    @IsTest
    static void testCreateWrikeQuoteDocuments() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        final Id documentId = TestUtils.createContentDocument();
        final Map<String, String> file = new Map<String, String> {
            'documentId' => documentId,
            'name' => 'Test Name'
        };
        final List<CPQWrikeQuoteDocumentsController.DocumentInfo> createdDocuments =
                CPQWrikeQuoteDocumentsController.createWrikeQuoteDocuments(quote.Id,
                        new List<Map<String, String>>{file});
        System.assertEquals(1, createdDocuments.size());
        final CPQWrikeQuoteDocumentsController.DocumentInfo documentInfo = createdDocuments.get(0);
        System.assertEquals('Quote-Manual', documentInfo.type);
        System.assertEquals('Test Name', documentInfo.name);
        System.assertEquals(documentId, documentInfo.contentDocumentId);
    }

    @IsTest
    static void testDeleteWrikeQuoteDocuments() {
        final Id documentId = TestUtils.createContentDocument();
        final WrikeQuoteDocument__c wrikeQuoteDocument = new WrikeQuoteDocument__c(
                ContentDocumentId__c = documentId
        );
        insert wrikeQuoteDocument;
        CPQWrikeQuoteDocumentsController.deleteWrikeQuoteDocument(wrikeQuoteDocument.Id);
        System.assertEquals(0, [SELECT Id FROM WrikeQuoteDocument__c WHERE Id = :wrikeQuoteDocument.Id].size());
        System.assertEquals(0, [SELECT Id FROM ContentDocument WHERE Id = :documentId].size());
    }
}
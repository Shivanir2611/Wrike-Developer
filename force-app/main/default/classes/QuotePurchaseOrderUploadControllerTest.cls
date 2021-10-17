@IsTest
public class QuotePurchaseOrderUploadControllerTest {

    @IsTest
    static void testUpload() {
        final Id quoteId = createNewQuote();
        PageReference uploadPage = Page.QuotePurchaseOrderUpload;
        uploadPage.getParameters().put(RequestParam.QUOTE_ID, quoteId);
        Test.setCurrentPage(uploadPage);
        Test.startTest();
        final QuotePurchaseOrderUploadController controller = new QuotePurchaseOrderUploadController();
        System.assertNotEquals(null, controller.getAttachment());
        System.assertEquals(null, controller.getAttachment().Name);
        controller.setAttachment(new Attachment(
                Name = 'test-file.pdf',
                Body = Blob.valueOf('Test File Data')
        ));
        controller.upload();
        System.assertNotEquals(null, findAttachmentId(quoteId));
        Test.setCurrentPage(uploadPage);
        new QuotePurchaseOrderUploadController().deleteUpload();
        System.assertEquals(null, findAttachmentId(quoteId));
        Test.stopTest();
    }

    private static Id createNewQuote() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final Quote__c quote = TestDataFactory.createQuote(opportunity.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        quote.Primary__c = true;
        quote.Status__c = WrikeQuote.Status.PROPOSAL.name();
        insert quote;
        return quote.Id;
    }

    private static Id findAttachmentId(final Id quoteId) {
        final Quote__c quote = [
                SELECT Id, PurchaseOrderAttachmentId__c
                FROM Quote__c
                WHERE Id = :quoteId
        ];
        return quote.PurchaseOrderAttachmentId__c != null
               ? Id.valueOf(quote.PurchaseOrderAttachmentId__c)
               : null;
    }
}
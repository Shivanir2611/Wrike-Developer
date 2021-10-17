@IsTest
public class CPQQuoteTemplateHeaderControllerTest {

    @IsTest
    static void testInit() {
        final SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c();
        insert template;
        insert new CPQSettings__c(QuoteDocumentTemplateId__c = template.Id);
        final SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        final PageReference quoteTemplateHeaderPage = Page.quoteTemplateHeader;
        quoteTemplateHeaderPage.getParameters().put('qid', quote.Id);
        Test.setCurrentPage(quoteTemplateHeaderPage);
        final CPQQuoteTemplateHeaderController controller = new CPQQuoteTemplateHeaderController();
        System.assertEquals(false, controller.hasReseller);
        System.assertEquals(quote.Id, controller.quote.Id);
        System.assertEquals(template.Id, controller.template.Id);
    }
}
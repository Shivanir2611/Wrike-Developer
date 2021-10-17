@IsTest
public class CPQQuoteTemplateSignatureControllerTest {

    @IsTest
    static void testInit() {
        final StaticResource logoStaticResource = [
                SELECT Id, Body
                FROM StaticResource
                WHERE Name = 'quoteWrikeLogo'
        ]; // instead of creation signature static resource
        insert new CPQSettings__c(
                WrikeSignerName__c = 'Test Name',
                WrikeSignatureStaticResourceId__c = logoStaticResource.Id
        );
        final SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        final PageReference quoteTemplateSignatureBlockPage = Page.quoteTemplateSignatureBlock;
        quoteTemplateSignatureBlockPage.getParameters().put('qid', quote.Id);
        Test.setCurrentPage(quoteTemplateSignatureBlockPage);
        final CPQQuoteTemplateSignatureController controller = new CPQQuoteTemplateSignatureController();
        System.assertEquals(DateUtils.format(DateUtils.getPacificLocalDate()), controller.getWrikeSignFormattedDate());
        System.assertEquals(quote.Id, controller.quote.Id);
        System.assertEquals(false, controller.getHasReseller());
        System.assertEquals('Test Name', controller.getWrikeSignerName());
        System.assertNotEquals(null, controller.getWrikeSignatureBase64());
        System.assert(controller.getAdditionalSignatureNumbers().isEmpty());
    }
}
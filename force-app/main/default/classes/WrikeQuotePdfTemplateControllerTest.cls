@IsTest
public class WrikeQuotePdfTemplateControllerTest {

    @IsTest(SeeAllData = true) // required for Zuora API objects
    static void testController() {
        MockApi.mockProductServiceDefault();
        final Id quoteId = createNewQuote();
        final WrikeQuoteZuoraService.SubscriptionPreview subscriptionPreview =
                TestDataFactory.generateSubscriptionPreview(quoteId);
        final QuoteService quoteService = QuoteService.getInstance();
        quoteService.saveSubscriptionPreview(quoteService.getStatusLock(quoteId), subscriptionPreview);
        PageReference pdfTemplatePage = Page.wrikeQuotePdfTemplate;
        pdfTemplatePage.getParameters().put(RequestParam.QUOTE_ID, WrikeUtil.encrypt(quoteId));
        Test.setCurrentPage(pdfTemplatePage);
        Test.startTest();
        final WrikeQuotePdfTemplateController controller = new WrikeQuotePdfTemplateController();
        System.assertEquals(controller, controller.getController());
        System.assertEquals(false, controller.getRenderAdditionalTerms());
        System.assertEquals(false, controller.getNoListPrice());
        final QuoteBundle quoteBundle = controller.getQuoteBundle();
        System.assertNotEquals(null, quoteBundle);
        final InvoicePreview invoicePreview = controller.getInvoicePreview();
        System.assertNotEquals(null, invoicePreview);
        final WrikeQuotePdfTemplateController.DeploymentLanguageData deploymentLanguageData = controller.getDeploymentLanguageData();
        System.assertEquals(true, deploymentLanguageData.getDisplay());
        System.assertEquals(false, deploymentLanguageData.getCustom());
        System.assertEquals('', deploymentLanguageData.getExhibits());
        Test.stopTest();
    }

    private static Id createNewQuote() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final Quote__c quote = TestDataFactory.createQuote(opportunity.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        quote.Primary__c = true;
        insert quote;
        return quote.Id;
    }
}
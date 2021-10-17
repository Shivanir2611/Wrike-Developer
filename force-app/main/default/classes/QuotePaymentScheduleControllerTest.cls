@IsTest
public class QuotePaymentScheduleControllerTest {

    @IsTest(SeeAllData = true) // required for Zuora API objects
    static void testController() {
        final Id quoteId = createNewQuote();
        final WrikeQuoteZuoraService.SubscriptionPreview subscriptionPreview = TestDataFactory.generateSubscriptionPreview(quoteId);
        final QuoteService quoteService = QuoteService.getInstance();
        quoteService.saveSubscriptionPreview(quoteService.getStatusLock(quoteId), subscriptionPreview);
        PageReference paymentSchedulePage = Page.quotePaymentSchedule;
        paymentSchedulePage.getParameters().put(RequestParam.QUOTE_ID, quoteId);
        Test.setCurrentPage(paymentSchedulePage);
        Test.startTest();
        final QuotePaymentScheduleController controller = new QuotePaymentScheduleController();
        System.assertNotEquals(null, controller.getQuote());
        System.assertEquals(quoteId, controller.getQuote().Id);
        System.assertEquals(null, controller.getErrorMessage());
        System.assertNotEquals(null, controller.getPreview());
        System.assertNotEquals(null, controller.getFirstInvoiceDate());
        System.assertNotEquals(null, controller.getInvoices());
        System.assertEquals(1, controller.getInvoices().size());
        final QuotePaymentScheduleController.InvoiceBundle invoiceBundle = controller.getInvoices()[0];
        System.assertEquals(3, invoiceBundle.getAllItems().size());
        System.assertEquals(3330.0, invoiceBundle.getRecurrentTotal());
        System.assertEquals(2, invoiceBundle.getRecurrentItems().size());
        System.assertEquals(2000, invoiceBundle.getOneTimeTotal());
        System.assertEquals(1, invoiceBundle.getOneTimeItems().size());
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
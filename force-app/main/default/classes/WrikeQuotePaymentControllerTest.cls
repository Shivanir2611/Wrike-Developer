@IsTest
public class WrikeQuotePaymentControllerTest {

    @IsTest
    static void testController() {
        insert TestDataFactory.createSettings();
        Test.setMock(HttpCalloutMock.class, new ZuoraSignatureUtilTest.ZuoraSignatureMock());
        MockApi.setup()
               .mock(MockApi.zuoraRestQueryService().findCreditCardInfoByAccountId(''), null)
               .mockStrict(MockApi.zuoraRestQueryService().findCreditCardInfoById('abcdef1234567890abcdef1234567890', false), new BillingInfo())
               .build();
        ServiceLocator.setInstance(ZuoraService.class, MockApi.mock(ZuoraService.class));
        final Id quoteId = createNewQuote();
        PageReference newQuotePage = Page.quotePaymentPage;
        newQuotePage.getParameters().put('q', WrikeUtil.encrypt(quoteId));
        Test.setCurrentPage(newQuotePage);
        Test.startTest();
        System.assertNotEquals(null, new WrikeQuotePaymentController().getSignature());
        newQuotePage.getParameters().put('paymentMethodId', 'abcdef1234567890abcdef1234567890');
        new WrikeQuotePaymentController().savePaymentMethod();
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
}
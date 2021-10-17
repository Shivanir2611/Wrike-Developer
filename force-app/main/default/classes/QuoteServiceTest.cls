@IsTest
private class QuoteServiceTest {

    @TestSetup
    static void setup() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Contact testContact = TestDataFactory.createContact(testAccount.Id);
        TestUtils.insertAndAssert(testContact);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, testContact.Id, 100);
        TestUtils.insertAndAssert(testOpportunity);

        Quote__c testQuote = TestDataFactory.insertDraftAmendmentQuote(testOpportunity.Id);
    }

    @IsTest
    static void testFindById() {
        List<Quote__c> quotes = TestUtils.findQuotes();
        System.assertEquals(1, quotes.size());

        Test.startTest();

        QuoteService quoteSrv = QuoteService.getInstance();
        WrikeQuote wQuote = quoteSrv.findById(quotes.get(0).Id);
        System.assertEquals(quotes.get(0).Id, wQuote.id);

        Test.stopTest();
    }

    @IsTest
    static void testListNonSentQuoteIds() {
        List<Quote__c> quotes = TestUtils.findQuotes();
        System.assertEquals(1, quotes.size());

        Test.startTest();

        QuoteService quoteSrv = QuoteService.getInstance();
        List<Id> nonSentQUoteIds = quoteSrv.listNonSentQuoteIds(new List<String>{quotes.get(0).Id});
        System.assertEquals(1, nonSentQUoteIds.size());
        System.assertEquals(quotes.get(0).Id, nonSentQUoteIds.get(0));

        Test.stopTest();
    }

    @IsTest
    static void testCrudSubscriptionPreview() {
        List<Quote__c> quotes = TestUtils.findQuotes();
        System.assertEquals(1, quotes.size());
        Quote__c myQuote = quotes.get(0);

        Test.startTest();

        QuoteService quoteSrv = QuoteService.getInstance();

        QuoteService.StatusLock quoteStatusLock = quoteSrv.getStatusLock(myQuote.Id);

        WrikeQuote wQuote = quoteSrv.findById(myQuote.Id);

        WrikeQuoteZuoraService.SubscriptionPreview preview = new WrikeQuoteZuoraService.SubscriptionPreviewBuilder(wQuote).
            setSuccess(false).build();
        quoteSrv.saveSubscriptionPreview(quoteStatusLock, preview);

        WrikeQuoteZuoraService.SubscriptionPreview savedPreview = quoteSrv.getSavedSubscriptionPreview(myQuote.Id);
        System.assertEquals(preview.isSuccess(), savedPreview.isSuccess());

        myQuote.Status__c = WrikeQuote.Status.PROPOSAL.name();
        TestUtils.updateAndAssert(myQuote);

        quoteStatusLock = quoteSrv.getStatusLock(myQuote.Id);
        quoteSrv.removeInvoicePreview(quoteStatusLock);

        quotes = TestUtils.findQuotes();
        System.assertEquals(1, quotes.size());
        System.assertEquals(WrikeQuote.Status.APPROVED.name(), quotes.get(0).Status__c);

        Test.stopTest();
    }

    @IsTest
    static void testCrudQuoteOperation() {
        List<Quote__c> quotes = TestUtils.findQuotes();
        System.assertEquals(1, quotes.size());
        Quote__c myQuote = quotes.get(0);
        System.assert(myQuote.Quote_Operations__r.isEmpty());

        Test.startTest();

        QuoteService quoteSrv = QuoteService.getInstance();
        quoteSrv.addSendQuoteOperation(myQuote.Id);
        quotes = TestUtils.findQuotes();
        System.assertEquals(1, quotes.get(0).Quote_Operations__r.size());

        quoteSrv.removeSendQuoteOperation(myQuote.Id);
        quotes = TestUtils.findQuotes();
        System.assertEquals(0, quotes.get(0).Quote_Operations__r.size());

        Test.stopTest();
    }

    @IsTest
    static void testStatus() {
        List<Quote__c> quotes = TestUtils.findQuotes();
        System.assertEquals(1, quotes.size());
        quotes.get(0).Status__c = WrikeQuote.Status.APPROVED.name();
        TestUtils.updateAndAssert(quotes.get(0));

        Test.startTest();

        QuoteService quoteSrv = QuoteService.getInstance();
        QuoteService.StatusLock quoteStatusLock = quoteSrv.getStatusLock(quotes.get(0).Id);

        InvoicePreview invoicePreview = new InvoicePreview(Date.today(), new List<Invoice>());
        invoicePreview.deltaMrr = 100;
        invoicePreview.totalChargeAmount = 100;
        quoteSrv.setProposal(quoteStatusLock, invoicePreview, '00P000000000000');

        quoteStatusLock = quoteSrv.getStatusLock(quotes.get(0).Id);
        quoteSrv.markQuoteSentToZuora(quoteStatusLock);
        quotes = TestUtils.findQuotes();
        System.assertEquals(WrikeQuote.Status.SENT.name(), quotes.get(0).Status__c);

        quoteSrv.updateAttachmentId(quotes.get(0).Id, 'AttachmentId');
        quotes = TestUtils.findQuotes();
        System.assertEquals('AttachmentId', quotes.get(0).PurchaseOrderAttachmentId__c);

        Test.stopTest();
    }

    @IsTest
    static void testMarkPrimary() {
        final Opportunity opportunity = TestUtils.findOpportunity();
        final Quote__c quote1 = TestDataFactory.insertDraftAmendmentQuote(opportunity.Id);
        final Quote__c quote2 = TestDataFactory.insertDraftAmendmentQuote(opportunity.Id);
        final QuoteService quoteSrv = QuoteService.getInstance();
        Test.startTest();
        quoteSrv.markPrimary(quote1.Id);
        System.assertEquals(true, TestUtils.findQuoteById(quote1.Id)[0].Primary__c);
        quoteSrv.markPrimary(quote2.Id);
        System.assertEquals(false, TestUtils.findQuoteById(quote1.Id)[0].Primary__c);
        System.assertEquals(true, TestUtils.findQuoteById(quote2.Id)[0].Primary__c);
        Test.stopTest();
    }
}
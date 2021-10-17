@IsTest
private class WrikeViewQuoteControllerTest {

    @TestSetup
    static void setup() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 100);
        testOpportunity.RecordTypeId = RecordTypeQueryService.getInstance().getOpportunityRecordTypeIdByDevName(RecordTypeQueryService.OPPORTUNITY_RENEWAL);
        TestUtils.insertAndAssert(testOpportunity);
    }

    static {
        Zuora.zApi.SubscribeResult subscribeResult = (Zuora.zApi.SubscribeResult)JSON.deserialize('{}', Zuora.zApi.SubscribeResult.class);
        subscribeResult.Success = true;
        Zuora.zApi.AmendResult amendResult = (Zuora.zApi.AmendResult)JSON.deserialize('{}', Zuora.zApi.AmendResult.class);
        amendResult.Success = true;

        final WrikeQuoteZuoraService wrikeQuoteZuoraSrvMock =
                (WrikeQuoteZuoraService)MockApi.mock(WrikeQuoteZuoraService.class);
        MockApi.mockQuoteValidatorCreation();
        MockApi.mockProductServiceDefault();
        MockApi.mockZuoraRestQueryServiceDefault();
        MockApi.setup()
                .mock(MockApi.zuoraProductCatalogService().getProductWithRatePlansChargesTiers(ZuoraCurrency.USD),
                TestDataFactory.getProductWithRatePlansChargesTiers())
                .mock(wrikeQuoteZuoraSrvMock.zSubscribe(null), new List<Zuora.zApi.SubscribeResult>{subscribeResult})
                .mock(wrikeQuoteZuoraSrvMock.zamend(null), amendResult)
                .build();
    }

    @IsTest
    static void testSubmitForApprovalAndCancel() {
        Test.startTest();

        String quoteId = TestDataFactory.insertNewQuoteThroughController();

        PageReference viewQuotePage = Page.ViewQuote;
        viewQuotePage.getParameters().put(RequestParam.ID_PARAM, quoteId);
        Test.setCurrentPage(viewQuotePage);

        Quote__c newQuote = new Quote__c(Id = quoteId);
        ApexPages.StandardController standardController = new ApexPages.StandardController(newQuote);
        WrikeViewQuoteController viewQuoteController = new WrikeViewQuoteController(standardController);
        System.assert(viewQuoteController.getValidationResults().getIsValid());

        Map<String, String> amendmentTypeToDescription = viewQuoteController.getAmendmentTypeToDescription();
        System.assertEquals(4, amendmentTypeToDescription.size());

        viewQuoteController.getWrikeAccountUrl();
        viewQuoteController.editProducts();
        viewQuoteController.sendWithDocuSign();
        viewQuoteController.sendQuote();

        System.assertEquals(null, viewQuoteController.getPdf());

//        viewQuoteController.wQuote.status = WrikeQuote.Status.TRIAL;
//        viewQuoteController.submitForApproval();
//        System.assert(viewQuoteController.getValidationResults().getIsValid());
//        System.assert(viewQuoteController.wQuote.getIsApprovalPending());
//        System.assert(!viewQuoteController.wQuote.getIsApprovalCompleted());
//        viewQuoteController.cancelApproval();
//        System.assert(!viewQuoteController.wQuote.getIsApprovalPending());

//        viewQuoteController.generateQuotePreview();
//        viewQuoteController.generatePdf();

        Test.stopTest();
    }

    @IsTest
    static void testInvalidInit() {
        Quote__c newQuote = new Quote__c(Id = Quote__c.sobjecttype.getDescribe().getKeyPrefix() + '000000000000');
        ApexPages.StandardController standardController = new ApexPages.StandardController(newQuote);
        WrikeViewQuoteController viewQuoteController = new WrikeViewQuoteController(standardController);
        System.assert(viewQuoteController.getValidationResults().getIsNotValid());
    }

    @IsTest
    static void testDeleteDraftQuote() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote = TestDataFactory.insertDraftAmendmentQuote(opportunities.get(0).Id);
        subscriptionQuote.Zuora_Subscription_Id__c = 'testSubscriptionId';
        TestUtils.updateAndAssert(subscriptionQuote);

        List<Quote__c> quoteWithItems = TestUtils.findQuoteById(subscriptionQuote.Id);
        System.assertEquals(1, quoteWithItems.size());

        WrikeHttpMock wrikeMock = new WrikeHttpMock();
        Test.setMock(HttpCalloutMock.class, wrikeMock);

        Test.startTest();

        PageReference viewQuotePage = Page.ViewQuote;
        viewQuotePage.getParameters().put(RequestParam.ID_PARAM, subscriptionQuote.Id);
        Test.setCurrentPage(viewQuotePage);

        ApexPages.StandardController standardController = new ApexPages.StandardController(subscriptionQuote);
        WrikeViewQuoteController viewQuoteController = new WrikeViewQuoteController(standardController);
        System.assert(viewQuoteController.getValidationResults().getIsValid());

        viewQuoteController.deleteQuote();

        Test.stopTest();

        List<Quote__c> quoteAfterDelete = TestUtils.findQuoteById(subscriptionQuote.Id);
        System.assertEquals(0, quoteAfterDelete.size());

        List<String> quoteProductIds = SobjectUtils.extractNotNullByFieldName(quoteWithItems.get(0).Quote_Items__r, 'Product__c');
        List<Quote_Product__c> quoteProducts = TestUtils.findQuoteProductsByIds(quoteProductIds);
        System.assertEquals(0, quoteProducts.size());
    }

    @IsTest
    static void testDeleteTrialQuote() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote = TestDataFactory.insertDraftAmendmentQuote(opportunities.get(0).Id);
        subscriptionQuote.Status__c = WrikeQuote.Status.TRIAL.name();
        subscriptionQuote.Zuora_Subscription_Id__c = 'testSubscriptionId';
        TestUtils.updateAndAssert(subscriptionQuote);

        List<Quote__c> quoteWithItems = TestUtils.findQuoteById(subscriptionQuote.Id);
        System.assertEquals(1, quoteWithItems.size());

        WrikeHttpMock wrikeMock = new WrikeHttpMock();
        Test.setMock(HttpCalloutMock.class, wrikeMock);

        Test.startTest();

        PageReference viewQuotePage = Page.ViewQuote;
        viewQuotePage.getParameters().put(RequestParam.ID_PARAM, subscriptionQuote.Id);
        Test.setCurrentPage(viewQuotePage);

        ApexPages.StandardController standardController = new ApexPages.StandardController(subscriptionQuote);
        WrikeViewQuoteController viewQuoteController = new WrikeViewQuoteController(standardController);
        System.assert(viewQuoteController.getValidationResults().getIsValid());

        System.assert(viewQuoteController.getHasDeleteAccess());
        viewQuoteController.deleteQuote();

        Test.stopTest();

        List<Quote__c> quoteAfterDelete = TestUtils.findQuoteById(subscriptionQuote.Id);
        System.assertEquals(0, quoteAfterDelete.size());

        List<String> quoteProductIds = SobjectUtils.extractNotNullByFieldName(quoteWithItems.get(0).Quote_Items__r, 'Product__c');
        List<Quote_Product__c> quoteProducts = TestUtils.findQuoteProductsByIds(quoteProductIds);
        System.assertEquals(0, quoteProducts.size());

        WrikeHttpMock.assertNumberOfActionInvocation('delete_quotes', 1);
    }

    @IsTest
    static void testDuplicateQuote() {
        ZuoraObject.ZuoraAccount zAccount = TestDataFactory.createZuoraAccount('zuoraAccountId', '100');

        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote = TestDataFactory.insertDraftSubscriptionQuote(opportunities.get(0).Id);
        subscriptionQuote.Status__c = WrikeQuote.Status.PROPOSAL.name();
        subscriptionQuote.EffectiveDate__c = Date.today().addDays(-1);
        TestUtils.updateAndAssert(subscriptionQuote);

        Attachment pdf = TestDataFactory.createAttachment(subscriptionQuote.Id);
        TestUtils.insertAndAssert(pdf);

        subscriptionQuote.Pdf_Id__c = pdf.Id;
        TestUtils.updateAndAssert(subscriptionQuote);

        List<Quote__c> quoteWithItems = TestUtils.findQuoteById(subscriptionQuote.Id);
        System.assertEquals(1, quoteWithItems.size());

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findSubscriptionsByZuoraAccountId(subscriptionQuote.Zuora_Account_Id__c), new List<ZuoraObject.ZuoraSubscription>())
                .mockStrict(MockApi.zuoraRestQueryService().getZuoraAccounts(subscriptionQuote.Zuora_Account_Id__c, subscriptionQuote.WrikeAccountId__c, 'Canceled'), new List<ZuoraObject.ZuoraAccount>{zAccount})
                .build();
        Test.startTest();

        PageReference viewQuotePage = Page.ViewQuote;
        viewQuotePage.getParameters().put(RequestParam.ID_PARAM, subscriptionQuote.Id);
        Test.setCurrentPage(viewQuotePage);

        ApexPages.StandardController standardController = new ApexPages.StandardController(subscriptionQuote);
        WrikeViewQuoteController viewQuoteController = new WrikeViewQuoteController(standardController);
        System.assert(viewQuoteController.getValidationResults().getIsValid());

        System.assert(viewQuoteController.getIsDuplicateVisible());
        PageReference duplicateQuoteViewPage = viewQuoteController.duplicate();
        System.assertNotEquals(null, duplicateQuoteViewPage);

        Test.stopTest();

        String duplicateQuoteId = duplicateQuoteViewPage.getUrl().substringAfter('/');
        System.assertNotEquals(subscriptionQuote.Id, duplicateQuoteId);

        List<Quote__c> duplicatedQuote = TestUtils.findQuoteById(duplicateQuoteId);
        System.assertEquals(quoteWithItems.get(0).Quote_Items__r.size(), duplicatedQuote.get(0).Quote_Items__r.size());

        WrikeHttpMock.assertNumberOfActionInvocation('new_quote', 1);
    }

    @IsTest
    static void testUpdateFromTrialDraftQuote() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote = TestDataFactory.createQuote(opportunities.get(0).Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        subscriptionQuote.Status__c = WrikeQuote.Status.TRIAL.name();
        TestUtils.insertAndAssert(subscriptionQuote);

        WrikeHttpMock wrikeMock = new WrikeHttpMock();
        Test.setMock(HttpCalloutMock.class, wrikeMock);

        Test.startTest();

        subscriptionQuote.Status__c = WrikeQuote.Status.DRAFT.name();
        TestUtils.updateAndAssert(subscriptionQuote);

        Test.stopTest();

        WrikeHttpMock.assertNumberOfActionInvocation('delete_quotes', 1);
    }

    @IsTest
    static void testCancelTrialQuote() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote = TestDataFactory.insertDraftAmendmentQuote(opportunities.get(0).Id);
        subscriptionQuote.Zuora_Subscription_Id__c = 'testSubscriptionId';
        subscriptionQuote.Status__c = WrikeQuote.Status.TRIAL.name();
        TestUtils.updateAndAssert(subscriptionQuote);

        WrikeHttpMock wrikeMock = new WrikeHttpMock();
        Test.setMock(HttpCalloutMock.class, wrikeMock);

        Test.startTest();

        PageReference viewQuotePage = Page.ViewQuote;
        viewQuotePage.getParameters().put(RequestParam.ID_PARAM, subscriptionQuote.Id);
        Test.setCurrentPage(viewQuotePage);

        ApexPages.StandardController standardController = new ApexPages.StandardController(subscriptionQuote);
        WrikeViewQuoteController viewQuoteController = new WrikeViewQuoteController(standardController);
        System.assert(viewQuoteController.getValidationResults().getIsValid());

        System.assert(viewQuoteController.getHasEditAccess());
        viewQuoteController.cancelQuote();

        List<Quote__c> cancelledQuotes = TestUtils.findQuoteById(subscriptionQuote.Id);
        System.assertEquals(1, cancelledQuotes.size());
        System.assertEquals(WrikeQuote.Status.CANCEL.name(), cancelledQuotes.get(0).Status__c);

        Test.stopTest();

        WrikeHttpMock.assertNumberOfActionInvocation('delete_quotes', 1);
    }
}
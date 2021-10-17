@IsTest
private class SendQuoteControllerTest {

    @TestSetup
    static void setup() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Contact testContact = TestDataFactory.createContact(testAccount.Id);
        TestUtils.insertAndAssert(testContact);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, testContact.Id, 100);
        TestUtils.insertAndAssert(testOpportunity);
    }

    static {
        MockApi.mockQuoteValidatorCreation();
        MockApi.mockZuoraRestQueryServiceDefault();
        MockApi.mockProductServiceDefault();
        MockApi.setup()
                .mock(MockApi.zuoraProductCatalogService().getProductWithRatePlansChargesTiers(ZuoraCurrency.USD),
                TestDataFactory.getProductWithRatePlansChargesTiers())
                .build();
    }

    @IsTest
    static void testSend() {
        Test.startTest();
        String quoteId = TestDataFactory.insertNewQuoteThroughController();

        TestUtils.updateAndAssert(new Quote__c(Id = quoteId, Status__c = WrikeQuote.Status.PROPOSAL.name()));

        Test.setMock(WebServiceMock.class, new CheckVatMock());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.ID_PARAM, quoteId);
        Test.setCurrentPage(newQuotePage);

        SendQuoteController sendController = new SendQuoteController();

        System.assertNotEquals(null, sendController.wQuote);
        System.assert(!sendController.getVatNumberRequired());

        sendController.getIsAdmin();
        sendController.getSelectedBillingInfo();
        newQuotePage.getParameters().put('paymentMethod', 'zuoraCreditCard');
        sendController.selectPaymentMethod();
        sendController.getNextAvailable();
        sendController.back();

        sendController.checkVatNumber();
        System.assert(sendController.isVatNumberValid);

        sendController.getSelectedBillingInfo().country = 'US';
        sendController.getSelectedBillingInfo().vatNumber = 'US123';
        sendController.checkVatNumber();
        System.assert(sendController.isVatNumberValid);

        sendController.validateSendQuoteOperation();
        sendController.sendQuote();

        //TODO: Test send to Zuora Impl

        Test.stopTest();
    }

    @IsTest
    static void testInvalidInit() {
        PageReference newQuotePage = Page.AmendmentQuote;
        Test.setCurrentPage(newQuotePage);

        Test.startTest();

        SendQuoteController sendController = new SendQuoteController();
        System.assert(sendController.getValidationResults().getIsNotValid());

        Test.stopTest();
    }
}
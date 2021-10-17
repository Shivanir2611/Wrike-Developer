@IsTest
private class WrikeSubscriptionQuoteControllerTest {

    @TestSetup
    static void setup() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 100);
        TestUtils.insertAndAssert(testOpportunity);
    }

    static {
        MockApi.mockQuoteValidatorCreation();
        MockApi.mockProductServiceDefault();
        MockApi.setup()
                .mock(MockApi.zuoraProductCatalogService().getProductWithRatePlansChargesTiers(ZuoraCurrency.USD),  TestDataFactory.getProductWithRatePlansChargesTiers())
                .build();
    }

    @IsTest
    static void testAddNewLicenseProduct() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.SubscriptionQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeSubscriptionQuoteController quoteController = new WrikeSubscriptionQuoteController();
        quoteController.getInstance();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.getMinEffectiveDate();
        quoteController.getMaxEffectiveDate();
        quoteController.getMinVaidUntilDate();
        quoteController.getMaxVaidUntilDate();
        quoteController.getMinInvoiceDate();
        quoteController.getMaxInvoiceDate();
        quoteController.getSubscriptionStartDate();
        quoteController.getSubscriptionEndDate();
        quoteController.getFirstDateOfCurrentMonth();
        quoteController.getLastDateOfEffectiveDateMonth();
        quoteController.getQuoteValidDays();
        quoteController.getIsSaveQuoteDetailsVisible();
        quoteController.effectiveDateChangeHandler();

        quoteController.wQuote.newTerm = 12;
        quoteController.wQuote.renewalTerm = 12;
        quoteController.wQuote.numberOfTeams = 0;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid(),
                quoteController.getValidationResults().getResult());

        PageReference saveResult = quoteController.saveQuote();
        System.assertEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.showNewProductSection();
        System.assertEquals(3, quoteController.getProductOptions().size());
        System.assertEquals(1, quoteController.getProductPlanOptions().size());
        quoteController.showNewDeploymentSection();
        System.assertEquals(2, quoteController.getProductOptions().size());
        System.assertEquals(1, quoteController.getProductPlanOptions().size());

        quoteController.newProduct.zuoraProductId = 'id1';
        System.assertEquals(3, quoteController.getProductPlanOptions().size());

        quoteController.changeProductHandler();
        System.assertEquals('Annual', quoteController.newProduct.billingPeriodName);

        quoteController.newProduct.zuoraProductRatePlanId = 'productRatePlanId3';
        quoteController.populatePrice();
        System.assertEquals(5, quoteController.newProduct.quantity);
        System.assertEquals(500, quoteController.newProduct.billingIntervalListPrice);
        System.assertEquals(499.8, quoteController.newProduct.effectivePrice);
        System.assertEquals(8.33, quoteController.newProduct.effectivePricePerUserPerMonth);

        quoteController.newProduct.effectivePricePerUserPerMonth = 7.5;
        quoteController.recalculateByPrice();
        System.assertEquals(10, quoteController.newProduct.discount);

        quoteController.newProduct.discount = 20;
        quoteController.recalculateByDiscount();
        System.assertEquals(6.67, quoteController.newProduct.effectivePricePerUserPerMonth);
        System.assertEquals(400.2, quoteController.newProduct.effectivePrice);

        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(1, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);

        saveResult = quoteController.saveQuote();
        System.assertNotEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsValid());

        Test.stopTest();
    }

    @IsTest
    static void testEditQuoteDetails() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote = TestDataFactory.insertDraftSubscriptionQuote(opportunities.get(0).Id);

        PageReference newQuotePage = Page.SubscriptionQuote;
        newQuotePage.getParameters().put(RequestParam.QUOTE_ID, subscriptionQuote.Id);
        newQuotePage.getParameters().put(RequestParam.STEP, WrikeQuoteBaseController.QUOTE_DETAILS_STEP);
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeSubscriptionQuoteController quoteController = new WrikeSubscriptionQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.wQuote.newTerm = 1;
        quoteController.wQuote.renewalTerm = 1;
        quoteController.changeTermHandler();

        PageReference saveResult = quoteController.saveQuoteDetails();
        System.assertNotEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsValid());

        Test.stopTest();
    }

    @IsTest
    static void testAddNewLicenseProductWithEffectiveDateInThePast() {
        TestDataFactory.insertSalesSettings();
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.SubscriptionQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeSubscriptionQuoteController quoteController = new WrikeSubscriptionQuoteController();
        quoteController.getInstance();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        final Date effectiveDate = Date.today().addMonths(-1);
        quoteController.wQuote.effectiveDate = effectiveDate;
        quoteController.wQuote.invoiceDate = effectiveDate.addDays(-1);
        quoteController.wQuote.newTerm = 12;
        quoteController.wQuote.renewalTerm = 12;
        quoteController.wQuote.numberOfTeams = 0;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.effectiveDateChangeHandler();
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid(),
                quoteController.getValidationResults().getResult());

        PageReference saveResult = quoteController.saveQuote();
        System.assertEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.showNewProductSection();
        System.assertEquals(3, quoteController.getProductOptions().size());
        System.assertEquals(1, quoteController.getProductPlanOptions().size());
        quoteController.showNewDeploymentSection();
        System.assertEquals(2, quoteController.getProductOptions().size());
        System.assertEquals(1, quoteController.getProductPlanOptions().size());

        quoteController.newProduct.zuoraProductId = 'id1';
        System.assertEquals(3, quoteController.getProductPlanOptions().size());

        quoteController.changeProductHandler();
        System.assertEquals('Annual', quoteController.newProduct.billingPeriodName);

        quoteController.newProduct.zuoraProductRatePlanId = 'productRatePlanId3';
        quoteController.populatePrice();
        System.assertEquals(5, quoteController.newProduct.quantity);
        System.assertEquals(500, quoteController.newProduct.billingIntervalListPrice);
		System.assertEquals(499.8, quoteController.newProduct.effectivePrice);
        System.assertEquals(8.33, quoteController.newProduct.effectivePricePerUserPerMonth);

        quoteController.newProduct.effectivePricePerUserPerMonth = 7.5;
        quoteController.recalculateByPrice();
        System.assertEquals(10, quoteController.newProduct.discount);

        quoteController.newProduct.discount = 20;
        quoteController.recalculateByDiscount();
        System.assertEquals(6.67, quoteController.newProduct.effectivePricePerUserPerMonth);
        System.assertEquals(400.2, quoteController.newProduct.effectivePrice);

        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(1, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);

        saveResult = quoteController.saveQuote();
        System.assertNotEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsValid());

        Test.stopTest();
    }
}
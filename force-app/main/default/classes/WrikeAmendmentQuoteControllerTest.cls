@IsTest
private class WrikeAmendmentQuoteControllerTest {

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
        MockApi.mockZuoraRestQueryServiceDefault();
        MockApi.mockProductServiceDefault();
        MockApi.setup()
                .mock(MockApi.zuoraProductCatalogService().getProductWithRatePlansChargesTiers(ZuoraCurrency.USD),  TestDataFactory.getProductWithRatePlansChargesTiers())
                .build();
    }

    @IsTest
    static void testAddNewLicenseProduct() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        newQuotePage.getParameters().put(RequestParam.ZUORA_ACCOUNT_ID, 'zuoraAccountId');
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeAmendmentQuoteController quoteController = new WrikeAmendmentQuoteController();
        quoteController.getInstance();
        System.assert(quoteController.getValidationResults().getIsValid());

        quoteController.getAmendmentTypeToControlVisibility();
        List<SelectOption> avalibleAmendmentTypes = quoteController.getAvalibleAmendmentTypes();
        System.assertEquals(4, avalibleAmendmentTypes.size());

        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsNotValid());
        System.assertEquals(quoteController.getAmendmentTypeSelectStepName(), quoteController.step);

        quoteController.wQuote.currentTerm = 12;
        quoteController.wQuote.amendmentType = WrikeQuote.AmendmentType.AMEND_ON_RENEWAL;
        quoteController.next();
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
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getProductsTableStepName(), quoteController.step);
        System.assertEquals(2, quoteController.wQuote.items.size());

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
        System.assertEquals(3, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[2].state);

        saveResult = quoteController.saveQuote();
        System.assertNotEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsValid());

        Test.stopTest();
    }

    @IsTest
    static void testRemoveAndRestoreExistingProducts() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        newQuotePage.getParameters().put(RequestParam.ZUORA_ACCOUNT_ID, 'zuoraAccountId');
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeAmendmentQuoteController quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());

        List<SelectOption> avalibleAmendmentTypes = quoteController.getAvalibleAmendmentTypes();
        System.assertEquals(4, avalibleAmendmentTypes.size());

        quoteController.wQuote.currentTerm = 12;
        quoteController.wQuote.amendmentType = WrikeQuote.AmendmentType.AMEND_ON_RENEWAL;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getProductsTableStepName(), quoteController.step);
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);

        quoteController.removeProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);

        quoteController.wQuote.items[0].uid = 'uid1';
        quoteController.wQuote.items[1].uid = 'uid2';

        quoteController.deleteItemUID = 'uid1';
        quoteController.removeProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);

        quoteController.deleteItemUID = 'uid2';
        quoteController.removeProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[1].state);

        quoteController.deleteItemUID = 'uid1';
        quoteController.restoreProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[1].state);

        quoteController.deleteItemUID = 'uid2';
        quoteController.restoreProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);

        PageReference saveResult = quoteController.saveQuote();
        System.assertEquals(null, saveResult);

        Test.stopTest();
    }

    @IsTest
    static void testAddAndRemoveNewProduct() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        newQuotePage.getParameters().put(RequestParam.ZUORA_ACCOUNT_ID, 'zuoraAccountId');
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeAmendmentQuoteController quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());
        quoteController.wQuote.currentTerm = 12;
        quoteController.wQuote.amendmentType = WrikeQuote.AmendmentType.AMEND_ON_RENEWAL;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getProductsTableStepName(), quoteController.step);
        System.assertEquals(2, quoteController.wQuote.items.size());

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

        quoteController.recalculateByPrice();
        System.assertEquals(499.8, quoteController.newProduct.effectivePrice);
        System.assertEquals(8.33, quoteController.newProduct.effectivePricePerUserPerMonth);
        System.assertEquals(0.04, quoteController.newProduct.discount);

        quoteController.addNewProduct();

        quoteController.wQuote.items[0].uid = 'uid1';

        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(3, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[2].state);

        quoteController.deleteItemUID = 'uid1';
        quoteController.removeProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[1].state);

        PageReference saveResult = quoteController.saveQuote();
        System.assertEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsNotValid());

        Test.stopTest();
    }

    @IsTest
    static void testEditNewProduct() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        newQuotePage.getParameters().put(RequestParam.ZUORA_ACCOUNT_ID, 'zuoraAccountId');
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeAmendmentQuoteController quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());

        quoteController.wQuote.currentTerm = 12;
        quoteController.wQuote.amendmentType = WrikeQuote.AmendmentType.AMEND_ON_RENEWAL;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getProductsTableStepName(), quoteController.step);
        System.assertEquals(2, quoteController.wQuote.items.size());

        quoteController.editProduct();
        System.assertEquals(null, quoteController.newProduct);

        quoteController.wQuote.items[0].uid = 'uid1';

        quoteController.editItemUID = 'uid1';
        quoteController.editProduct();
        System.assertEquals(null, quoteController.newProduct);

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

        quoteController.recalculateByPrice();
        System.assertEquals(499.8, quoteController.newProduct.effectivePrice);
        System.assertEquals(0.04, quoteController.newProduct.discount);

        quoteController.addNewProduct();

        quoteController.wQuote.items[0].uid = 'uid1';

        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(3, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[2].state);

        quoteController.showNewProductSection();
        System.assertNotEquals(null, quoteController.newProduct);

        quoteController.cancelNewProduct();
        System.assertEquals(null, quoteController.newProduct);

        quoteController.editItemUID = 'uid1';
        quoteController.editProduct();
        System.assertNotEquals(null, quoteController.newProduct);
        System.assertEquals('id1', quoteController.newProduct.zuoraProductId);
        System.assertEquals('productRatePlanId3', quoteController.newProduct.zuoraProductRatePlanId);
        System.assertEquals('productRatePlanChargeId3', quoteController.newProduct.zuoraProductRatePlanChargeId);
        System.assertEquals(5, quoteController.newProduct.quantity);
        System.assertEquals(499.8, quoteController.newProduct.effectivePrice);
        System.assertEquals(8.33, quoteController.newProduct.effectivePricePerUserPerMonth);
        System.assertEquals(0.04, quoteController.newProduct.discount);

        quoteController.newProduct.zuoraProductId = 'id2';
        quoteController.changeProductHandler();
        quoteController.newProduct.zuoraProductRatePlanId = 'productRatePlanId3';
        quoteController.populatePrice();
        quoteController.newProduct.quantity = 10;
        quoteController.changeQuantity();
        System.assertEquals(999.6, quoteController.newProduct.effectivePrice);
        System.assertEquals(8.33, quoteController.newProduct.effectivePricePerUserPerMonth);
        System.assertEquals(0, quoteController.newProduct.discount);

        quoteController.newProduct.effectivePricePerUserPerMonth = 7.5;
        quoteController.recalculateByPrice();
        System.assertEquals(10, quoteController.newProduct.discount);

        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(3, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[2].state);

        PageReference saveResult = quoteController.saveQuote();
        System.assertEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsNotValid());

        Test.stopTest();
    }

    @IsTest
    static void testStep2Validate() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        newQuotePage.getParameters().put(RequestParam.ZUORA_ACCOUNT_ID, 'zuoraAccountId');
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeAmendmentQuoteController quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());

        quoteController.wQuote.amendmentType = WrikeQuote.AmendmentType.START_NEW_BILLING_CYCLE;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.wQuote.name = null;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        List<Integer> numbers = new List<Integer>();
        for (Integer i = 0; i < 80; i++) {
            numbers.add(i);
        }
        quoteController.wQuote.name = String.join(numbers, '');
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.wQuote.name = 'test';
        quoteController.wQuote.effectiveDate = Date.today().addDays(-4);
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.wQuote.effectiveDate = Date.today();
        quoteController.wQuote.validUntil = Date.today().addDays(-1);
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.wQuote.validUntil = Date.today();
        quoteController.wQuote.newTerm = 0;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsNotValid());

//        quoteController.wQuote.newTerm = 12;
//        quoteController.next();
//        System.assert(quoteController.getValidationResult().getIsNotValid());

        quoteController.wQuote.newTerm = 13;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getProductsTableStepName(), quoteController.step);
        System.assertEquals(2, quoteController.wQuote.items.size());

        quoteController.previous();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.next();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[1].state);

        PageReference saveResult = quoteController.saveQuote();
        System.assertEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.goToOpportunity();

        Test.stopTest();
    }

    @IsTest
    static void testValidateNewProduct() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        newQuotePage.getParameters().put(RequestParam.ZUORA_ACCOUNT_ID, 'zuoraAccountId');
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeAmendmentQuoteController quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());

        quoteController.wQuote.currentTerm = 12;
        quoteController.wQuote.amendmentType = WrikeQuote.AmendmentType.AMEND_ON_RENEWAL;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getProductsTableStepName(), quoteController.step);
        System.assertEquals(2, quoteController.wQuote.items.size());

        quoteController.showNewProductSection();
        System.assertEquals(3, quoteController.getProductOptions().size());
        System.assertEquals(1, quoteController.getProductPlanOptions().size());
        quoteController.showNewDeploymentSection();
        System.assertEquals(2, quoteController.getProductOptions().size());
        System.assertEquals(1, quoteController.getProductPlanOptions().size());

        quoteController.newProduct.zuoraProductId = 'id3';
        System.assertEquals(4, quoteController.getProductPlanOptions().size());

        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.newProduct.zuoraProductRatePlanId = 'productRatePlanId3';
        quoteController.populatePrice();
        System.assertEquals(1, quoteController.newProduct.quantity);
        System.assertEquals(500, quoteController.newProduct.billingIntervalListPrice);

        quoteController.newProduct.effectivePrice = -1;
        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.newProduct.effectivePrice = 500;
        quoteController.newProduct.quantity = 101;
        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.newProduct.quantity = 1;
        quoteController.newProduct.discount = 101;
        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        quoteController.newProduct.discount = 10;
        quoteController.recalculateByDiscount();
        System.assertEquals(450, quoteController.newProduct.effectivePrice);

        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(3, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[2].state);

        PageReference saveResult = quoteController.saveQuote();
        System.assertNotEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsValid());

        Test.stopTest();
    }

    @IsTest
    static void testAddNewProductSaveAndEdit() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        newQuotePage.getParameters().put(RequestParam.ZUORA_ACCOUNT_ID, 'zuoraAccountId');
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeAmendmentQuoteController quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());

        quoteController.getAmendmentTypeToControlVisibility();
        List<SelectOption> avalibleAmendmentTypes = quoteController.getAvalibleAmendmentTypes();
        System.assertEquals(4, avalibleAmendmentTypes.size());

        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsNotValid());
        System.assertEquals(quoteController.getAmendmentTypeSelectStepName(), quoteController.step);

        quoteController.wQuote.currentTerm = 12;
        quoteController.wQuote.amendmentType = WrikeQuote.AmendmentType.AMEND_ON_RENEWAL;
        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.next();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getProductsTableStepName(), quoteController.step);
        System.assertEquals(2, quoteController.wQuote.items.size());

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

        quoteController.newProduct.effectivePricePerUserPerMonth = 7.5;
        quoteController.recalculateByPrice();
        System.assertEquals(10, quoteController.newProduct.discount);

        quoteController.newProduct.discount = 20;
        quoteController.recalculateByDiscount();
        System.assertEquals(400.2, quoteController.newProduct.effectivePrice);
        System.assertEquals(6.67, quoteController.newProduct.effectivePricePerUserPerMonth);

        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(3, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[2].state);

        saveResult = quoteController.saveQuote();
        System.assertNotEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assert(String.isNotBlank(quoteController.wQuote.id));

        newQuotePage.getParameters().clear();
        newQuotePage.getParameters().put(RequestParam.QUOTE_ID, quoteController.wQuote.id);
        newQuotePage.getParameters().put(RequestParam.STEP, WrikeQuoteBaseController.PRODUCTS_TABLE_STEP);
        quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getProductsTableStepName(), quoteController.step);

        quoteController.wQuote.items[0].uid = 'uid1';
        quoteController.wQuote.items[1].uid = 'uid2';
        quoteController.wQuote.items[2].uid = 'uid3';

        for (Integer i = 0; i < quoteController.wQuote.items.size(); i++) {
            WrikeQuoteItem item = quoteController.wQuote.items[i];
            if (item.getIsAdded()) {
                quoteController.deleteItemUID = 'uid' + (i + 1);
            }
        }

        quoteController.removeProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[1].state);

        quoteController.deleteItemUID = 'uid3';
        quoteController.restoreProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);

        saveResult = quoteController.saveQuote();
        System.assertEquals(null, saveResult);

        quoteController.deleteItemUID = 'uid2';
        quoteController.removeProduct();
        System.assertEquals(2, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);

        saveResult = quoteController.saveQuote();
        System.assertNotEquals(null, saveResult);

        quoteController.previous();
        Test.stopTest();
    }

    @IsTest
    static void testInvalidInit() {
        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.ID_PARAM, '123');
        Test.setCurrentPage(newQuotePage);

        WrikeAmendmentQuoteController quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsNotValid());

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        quoteController = new WrikeAmendmentQuoteController();
        System.assert(quoteController.getValidationResults().getIsNotValid());
    }

    @IsTest
    static void testEditQuoteDetails() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c amendmentQuote = TestDataFactory.insertDraftSubscriptionQuote(opportunities.get(0).Id);

        PageReference newQuotePage = Page.SubscriptionQuote;
        newQuotePage.getParameters().put(RequestParam.QUOTE_ID, amendmentQuote.Id);
        newQuotePage.getParameters().put(RequestParam.STEP, WrikeQuoteBaseController.QUOTE_DETAILS_STEP);
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        WrikeSubscriptionQuoteController quoteController = new WrikeSubscriptionQuoteController();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(quoteController.getQuoteDetailsStepName(), quoteController.step);

        quoteController.wQuote.newTerm = 1;
        quoteController.changeTermHandler();

        PageReference saveResult = quoteController.saveQuoteDetails();
        System.assertNotEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsValid());

        Test.stopTest();
    }
}
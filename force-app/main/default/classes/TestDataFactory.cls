@IsTest
public class TestDataFactory {

    public static final String TEST_NAME = 'TestDataFactoryName';
    public static final String TEST_EMAIL = 'test@test.com';
    public static final String STAGE_NAME = 'Open';
    public static final Date ClOSE_DATE = Date.today().addDays(1);
    public static final RecordTypeQueryService recordTypeQuerySrv = RecordTypeQueryService.getInstance();

    public static Account createAccount(String name) {
        Account testAccount = new Account();
        testAccount.Name = name;
        testAccount.RecordTypeId = recordTypeQuerySrv.getAccountRecordTypeIdByDevName(RecordTypeQueryService.ACCOUNT_CUSTOMER);
        testAccount.CurrencyIsoCode = 'USD';
        return testAccount;
    }

    public static Account createAccount() {
        return createAccount(TEST_NAME);
    }

    public static Contact createContact(String accountId, String lastname, String email) {
        Contact testContact = new Contact();
        testContact.AccountId = accountId;
        testContact.LastName = lastname;
        testContact.FirstName = TEST_NAME;
        testContact.Email = email;
        testContact.RecordTypeId = recordTypeQuerySrv.getContactRecordTypeIdByDevName(RecordTypeQueryService.CONTACT_CUSTOMER);
        return testContact;
    }

    public static Contact createContact(String accountId) {
        return createContact(accountId, TEST_NAME, TEST_EMAIL);
    }

    public static Contact createContact() {
        return createContact(null);
    }

    public static Opportunity createOpportunity(String accountId, String name, Date closeDate, String stageName,
                                                String billingContactId, Integer wrikeAccountId) {
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.AccountId = accountId;
        testOpportunity.Name = name;
        testOpportunity.CloseDate = closeDate;
        testOpportunity.StageName = stageName;
        testOpportunity.Billing_Contact__c = billingContactId;
        testOpportunity.Wrike_Account_Id__c = wrikeAccountId;
        testOpportunity.CurrencyIsoCode = 'USD';
        testOpportunity.Type = 'New Business';
        return testOpportunity;
    }

    public static Opportunity createOpportunity(String accountId, String billingContactId) {
        return createOpportunity(accountId, TEST_NAME, ClOSE_DATE, STAGE_NAME, billingContactId, null);
    }

    public static Opportunity createOpportunity(String accountId, Integer wrikeAccountId) {
        return createOpportunity(accountId, TEST_NAME, ClOSE_DATE, STAGE_NAME, null, wrikeAccountId);
    }

    public static Opportunity createOpportunity(String accountId, String billingContactId, Integer wrikeAccountId) {
        return createOpportunity(accountId, TEST_NAME, ClOSE_DATE, STAGE_NAME, billingContactId, wrikeAccountId);
    }

    public static OpportunityContactRole createOpportunityContactRole(String contactId, String opportunityId) {
        OpportunityContactRole testOpportunityContactRole = new OpportunityContactRole();
        testOpportunityContactRole.ContactId = contactId;
        testOpportunityContactRole.OpportunityId = opportunityId;
        testOpportunityContactRole.IsPrimary = true;
        return testOpportunityContactRole;
    }

    public static Contract createCPQContract(final Id accountId, final Decimal wrikeAccountId) {
        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
            QS_Account__c =  accountId,
            Wrike_Account_ID__c = wrikeAccountId,
            QS_Bill_To__c = true
        );
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = new QS_Bill_To_Ship_To__c(
            QS_Account__c =  accountId,
            Wrike_Account_ID__c = wrikeAccountId,
            QS_Ship_To__c = true
        );
        insert shipTo;
        final Contract contract = new Contract(
            Wrike_Account_ID__c = wrikeAccountId,
            AccountId = accountId,
            StartDate = Date.today().addDays(1),
            EndDate = Date.today().addMonths(12),
            SBQQ__RenewalTerm__c = 12,
            RecordTypeId = SchemaUtils.getRecordTypeIdByName(Contract.getSObjectType(), 'CPQ Contracts'),
            QS_Bill_To__c = billTo.Id,
            QS_Ship_To__c = shipTo.Id
        );
        return contract;
    }

    public static Id createCPQQuote(final Integer wrikeAccountId, final String quoteType) {
        final Product2 product = new Product2(Name = 'Test Product');
        insert product;
        final Pricebook2 priceBook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
        insert priceBook;
        final PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(priceBook.Id, product.Id, 45);
        insert pricebookEntry;
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = createOpportunity(account.Id, wrikeAccountId);
        opportunity.Pricebook2Id = priceBook.Id;
        insert opportunity;
        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
                QS_Account__c = account.Id,
                Wrike_Account_ID__c = wrikeAccountId,
                QS_Bill_To__c = true
        );
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = new QS_Bill_To_Ship_To__c(
                QS_Account__c = account.Id,
                Wrike_Account_ID__c = wrikeAccountId,
                QS_Ship_To__c = true
        );
        insert shipTo;
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = account.Id,
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__BillingFrequency__c = 'Upfront',
                SBQQ__Status__c = 'Draft',
                QS_Bill_To__c = billTo.Id,
                QS_Ship_To__c = shipTo.Id,
                SBQQ__Primary__c = true,
                SBQQ__LineItemsGrouped__c = true,
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addMonths(12).addDays(-1),
                SBQQ__PriceBook__c = priceBook.Id,
                SBQQ__Type__c = quoteType
        );
        insert quote;
        opportunity.SBQQ__PrimaryQuote__c = quote.Id;
        update opportunity;
        final SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c(
                Name = 'Test Group',
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addMonths(12).addDays(-1),
                SBQQ__Quote__c = quote.Id,
                OneTime__c = false
        );
        insert quoteGroup;
        insert new SBQQ__QuoteLine__c(
                SBQQ__Group__c = quoteGroup.Id,
                SBQQ__ChargeType__c = 'Recurring',
                SBQQ__BillingType__c = 'Advance',
                SBQQ__BillingFrequency__c = 'Upfront',
                SBQQ__SubscriptionType__c = 'Renewable',
                SBQQ__ProductSubscriptionType__c = 'Renewable',
                SBQQ__ListPrice__c = 45,
                SBQQ__NetPrice__c = 45,
                SBQQ__CustomerPrice__c = 45,
                SBQQ__ProratedPrice__c = 45,
                SBQQ__SpecialPrice__c = 45,
                SBQQ__Quantity__c = 5,
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__ProrateMultiplier__c = 12,
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addMonths(12).addDays(-1),
                SBQQ__PricebookEntryId__c = pricebookEntry.Id,
                SBQQ__PricingMethod__c = 'List',
                SBQQ__Bundled__c = false,
                SBQQ__Bundle__c = false
        );
        return quote.Id;
    }

    public static Settings__c createSettings() {
        final Blob wrikeKey = Crypto.generateAesKey(128);
        final Settings__c settings = new Settings__c();
        settings.Wrike_Key__c = EncodingUtil.base64Encode(wrikeKey);
        settings.Wrike_URL__c = 'WrikeUrl';
        settings.ZuoraUrl__c = 'ZuoraUrl';
        settings.ZuoraLogin__c = encrypt(wrikeKey, 'zuora@team.wrike.com');
        settings.ZuoraPassword__c = encrypt(wrikeKey, 'zuorapass123');
        settings.ZuoraPaymentPageId__c = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        settings.PartnerLeadsNotificationEmails__c = 'test@testDoamin.com';
        settings.LicenseSeatsMatchingProducts__c =
                'Wrike Publish,Wrike Resource,Wrike Integrate,Wrike Lock,Advanced Feature Add-on,Wrike Proof,Wrike for Marketers Package';
        settings.Product2QuoteValidator__c = false;
        return settings;
    }

    private static String encrypt(final Blob key, final String data) {
        return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', key, Blob.valueOf(data)));
    }

    public static void insertSettings() {
        Settings__c settings = createSettings();
        TestUtils.insertAndAssert(settings);
    }

    public static SalesSettings__c createSalesSettings() {
        SalesSettings__c salesSettings = new SalesSettings__c();
        salesSettings.SubscriptionStartDateInThePast__c = true;
        salesSettings.Custom_User_License_Tiers__c = false;
        salesSettings.Unlimited_Professional_License__c = false;
        return salesSettings;
    }

    public static void insertSalesSettings() {
        TestUtils.insertAndAssert(createSalesSettings());
    }

    public static ZuoraObject.ZuoraSubscriptionProduct createSubscriptionProduct(Integer productIndex, String serviceType,
            Integer quantity, String chargeType, String billingPeriod, Decimal price) {
        ZuoraObject.ZuoraSubscriptionProduct testSubscriptionProduct = new ZuoraObject.ZuoraSubscriptionProduct();
        testSubscriptionProduct.id = 'id' + productIndex;
        testSubscriptionProduct.name = serviceType;
        testSubscriptionProduct.serviceType = serviceType;
        testSubscriptionProduct.description = serviceType;
        testSubscriptionProduct.quantity = quantity;
        testSubscriptionProduct.ratePlanId = 'ratePlanId' + productIndex;
        testSubscriptionProduct.ratePlanChargeId = 'ratePlanChargeId' + productIndex;
        testSubscriptionProduct.ratePlanChargeName = 'ratePlanChargeName' + productIndex;
        testSubscriptionProduct.productRatePlanId = 'productRatePlanId' + productIndex;
        testSubscriptionProduct.productRatePlanChargeId = 'productRatePlanChargeId' + productIndex;
        testSubscriptionProduct.chargeType = chargeType;
        testSubscriptionProduct.chargeModel = 'Flat Fee Pricing';
        testSubscriptionProduct.mrr = 99;
        testSubscriptionProduct.billingPeriod = billingPeriod;
        testSubscriptionProduct.price = price;
        return testSubscriptionProduct;
    }


    public static List<ZuoraObject.ZuoraRatePlanChargeTier> createProductRatePlanTiers(Integer count, Integer unitRange, Integer initPrice) {
        List<ZuoraObject.ZuoraRatePlanChargeTier> tiers = new List<ZuoraObject.ZuoraRatePlanChargeTier>();
        for (Integer i = 0; i < count; i++) {
            ZuoraObject.ZuoraRatePlanChargeTier tier = new ZuoraObject.ZuoraRatePlanChargeTier();
            tier.tier = i + 1;
            tier.startingUnit = unitRange * i + 1;
            tier.endingUnit = unitRange * (i + 1);
            tier.price = initPrice * tier.endingUnit;
            tiers.add(tier);
        }
        return tiers;
    }

    public static ZuoraProductCatalogService.ProductRatePlanWithCharge createProductRatePlan(Integer index, String billingPeriodName,
            String chargeType, Integer maxQuantity, Integer minQuantity) {
        ZuoraProductCatalogService.ProductRatePlanWithCharge testProductRatePlan = new ZuoraProductCatalogService.ProductRatePlanWithCharge();
        testProductRatePlan.name = billingPeriodName + chargeType;
        testProductRatePlan.description = billingPeriodName;
        testProductRatePlan.productRatePlanId = 'productRatePlanId' + index;
        testProductRatePlan.productRatePlanChargeId = 'productRatePlanChargeId' + index;
        testProductRatePlan.chargeType = chargeType;
        testProductRatePlan.chargeModel = 'Flat Fee Pricing';
        testProductRatePlan.billingPeriodName = billingPeriodName;
        testProductRatePlan.maxQuantity = maxQuantity;
        testProductRatePlan.minQuantity = minQuantity;
        return testProductRatePlan;
    }

    public static ZuoraProductCatalogService.Product createProduct(Integer index, String serviceType) {
        ZuoraProductCatalogService.Product testProduct = new ZuoraProductCatalogService.Product();
        testProduct.id = 'id' + index;
        testProduct.name = serviceType;
        testProduct.description = serviceType;
        testProduct.serviceType = serviceType;
        return testProduct;
    }

    public static ZuoraObject.ZuoraAccount createZuoraAccount(String zuoraAccountId, String accountNumber) {
        ZuoraObject.ZuoraAccount zAccount = new ZuoraObject.ZuoraAccount();
        zAccount.id = zuoraAccountId;
        zAccount.name = 'Test ZuoraAccount';
        zAccount.accountNumber = accountNumber;
        zAccount.status = 'Active';
        zAccount.crmId = 'SF';
        zAccount.currencyCode = 'USD';
        return zAccount;
    }

    public static ZuoraObject.ZuoraSubscription createZuoraSubscription(String zuoraAccountId) {
        ZuoraObject.ZuoraSubscription subscription = new ZuoraObject.ZuoraSubscription();
        subscription.id = 'id';
        subscription.name = 'Test Subscription';
        subscription.accountId = zuoraAccountId;
        subscription.accountName = 'Test ZuoraAccount';
        subscription.status = 'Active';
        subscription.subscriptionStartDate = Date.today();
        subscription.subscriptionEndDate = Date.today();
        subscription.contractEffectiveDate = Date.today();
        subscription.termEndDate = Date.today();
        return subscription;
    }

    public static String insertNewQuoteThroughController() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        PageReference newQuotePage = Page.AmendmentQuote;
        newQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, opportunities[0].Id);
        newQuotePage.getParameters().put(RequestParam.ZUORA_ACCOUNT_ID, 'zuoraAccountId');
        Test.setCurrentPage(newQuotePage);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

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
        quoteController.newProduct.zuoraProductRatePlanId = 'productRatePlanId3';
        quoteController.populatePrice();
        System.assertEquals(5, quoteController.newProduct.quantity);
        System.assertEquals(500, quoteController.newProduct.billingIntervalListPrice);
        quoteController.newProduct.discount = 25;
        quoteController.recalculateByDiscount();
        System.assertEquals(375, quoteController.newProduct.effectivePrice);
        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(3, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.EXISTING, quoteController.wQuote.items[1].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[2].state);

        quoteController.showNewProductSection();
        System.assertEquals(3, quoteController.getProductOptions().size());
        System.assertEquals(1, quoteController.getProductPlanOptions().size());
        quoteController.showNewDeploymentSection();
        System.assertEquals(2, quoteController.getProductOptions().size());
        System.assertEquals(1, quoteController.getProductPlanOptions().size());
        quoteController.newProduct.zuoraProductId = 'id2';
        System.assertEquals(3, quoteController.getProductPlanOptions().size());
        quoteController.changeProductHandler();
        quoteController.newProduct.zuoraProductRatePlanId = 'productRatePlanId3';
        quoteController.newProduct.quantity = 10;
        quoteController.changeQuantity();
        System.assertEquals(1000, quoteController.newProduct.billingIntervalListPrice);
        quoteController.newProduct.discount = 25;
        quoteController.recalculateByDiscount();
        System.assertEquals(750, quoteController.newProduct.effectivePrice);
        quoteController.addNewProduct();
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assertEquals(4, quoteController.wQuote.items.size());
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[0].state);
        System.assertEquals(WrikeQuoteItem.State.ADDED, quoteController.wQuote.items[1].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[2].state);
        System.assertEquals(WrikeQuoteItem.State.REMOVED, quoteController.wQuote.items[3].state);

        PageReference saveResult = quoteController.saveQuote();
        System.assertNotEquals(null, saveResult);
        System.assert(quoteController.getValidationResults().getIsValid());
        System.assert(String.isNotBlank(quoteController.wQuote.id));

        return quoteController.wQuote.id;
    }

    public static Quote__c insertDraftAmendmentQuote(String opportunityId) {
        Quote__c amendemntQuote = createQuote(opportunityId, 12, WrikeQuote.QuoteType.AMENDMENT,
            WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL);
        TestUtils.insertAndAssert(amendemntQuote);

        Quote_Product__c quoteProduct1 = createQuoteProduct(100, 10, 5, 'PremiumSeats', 12, 'Month');
        Quote_Product__c quoteProduct2 = createQuoteProduct(100, 10, 5, 'ProofingAddon', 12, 'Annual');
        Quote_Product__c quoteProduct3 = createQuoteProduct(100, 10, 5, 'PremiumSeats', 12, 'Annual');
        TestUtils.insertAndAssert(new List<Quote_Product__c>{quoteProduct1, quoteProduct2, quoteProduct3});

        Quote_Item__c quoteItem1 = createQuoteItem(amendemntQuote.Id, quoteProduct1.Id, WrikeQuoteItem.State.REMOVED);
        Quote_Item__c quoteItem2 = createQuoteItem(amendemntQuote.Id, quoteProduct2.Id, WrikeQuoteItem.State.EXISTING);
        Quote_Item__c quoteItem3 = createQuoteItem(amendemntQuote.Id, quoteProduct3.Id, WrikeQuoteItem.State.ADDED);
        TestUtils.insertAndAssert(new List<Quote_Item__c>{quoteItem1, quoteItem2, quoteItem3});

        return amendemntQuote;
    }

    public static Quote__c insertDraftSubscriptionQuote(String opportunityId) {
        Quote__c subscriptionQuote = createQuote(opportunityId, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(subscriptionQuote);

        Quote_Product__c quoteProduct1 = createQuoteProduct(100, 10, 5, 'PremiumSeats', 12, 'Annual');
        Quote_Product__c quoteProduct2 = createQuoteProduct(100, 10, 5, 'ProofingAddon', 12, 'Annual');
        TestUtils.insertAndAssert(new List<Quote_Product__c>{quoteProduct1, quoteProduct2});

        Quote_Item__c quoteItem1 = createQuoteItem(subscriptionQuote.Id, quoteProduct1.Id, WrikeQuoteItem.State.ADDED);
        Quote_Item__c quoteItem2 = createQuoteItem(subscriptionQuote.Id, quoteProduct2.Id, WrikeQuoteItem.State.ADDED);
        TestUtils.insertAndAssert(new List<Quote_Item__c>{quoteItem1, quoteItem2});

        return subscriptionQuote;
    }

    public static Quote__c createQuote(String opportunityId, Integer term, WrikeQuote.QuoteType quoteType,
            WrikeQuote.AmendmentType amendmentType) {
        Quote__c testQuote = new  Quote__c();
        testQuote.Name = 'Test Quote';
        testQuote.CompanyName__c = 'Test Company';
        testQuote.Notes__c = 'Test Notes';
        testQuote.Status__c = WrikeQuote.DRAFT;
        testQuote.Opportunity__c = opportunityId;
        testQuote.EffectiveDate__c = Date.today();
        testQuote.ValidUntil__c = Date.today();
        testQuote.InvoiceDate__c = Date.today();
        testQuote.InitialTerm__c = term;
        testQuote.NewTerm__c = term;
        testQuote.RenewalTerm__c = term;
        testQuote.QuoteType__c = quoteType.name();
        if (amendmentType != null) {
            testQuote.AmendmentType__c = amendmentType.name();
            testQuote.SubscriptionStartDate__c = Date.today().addDays(-14);
            testQuote.SubscriptionEndDate__c = Date.today().addDays(14);
        }
        testQuote.WrikeAccountId__c = 100;
        testQuote.Zuora_Account_Id__c = 'zuoraAccountId';
        testQuote.Zuora_Subscription_Id__c = 'zuoraSubscriptionId';
        testQuote.ZuoraAccountName__c = 'Test Zuora Account';
        testQuote.ZuoraSubscriptionName__c = 'Test subscription Name';
        testQuote.TaxExempt__c = false;
        return testQuote;
    }

    public static Quote_Item__c createQuoteItem(String quoteId, String productId, WrikeQuoteItem.State state) {
        Quote_Item__c quoteItem = new Quote_Item__c();
        quoteItem.Quote__c = quoteId;
        quoteItem.State__c = state.name();
        quoteItem.Product__c = productId;
        return quoteItem;
    }

    public static Quote_Product__c createQuoteProduct(Decimal price, Decimal discount, Integer quantity, String serviceType,
                                                      Integer term, String billingPeriodName) {
        Quote_Product__c quoteProduct = new Quote_Product__c();
        quoteProduct.Name = 'Test Name';
        quoteProduct.Description__c = 'Test Description';
        quoteProduct.BillingIntervalListPrice__c = price;
        quoteProduct.Price__c = price - (price * discount / 100);
        quoteProduct.Discount__c = discount;
        quoteProduct.Quantity__c = quantity;
        quoteProduct.ServiceType__c = serviceType;
        quoteProduct.Term__c = term;
        quoteProduct.MRR__c = 99;
        quoteProduct.ZuoraProductId__c = 'ProductId';
        quoteProduct.ZuoraProductRatePlanId__c = 'ProductRatePlanId';
        quoteProduct.ZuoraProductRatePlanChargeId__c = 'ProductRatePlanChargeId';
        quoteProduct.ZuoraProductRatePlanChargeName__c = 'TestZuoraProductRatePlanChargeName';
        quoteProduct.ZuoraRatePlanId__c = 'RatePlanId';
        quoteProduct.ZuoraRatePlanChargeId__c = 'RatePlanChargeId';
        quoteProduct.BillingPeriodName__c = billingPeriodName;
        return quoteProduct;
    }

    public static Lead createLead() {
        return createLead(null);
    }

    public static Lead createLead(String ownerId) {
        return createLead(ownerId, 'test@testdomain.com');
    }

    public static Lead createLead(String ownerId, String email) {
        Lead testLead = new Lead();
        testLead.FirstName = 'Test';
        testLead.LastName = 'Lead';
        testLead.Company = 'Test Company';
        testLead.LeadSource = 'Web';
        testLead.Lead_Sub_Source__c = 'Request';
        testLead.Trial_Type__c = 'Enterprise';
        testLead.Country = 'United States';
        if (ownerId != null) {
            testLead.OwnerId = ownerId;
        }
        testLead.Email = email;
        return testLead;
    }

    public static User createUser(final String email, final Boolean notifyAboutLeads) {
        return createUser(email, 'Testing', 'Testing', 'Standard User', notifyAboutLeads);
    }

    public static User createUser(final String email, final String firstName, final String lastname, final String profileName, final Boolean notifyAboutLeads) {
        return new User(
            Alias = 'standt',
            Email = email,
            EmailEncodingKey = 'UTF-8',
            FirstName = firstName,
            LastName = lastname,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testdatafactory@test.com',
            NotifyAboutNewAssignedLeads__c = notifyAboutLeads
        );
    }

    public static Attachment createAttachment(String parentId) {
        final Attachment pdf = new Attachment();
        pdf.Body = EncodingUtil.base64Decode('Body');
        pdf.ContentType = 'application/pdf';
        pdf.Name = 'Test Name';
        pdf.IsPrivate = false;
        pdf.ParentId = parentId;
        return pdf;
    }

    public static Id createFile(final Id relatedObjectId, final String fileName) {
        final ContentVersion documentVersion = new ContentVersion(
                Title = fileName,
                ContentLocation = 'S',
                PathOnClient = fileName,
                Origin = 'C',
                VersionData = Blob.valueOf('test file')
        );
        insert documentVersion;
        final Id documentId = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id =:documentVersion.Id
        ].ContentDocumentId;
        insert new ContentDocumentLink(
                ContentDocumentId = documentId,
                LinkedEntityId = relatedObjectId,
                ShareType = 'V'
        );
        return documentId;
    }

    public static Task createTask(String whoId, String whatId, String type, String subject, Integer duraton, String direction) {
        return createTask(whoId, whatId, type, subject, duraton, direction, null);
    }

    public static Task createTask(String whoId, String whatId, String type, String subject, Integer duraton, String direction,
                                  String originTaskId) {
        return new Task(
            WhoId = whoId,
            WhatId = whatId,
            Status = 'Open',
            Type = type,
            Subject = subject,
            ActivityDate = Date.today(),
            CallType = direction,
            CallDurationInSeconds = duraton,
            ringdna__Call_Duration__c = duraton,
            Origin_Task_Id__c = originTaskId
        );
    }

    public static InvoiceItem createInvoiceItem(final Date serviceStartDate, final Date serviceEndDate, final Decimal amount) {
        final WrikeQuoteProduct product = new WrikeQuoteProduct();
        product.zuoraProductId = '2c92c0f94b4e2e1b014b56830eb27ea9';
        product.chargeType = ZuoraRestQueryService.RECURRING;
        product.name = 'Enterprise Subscription Licenses';
        final WrikeQuoteItem productItem = new WrikeQuoteItem();
        productItem.product = product;
        productItem.state = amount > 0 ? WrikeQuoteItem.State.ADDED : WrikeQuoteItem.State.REMOVED;
        return new InvoiceItem(
                productItem,
                15,
                serviceStartDate,
                serviceEndDate,
                amount,
                new WrikeQuote());
    }

    public static Messaging.InboundEmail createInboundEmail(String attachmentBody) {
        Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
        textAttachment.fileName = 'lead.csv';
        textAttachment.mimeTypeSubType = 'text/csv';
        textAttachment.body = attachmentBody;

        Messaging.InboundEmail inboxEmail = new Messaging.InboundEmail();
        inboxEmail.htmlBody = '<html></html>';
        inboxEmail.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{textAttachment};
        return inboxEmail;
    }

    public static WrikeData__c createWrikeData(Integer wrikeAccountId, Boolean isAnnual) {
        return createWrikeData(wrikeAccountId, isAnnual, null, null, null, null, null, null);
    }

    public static WrikeData__c createWrikeData(Integer wrikeAccountId, Boolean isAnnual, String countryCode,
                                               String stateCode, String city, String address, String postalCode) {
        return createWrikeData(wrikeAccountId, isAnnual, countryCode, stateCode, city, address, postalCode, null);
    }

    public static WrikeData__c createWrikeData(Integer wrikeAccountId, Boolean isAnnual, String countryCode,
                                               String stateCode, String city, String address, String postalCode, Decimal mrr) {
        return new WrikeData__c(
            Wrike_Account_Id__c = wrikeAccountId,
            Annual__c = isAnnual,
            CountryCode__c = countryCode,
            StateCode__c = stateCode,
            Address__c = address,
            City__c = city,
            PostalCode__c = postalCode,
            MRR__c = mrr,
            Users__c = 5,
            Collaborators__c = 10,
            License_Users__c = 15
        );
    }

    public static Subscription__c createWrikeSubscription(final String accountId, final String wrikeDataId, final String status,
                                                          final Integer wrikeAccountId, final Decimal mrr) {
        return new Subscription__c (
            Account__c = accountId,
            Wrike_Data__c = wrikeDataId,
            Status__c = status,
            Wrike_Account_Id__c = wrikeAccountId,
            MRR__c = mrr
        );
    }

    public static Event__c createSupportEvent(final String accountId, final String opportunityId, final String eventDataId, final String subType) {
        return createSupportEvent(accountId, opportunityId, null, eventDataId, subType);
    }

    public static Event__c createSupportEvent(final String leadId, final String eventDataId, final String subType) {
        return createSupportEvent(null, null, leadId, eventDataId, subType);
    }

    private static Event__c createSupportEvent(final String accountId, final String opportunityId, final String leadId, final String eventDataId, final String subType) {
        return new Event__c(
                Status__c = 'Pending',
                Account__c = accountId,
                Opportunity__c = opportunityId,
                Lead__c = leadId,
                Type__c = 'SupportRequest',
                Sub_Type__c = subType,
                Event_Data__c = eventDataId
        );
    }

    public static dsfs__DocuSign_Status__c createDocuSignStatus(String wrikeQuoteId, String envelopeStatus) {
        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c();
        docuSignStatus.WrikeQuote__c = wrikeQuoteId;
        docuSignStatus.dsfs__Envelope_Status__c = envelopeStatus;
        return docuSignStatus;
    }

    public static CountryData__c createCountryData(final String countryCode, final Decimal countryWeight) {
        return new CountryData__c(
            CountryCode__c = countryCode,
            CountryWeight__c = countryWeight
        );
    }

    public static Deployment__c createDeployment(final String opportunityId, final String accountId, final  String status,
                                                 final Datetime startDate, final Datetime endDate) {
        return new Deployment__c(
            Name = 'Test Deployment',
            Opportunity__c = opportunityId,
            Account__c = accountId,
            Status__c = status,
            Start_Date__c = startDate,
            End_Date__c = endDate
        );
    }

    public static Map<String, ZuoraProductCatalogService.Product> getProductWithRatePlansChargesTiers() {
        Map<String, ZuoraProductCatalogService.Product> productsMap = new Map<String, ZuoraProductCatalogService.Product>();

        ZuoraProductCatalogService.Product product1 = TestDataFactory.createProduct(1, 'PremiumSeats');

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan1_1 =
            TestDataFactory.createProductRatePlan(1, 'Month', 'Recurring', 100, 1);
        productRatePlan1_1.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan1_2 =
            TestDataFactory.createProductRatePlan(2, 'Quarter', 'Recurring', 100, 1);
        productRatePlan1_2.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan1_3 =
            TestDataFactory.createProductRatePlan(3, 'Annual', 'Recurring', 100, 1);
        productRatePlan1_3.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        product1.plans.add(productRatePlan1_1);
        product1.plans.add(productRatePlan1_2);
        product1.plans.add(productRatePlan1_3);
        productsMap.put(product1.id, product1);

        ZuoraProductCatalogService.Product product2 = TestDataFactory.createProduct(2, 'ProofingAddon');

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan2_1 =
            TestDataFactory.createProductRatePlan(1, 'Month', 'Recurring', 100, 1);
        productRatePlan2_1.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan2_2 =
            TestDataFactory.createProductRatePlan(2, 'Quarter', 'Recurring', 100, 1);
        productRatePlan2_2.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan2_3 =
            TestDataFactory.createProductRatePlan(3, 'Annual', 'Recurring', 100, 1);
        productRatePlan2_3.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        product2.plans.add(productRatePlan2_1);
        product2.plans.add(productRatePlan2_2);
        product2.plans.add(productRatePlan2_3);
        productsMap.put(product2.id, product2);

        ZuoraProductCatalogService.Product product3 = TestDataFactory.createProduct(3, 'Implementation');

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan3_1 =
            TestDataFactory.createProductRatePlan(1, null, 'Month', 100, 1);
        productRatePlan3_1.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan3_2 =
            TestDataFactory.createProductRatePlan(2, null, 'Quarter', 100, 1);
        productRatePlan3_2.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan3_3 =
            TestDataFactory.createProductRatePlan(3, null, 'Annual', 100, 1);
        productRatePlan3_3.tiers.addAll(TestDataFactory.createProductRatePlanTiers(20, 5, 100));

        product3.plans.add(productRatePlan3_1);
        product3.plans.add(productRatePlan3_2);
        product3.plans.add(productRatePlan3_3);
        productsMap.put(product3.id, product3);

        return productsMap;
    }

    public static PricebookEntry createPricebookEntry(final Id pricebookId, final Id productId, final Decimal unitPrice) {
        final PricebookEntry standartPricebookEntry = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = productId,
                UnitPrice = 0.5
        );
        insert standartPricebookEntry;
        final PricebookEntry pricebookEntry = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = productId,
                IsActive = true,
                UseStandardPrice = false,
                UnitPrice = unitPrice
        );
        return pricebookEntry;
    }
    
    public static ZuoraAccountBuilder zuoraAccount() {
        return new ZuoraAccountBuilder();
    }
    
    public static ZuoraSubscriptionBuilder zuoraSubscription() {
        return new ZuoraSubscriptionBuilder();
    }

    public static ZuoraFullSubscriptionBuilder fullZuoraSubscription() {
        return new ZuoraFullSubscriptionBuilder();
    }
    
    public class ZuoraAccountBuilder {
        private ZuoraObject.ZuoraAccount account = new ZuoraObject.ZuoraAccount();
        
        private ZuoraAccountBuilder() {
            this.account.id = '2c92c0f85cee0940015d344f57612bd3';
            this.account.name = 'Test Zuora Account';
            this.account.status = 'Active';
            this.account.accountNumber = '1';
			this.account.currencyCode = 'USD';
        }
        
        public ZuoraAccountBuilder setAccountNumber(final String accountNumber) {
            this.account.accountNumber = accountNumber;
            return this;
        }
        
        public ZuoraObject.ZuoraAccount build() {
            return this.account;
        }
    }
    
    public class ZuoraSubscriptionBuilder {
        private ZuoraObject.ZuoraSubscription subscription = new ZuoraObject.ZuoraSubscription();
        
        private ZuoraSubscriptionBuilder() {
            this.subscription.id = '2c92c0f95cee23f4015d3451026d7544';
            this.subscription.subscriptionNumber = 'Test Zuora Subscription';
            this.subscription.accountId = '2c92c0f85cee0940015d344f57612bd3';
            this.subscription.accountName = 'Test Zuora Account';
            this.subscription.status = 'Active';
            this.subscription.subscriptionStartDate = Date.today();
            this.subscription.subscriptionEndDate = Date.today();
            this.subscription.contractEffectiveDate = Date.today();
            this.subscription.termEndDate = Date.today();
        }
        
        public ZuoraObject.ZuoraSubscription build() {
            return this.subscription;
        }
    }

    public class ZuoraFullSubscriptionBuilder {
        private ZuoraObject.ZuoraSubscriptionWithRatePlans subscription = new ZuoraObject.ZuoraSubscriptionWithRatePlans();

        private ZuoraFullSubscriptionBuilder() {
            this.subscription.id = '2c92c0f95cee23f4015d3451026d7544';
            this.subscription.subscriptionNumber = 'Test Zuora Subscription';
            this.subscription.accountId = '2c92c0f85cee0940015d344f57612bd3';
            this.subscription.accountName = 'Test Zuora Account';
            this.subscription.status = 'Active';
            this.subscription.subscriptionStartDate = Date.today();
            this.subscription.subscriptionEndDate = Date.today();
            this.subscription.contractEffectiveDate = Date.today();
            this.subscription.termEndDate = Date.today();
            final ZuoraObject.ZuoraRatePlanChargeWithTiers ratePlanCharge = new ZuoraObject.ZuoraRatePlanChargeWithTiers();
            ratePlanCharge.type = 'Recurring';
            ratePlanCharge.billingPeriod = 'Two Years';
            ratePlanCharge.quantity = 5;
            ratePlanCharge.mrr = 20;
            final ZuoraObject.ZuoraRatePlanWithCharges ratePlan = new ZuoraObject.ZuoraRatePlanWithCharges();
            ratePlan.id = 'ratePlanId';
            ratePlan.productName = 'Product Name';
            ratePlan.ratePlanCharges = new List<ZuoraObject.ZuoraRatePlanChargeWithTiers> { ratePlanCharge };
            this.subscription.ratePlans = new List<ZuoraObject.ZuoraRatePlanWithCharges> { ratePlan };
        }

        public ZuoraObject.ZuoraSubscriptionWithRatePlans build() {
            return this.subscription;
        }
    }

    public static WrikeQuoteZuoraService.SubscriptionPreview generateSubscriptionPreview(final Id quoteId) {
        final Zuora.zObject invoiceData = createSubscriptionInvoiceData(quoteId);
        final WrikeQuote quote = QuoteService.getInstance().findWithItemsById(quoteId);
        return new WrikeQuoteZuoraService.SubscriptionPreviewBuilder(quote)
                .setSuccess(true)
                .addInvoiceData(new List<Zuora.zObject> { invoiceData })
                .addErrors(new List<Zuora.zObject>())
                .addDeltaMrr(202.5)
                .build();
    }

    private static Zuora.zObject createSubscriptionInvoiceData(final Id quoteId) {
        final Quote_Product__c seatProduct = new Quote_Product__c(
                Name = 'Enterprise Subscription Licenses',
                BillingIntervalListPrice__c = 2700,
                Price__c = 2430,
                PricePerUserPerMonth__c = 40.5,
                Discount__c = 10,
                Quantity__c = 5,
                ServiceType__c = 'EnterpriseSeats',
                Term__c = 12,
                ZuoraProductId__c = '2c92c0f94b4e2e1b014b56830eb27ea9',
                ZuoraProductRatePlanId__c = '2c92c0f94cc6ea0f014cd943861a1b2f',
                ZuoraProductRatePlanChargeId__c = '2c92c0f94cc6ea0f014cd9438a891b41',
                ZuoraProductRatePlanChargeName__c = 'Annual billing ($45)',
                BillingPeriodName__c = 'Annual',
                ChargeModel__c = 'Volume Pricing',
                PriceFormat__c = 'Per Unit',
                ChargeType__c = 'Recurring'
        );
        final Quote_Product__c proofingProduct = new Quote_Product__c(
                Name = 'Wrike Proof',
                BillingIntervalListPrice__c = 900,
                Price__c = 900,
                PricePerUserPerMonth__c = 15,
                Discount__c = 0,
                Quantity__c = 5,
                ServiceType__c = 'ProofingAddon',
                Term__c = 12,
                ZuoraProductId__c = '2c92c0f9555cf10501555f48eee836c0',
                ZuoraProductRatePlanId__c = '2c92c0f855768c99015579f3875f0410',
                ZuoraProductRatePlanChargeId__c = '2c92c0f855768cc8015579f7411c392e',
                ZuoraProductRatePlanChargeName__c = 'Annual billing ($45)',
                BillingPeriodName__c = 'Annual',
                ChargeModel__c = 'Volume Pricing',
                PriceFormat__c = 'Per Unit',
                ChargeType__c = 'Recurring'
        );
        final Quote_Product__c deploymentProduct = new Quote_Product__c(
                Name = 'Professional Services - Remote',
                BillingIntervalListPrice__c = 2500,
                Price__c = 2000,
                Discount__c = 20,
                Quantity__c = 0,
                ServiceType__c = 'Implementation',
                Term__c = 12,
                ZuoraProductId__c = '2c92c0f94b4e2e1b014b56830eb27ea9',
                ZuoraProductRatePlanId__c = '2c92c0f94cc6ea0f014cd943861a1b2f',
                ZuoraProductRatePlanChargeId__c = '2c92c0f94cc6ea0f014cd9438a891b41',
                ZuoraProductRatePlanChargeName__c = 'Annual billing ($45)',
                BillingPeriodName__c = 'One-Time',
                ChargeModel__c = 'Flat Fee Pricing',
                PriceFormat__c = 'Flat Fee',
                ChargeType__c = 'OneTime'
        );
        insert new List<Quote_Product__c> {
                seatProduct,
                proofingProduct,
                deploymentProduct
                };
        final Quote_Item__c seatProductItem = TestDataFactory.createQuoteItem(quoteId, seatProduct.Id, WrikeQuoteItem.State.ADDED);
        final Quote_Item__c proofingProductItem = TestDataFactory.createQuoteItem(quoteId, proofingProduct.Id, WrikeQuoteItem.State.ADDED);
        final Quote_Item__c deploymentProductItem = TestDataFactory.createQuoteItem(quoteId, deploymentProduct.Id, WrikeQuoteItem.State.ADDED);
        insert new List<Quote_Item__c> {
                seatProductItem,
                proofingProductItem,
                deploymentProductItem
                };
        final Zuora.zObject invoiceData = new Zuora.zObject('InvoiceData');
        final Date serviceStartDate = Date.today();
        final Date serviceEndDate = Date.today().addYears(1).addDays(-1);
        invoiceData.setValue('Invoice', new Zuora.zObject('Invoice'));
        invoiceData.setValue('InvoiceItem', new List<Zuora.zObject> {
                generateInvoiceItem(serviceStartDate, serviceEndDate, 5, 2430.0, seatProductItem.Id),
                generateInvoiceItem(serviceStartDate, serviceEndDate, 5, 900, proofingProductItem.Id),
                generateInvoiceItem(serviceStartDate, serviceStartDate, 5, 2000.0, deploymentProductItem.Id)
                });
        return invoiceData;
    }

    private static Zuora.zObject generateInvoiceItem(final Date serviceStartDate,
                                                     final Date serviceEndDate,
                                                     final Integer quantity,
                                                     final Decimal chargeAmount,
                                                     final Id quoteItemId) {
        final Zuora.zObject invoiceItem = new Zuora.zObject('InvoiceItem');
        invoiceItem.setValue('ServiceStartDate', String.valueOf(serviceStartDate));
        invoiceItem.setValue('ServiceEndDate', String.valueOf(serviceEndDate));
        invoiceItem.setValue('Quantity', quantity);
        invoiceItem.setValue('ChargeAmount', chargeAmount);
        invoiceItem.setValue('ChargeDescription', quoteItemId);
        return invoiceItem;
    }

    public static QS_Bill_To_Ship_To__c createBillToShipTo(final Id accountId, final Integer wrikeAccountId, final boolean billTo) {
        return new QS_Bill_To_Ship_To__c(
                QS_Attention_To__c = 'Test User',
                QS_Email__c = 'test.user@address.com',
                QS_Account__c = accountId,
                QS_Country_Code__c = 'US',
                QS_State_Code__c = 'CA',
                QS_City__c = 'San Jose',
                QS_Street_1__c = 'N 2nd Street',
                QS_Street_2__c = '70',
                QS_Zip_Postal_Code__c = '95113',
                RegionState__c = 'California',
                Wrike_Account_ID__c = wrikeAccountId,
                QS_Bill_To__c = billTo,
                QS_Ship_To__c = !billTo
        );
    }
}
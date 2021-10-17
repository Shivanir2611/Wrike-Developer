@IsTest
public class CPQQuoteControllerTest {

    @IsTest
    static void testActivateQuote() {
        insert new Product2(
                Name = 'Wrike Analyze Standard',
                ProductCode = CPQProductService.WrikeAnalyzeStandard
        );
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = 'Draft',
                ApprovalRequired__c = false
        );
        insert quote;

        final Product2 product = new Product2(Name = 'Test Product');
        insert product;

        insert new SBQQ__QuoteLine__c(
                SBQQ__StartDate__c = Date.newInstance(2020, 1, 31),
                SBQQ__EndDate__c = Date.newInstance(2021, 1, 30),
                SBQQ__SubscriptionType__c = 'Renewable',
                SBQQ__ProductSubscriptionType__c = 'Renewable',
                SBQQ__NetPrice__c = 500,
                SBQQ__Quantity__c = 1,
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id
        );

        CPQQuoteController.activateQuote(quote.Id);

        final SBQQ__Quote__c updatedQuote = findQuoteById(quote.Id);
        System.assertEquals('Approved', updatedQuote.SBQQ__Status__c);
    }

    @IsTest
    static void testMakePrimary() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;

        final SBQQ__Quote__c primaryQuote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__Primary__c = true
        );
        insert primaryQuote;

        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__BillingFrequency__c = 'Quarterly',
                SBQQ__Status__c = 'Draft'
        );
        insert quote;
        quote.WrikeAccountId__c = 321;
        update quote;

        CPQQuoteController.makeQuotePrimary(quote.Id);

        final SBQQ__Quote__c updatedQuote = findQuoteById(quote.Id);
        System.assertEquals(true, updatedQuote.SBQQ__Primary__c);
        final SBQQ__Quote__c prevPrimaryQuote = findQuoteById(primaryQuote.Id);
        System.assertEquals(false, prevPrimaryQuote.SBQQ__Primary__c);
        final Opportunity updatedOpportunity = findOpportunityById(opportunity.Id);
        System.assertEquals(321, updatedOpportunity.Wrike_Account_Id__c);
    }

    @IsTest
    static void testChangeQuoteStatusToDraft() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = 'Approved'
        );
        insert quote;

        CPQQuoteController.changeQuoteStatusToDraft(quote.Id);

        final SBQQ__Quote__c updatedQuote = findQuoteById(quote.Id);
        System.assertEquals('Draft', updatedQuote.SBQQ__Status__c);
    }

    @IsTest
    static void testGetPartnerUpdateAllowed() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Account partnerAccount = new Account(
                Name = 'Test Partner Account',
                CurrencyIsoCode = 'USD',
                RecordTypeId = SchemaUtils.getRecordTypeIdByName(Account.getSObjectType(), 'Partner')
        );
        insert partnerAccount;
        final Opportunity opportunity = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = account.Id,
                StageName = '0-MQL',
                CloseDate = Date.today().addDays(30)
        );
        insert opportunity;
        final Partner__c partner = new Partner__c(
                Opportunity__c = opportunity.Id,
                Partner__c = partnerAccount.Id,
                Engagement_Level__c = 'Reseller'
        );
        insert partner;
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = 'Draft',
                SBQQ__Opportunity2__c = opportunity.Id
        );
        insert quote;
        System.assert(CPQQuoteController.getPartnerUpdateAllowed(quote.Id));
    }

    @IsTest
    static void testGetPreviewUrl() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;

        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__BillingFrequency__c = 'Quarterly',
                SBQQ__Status__c = 'Draft',
                SBQQ__Primary__c = true
        );
        insert quote;

        final Product2 product = new Product2(Name = 'Test Product');
        insert product;

        insert new SBQQ__QuoteLine__c(
                SBQQ__StartDate__c = Date.newInstance(2020, 1, 31),
                SBQQ__EndDate__c = Date.newInstance(2021, 1, 30),
                SBQQ__SubscriptionType__c = 'Renewable',
                SBQQ__ProductSubscriptionType__c = 'Renewable',
                SBQQ__NetPrice__c = 500,
                SBQQ__Quantity__c = 1,
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id
        );

        update new SBQQ__Quote__c(
            Id = quote.Id,
            SBQQ__Status__c = 'Approved'
        );

        System.assertEquals('/apex/documentpreview?quoteId=' + quote.Id, CPQQuoteController.getPreviewUrl(quote.Id));
    }

    @IsTest
    static void testDeleteQuoteDocument() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = 'DocumentGenerated'
        );
        insert quote;

        final SBQQ__QuoteDocument__c document = new SBQQ__QuoteDocument__c(SBQQ__Quote__c = quote.Id);
        insert document;

        CPQQuoteController.deleteQuoteDocument(quote.Id);

        final SBQQ__Quote__c updatedQuote = findQuoteById(quote.Id);
        System.assertEquals('Approved', updatedQuote.SBQQ__Status__c);
        System.assertEquals(null, updatedQuote.Document__c);

        System.assertEquals(null, findDocumentById(document.Id));
    }

    @IsTest
    static void testGetDocuSignUrl() {
        insert new CPQSettings__c(DocuSignWrikeRecipientEmail__c = 'wrike.recipient@test.email');
        final Account account = TestDataFactory.createAccount();
        insert account;
        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
                QS_Bill_To__c = true,
                QS_Account__c = account.Id,
                QS_Email__c = 'customer.recipient@test.email'
        );
        insert billTo;
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = account.Id,
                QS_Bill_To__c = billTo.Id,
                SBQQ__Status__c = 'DocumentGenerated',
                PreSignDocument__c = false,
                SBQQ__ExpirationDate__c = DateUtils.getPacificLocalDate().addDays(7)
        );
        insert quote;

        final String docuSignUrl = EncodingUtil.urlDecode(CPQQuoteController.getDocuSignUrl(quote.Id), 'UTF-8');
        System.assert(docuSignUrl.contains('Email~customer.recipient@test.email;'));
        System.assert(docuSignUrl.contains('Email~wrike.recipient@test.email;'));
        System.assert(docuSignUrl.contains('Email~' + UserInfo.getUserEmail()));
    }

    @IsTest
    static void testCancelDocuSignEnvelope() {
        DocuSignRestApiService docuSignRestApiSrvMock = (DocuSignRestApiService)MockApi.mock(DocuSignRestApiService.class);
        MockApi.setup()
                .mock(docuSignRestApiSrvMock.getEnvelopeStatus(null), 'sent')
                .mock(docuSignRestApiSrvMock.voidEnvelope(null), true)
                .build();
        final SBQQ__Quote__c record = new SBQQ__Quote__c(
                SBQQ__Status__c = 'DocuSignSent'
        );
        insert record;

        final CPQQuote quote = CPQQuoteController.cancelDocuSignEnvelope(record.Id);
        System.assert(quote.getIsDocumentGenerated());
    }

    @IsTest
    static void testCancelDocuSignCompletedEnvelope() {
        DocuSignRestApiService docuSignRestApiSrvMock = (DocuSignRestApiService)MockApi.mock(DocuSignRestApiService.class);
        MockApi.setup()
                .mock(docuSignRestApiSrvMock.getEnvelopeStatus(null), 'completed')
                .build();
        final SBQQ__Quote__c record = new SBQQ__Quote__c(
                SBQQ__Status__c = 'DocuSignSent'
        );
        insert record;

        final CPQQuote quote = CPQQuoteController.cancelDocuSignEnvelope(record.Id);
        System.assert(quote.getIsDocuSignSigned());
    }

    @IsTest
    static void testGetExistingPrimaryQuoteId() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;

        final SBQQ__Quote__c primaryQuote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__Primary__c = true
        );
        insert primaryQuote;

        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opportunity.Id
        );
        insert quote;

        System.assertEquals(primaryQuote.Id, CPQQuoteController.getExistingPrimaryQuoteId(quote.Id));
    }

    private static SBQQ__Quote__c findQuoteById(Final Id id) {
        return [
                SELECT Id, SBQQ__Status__c, SBQQ__Primary__c, SBQQ__StartDate__c, Document__c
                FROM SBQQ__Quote__c
                WHERE Id = :id
        ];
    }

    private static SBQQ__QuoteDocument__c findDocumentById(Final Id id) {
        final List<SBQQ__QuoteDocument__c> documents = [
                SELECT Id
                FROM SBQQ__QuoteDocument__c
                WHERE Id = :id
        ];
        return documents.isEmpty() ? null : documents.get(0);
    }

    private static Opportunity findOpportunityById(Final Id id) {
        return [
                SELECT Id, Wrike_Account_Id__c
                FROM Opportunity
                WHERE Id = :id
        ];
    }
}
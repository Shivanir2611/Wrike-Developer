@IsTest
public class CPQRestRenewalServiceTest {

    @TestSetup
    static void setup() {
        final Product2 enterpriseSeatsProduct = new Product2(
                Name = 'Enterprise Licenses',
                ZuoraServiceType__c = 'EnterpriseSeats',
                ProductCode = 'r-lic-base-Ent',
                CurrencyIsoCode = 'USD'
        );
        insert enterpriseSeatsProduct;
        final Pricebook2 pricebook = new Pricebook2(
                Name = 'Test Price Book',
                IsActive = true,
                CurrencyIsoCode = 'USD'
        );
        insert pricebook;
        TestUtils.createPricebookEntry(enterpriseSeatsProduct.Id, pricebook.Id, 45.0);
        insert new Settings__c(
                ProfessionalServicesPackageId__c = enterpriseSeatsProduct.Id,
                StandardPriceBookId__c = pricebook.Id
        );
        insert new CPQSettings__c(
            PriceBookName__c = pricebook.Name
        );
    }

    @IsTest
    static void testGetHandlerMap() {
        final Map<String, RestHandlerService.RestHandler> handlerMap =  new CPQRestRenewalService().getHandlerMap();
        System.assertEquals(true, handlerMap.get('quote') instanceof CPQRestRenewalService.RenewalQuoteHandler);
        System.assertEquals(true, handlerMap.get('update') instanceof CPQRestRenewalService.UpdateRenewalQuoteHandler);
        System.assertEquals(true, handlerMap.get('order') instanceof CPQRestRenewalService.OrderRenewalQuoteHandler);
    }

    @IsTest
    static void testRenewalQuoteHandler() {
        final CPQRestRenewalService.RenewQuoteRequest requestData = new CPQRestRenewalService.RenewQuoteRequest();
        requestData.wrikeAccountId = 12345;
        requestData.userName = 'Operation User';
        requestData.userEmail = 'operation.user@address.com';
        final CPQRestRenewalService.RenewalQuoteHandler handler = new CPQRestRenewalService.RenewalQuoteHandler();
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(12345, account.Id);
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = contract.SBQQ__RenewalOpportunity__c,
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft',
                CurrencyIsoCode = 'USD'
        );
        insert quote;
        final CPQQuoteCreationService quoteCreationServiceMock = (CPQQuoteCreationService)MockApi.mock(CPQQuoteCreationService.class);
        MockApi.setup().mockStrict(
                quoteCreationServiceMock.createSelfRenewalQuote(
                    contract.Id,
                    requestData.userName,
                    requestData.userEmail
                ),
                quote.Id
        ).build();
        Test.startTest();
        final RestHandlerService.RestResponseData responseData = handler.processRequest(requestData);
        System.assertEquals(true, responseData.getSuccess());
        System.assertEquals(quote.Id, ((Map<String, String>)responseData.getData()).get('quoteId'));
        Test.stopTest();
    }

    @IsTest
    static void testUpdateQuoteHandler() {
        final CPQRestRenewalService.UpdateRenewalQuoteHandler handler = new CPQRestRenewalService.UpdateRenewalQuoteHandler();
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(12345, account.Id);
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = contract.SBQQ__RenewalOpportunity__c,
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft',
                CurrencyIsoCode = 'USD',
                SBQQ__LineItemsGrouped__c = true,
                SBQQ__StartDate__c = contract.EndDate.addDays(1),
                SBQQ__EndDate__c = contract.EndDate.addMonths(12)
        );
        insert quote;
        insert new SBQQ__QuoteLineGroup__c(
                Name = 'Test Group',
                SBQQ__StartDate__c = quote.SBQQ__StartDate__c,
                SBQQ__EndDate__c = quote.SBQQ__EndDate__c,
                SBQQ__Quote__c = quote.Id,
                OneTime__c = false
        );
        final CPQRestRenewalService.UpdateRenewalQuoteRequest requestData = new CPQRestRenewalService.UpdateRenewalQuoteRequest();
        requestData.quoteId = quote.Id;
        requestData.newPlan = 'EnterpriseSeats';
        requestData.newSeatsQuantity = 25;
        requestData.newPrice = 45.0;
        Test.startTest();
        final RestHandlerService.RestResponseData responseData = handler.processRequest(requestData);
        System.assertEquals(true, responseData.getSuccess());
        System.assertEquals(quote.Id, ((Map<String, String>)responseData.getData()).get('quoteId'));
        Test.stopTest();
    }

    @IsTest
    static void testOrderRenewalQuoteHandler() {
        final Id productId = [
                    SELECT Id
                    FROM Product2
                    WHERE ZuoraServiceType__c = 'EnterpriseSeats'
        ].Id;
        final CPQRestRenewalService.OrderRenewalQuoteHandler handler = new CPQRestRenewalService.OrderRenewalQuoteHandler();
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(12345, account.Id);
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = contract.SBQQ__RenewalOpportunity__c,
                SBQQ__Primary__c = true,
                SBQQ__Type__c = 'Renewal',
                SBQQ__Status__c = 'Draft',
                CurrencyIsoCode = 'USD',
                SBQQ__LineItemsGrouped__c = true,
                SBQQ__StartDate__c = contract.EndDate.addDays(1),
                SBQQ__EndDate__c = contract.EndDate.addMonths(12),
                QS_Bill_To__c = contract.QS_Bill_To__c,
                QS_Ship_To__c = contract.QS_Ship_To__c
        );
        insert quote;
        final SBQQ__QuoteLineGroup__c lineGroup = new SBQQ__QuoteLineGroup__c(
                Name = 'Test Group',
                SBQQ__StartDate__c = quote.SBQQ__StartDate__c,
                SBQQ__EndDate__c = quote.SBQQ__EndDate__c,
                SBQQ__Quote__c = quote.Id,
                OneTime__c = false
        );
        insert lineGroup;
        insert new SBQQ__QuoteLine__c(
                SBQQ__SubscriptionType__c = 'Renewable',
                SBQQ__ProductSubscriptionType__c = 'Renewable',
                SBQQ__NetPrice__c = 1125,
                SBQQ__Quantity__c = 25,
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = productId,
                SBQQ__Group__c = lineGroup.Id
        );
        final CPQRestRenewalService.OrderRenewalQuoteRequest requestData = new CPQRestRenewalService.OrderRenewalQuoteRequest();
        requestData.quoteId = quote.Id;
        Test.startTest();
        final RestHandlerService.RestResponseData responseData = handler.processRequest(requestData);
        System.assertEquals(true, responseData.getSuccess());
        final Id orderId = [
                SELECT Id
                FROM Order
                WHERE SBQQ__Quote__c = :quote.Id
        ]?.Id;
        System.assertEquals(orderId, ((Map<String, String>)responseData.getData()).get('orderId'));
        Test.stopTest();
    }

    private static Contract createContract(final Integer wrikeAccountId, final Id accountId) {
        final Opportunity renewalOpportunity = TestDataFactory.createOpportunity(accountId, wrikeAccountId);
        renewalOpportunity.Type = 'Renewal';
        insert renewalOpportunity;
        final Contract contract = TestDataFactory.createCPQContract(accountId, wrikeAccountId);
        contract.Auto_Renew__c = 'Yes';
        contract.SBQQ__RenewalOpportunity__c = renewalOpportunity.Id;
        contract.StartDate = Date.today().toStartOfMonth();
        contract.EndDate = Date.today().toStartOfMonth().addMonths(12).addDays(-1);
        insert contract;
        contract.Status = 'Activated';
        update contract;
        return contract;
    }

}
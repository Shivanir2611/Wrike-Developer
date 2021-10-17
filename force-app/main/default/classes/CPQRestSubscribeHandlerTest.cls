@IsTest
public class CPQRestSubscribeHandlerTest {

    @IsTest
    static void testQuoteCreated() {
        final CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest request = createValidQuoteRequest(123);
        final RestHandlerService.RestResponseData response = processRequest(request);
        System.assertEquals(true, response.getSuccess());
        final Map<String, Object> responseData = (Map<String, Object>)response.getData();
        final Id quoteId = (String)responseData.get('quoteId');
        final Id accountId = (String)responseData.get('accountId');
        final Id opportunityId = (String)responseData.get('opportunityId');
        System.assertNotEquals(null, quoteId);
        System.assertNotEquals(null, accountId);
        System.assertNotEquals(null, opportunityId);
        final SBQQ__Quote__c quote = [
                SELECT SBQQ__Account__r.Name, SBQQ__Opportunity2__c, WrikeAccountId__c, eCommerce__c, ApprovalRequired__c,
                        RemoveSignatureBlock__c, BypassValidationRules__c, SBQQ__LineItemsGrouped__c, SBQQ__Primary__c,
                        SBQQ__RenewalTerm__c, SBQQ__SalesRep__c, SBQQ__Status__c,
                        QS_Bill_To__r.QS_Attention_To__c, QS_Bill_To__r.QS_Bill_To__c, QS_Bill_To__r.Wrike_Account_ID__c,
                        QS_Ship_To__r.QS_Attention_To__c, QS_Ship_To__r.QS_Bill_To__c, QS_Ship_To__r.Wrike_Account_ID__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
        System.assertEquals(accountId, quote.SBQQ__Account__r.Id, accountId);
        System.assertEquals(request.wrikeAccountName, quote.SBQQ__Account__r.Name);
        System.assertEquals(opportunityId, quote.SBQQ__Opportunity2__c);
        System.assertEquals(request.wrikeAccountId, quote.WrikeAccountId__c);
        System.assertEquals(true, quote.eCommerce__c);
        System.assertEquals(false, quote.ApprovalRequired__c);
        System.assertEquals(true, quote.RemoveSignatureBlock__c);
        System.assertEquals(true, quote.BypassValidationRules__c);
        System.assertEquals(true, quote.SBQQ__LineItemsGrouped__c);
        System.assertEquals(true, quote.SBQQ__Primary__c);
        System.assertEquals(12, quote.SBQQ__RenewalTerm__c);
        System.assertEquals(WrikeConstants.SF_ADMIN_ID, quote.SBQQ__SalesRep__c);
        System.assertEquals('Draft', quote.SBQQ__Status__c);
        System.assertEquals(request.billTo.userName, quote.QS_Bill_To__r.QS_Attention_To__c);
        System.assertEquals(true, quote.QS_Bill_To__r.QS_Bill_To__c);
        System.assertEquals(request.wrikeAccountId, quote.QS_Bill_To__r.Wrike_Account_ID__c);
        System.assertEquals(request.shipTo.userName, quote.QS_Ship_To__r.QS_Attention_To__c);
        System.assertEquals(false, quote.QS_Ship_To__r.QS_Bill_To__c);
        System.assertEquals(request.wrikeAccountId, quote.QS_Ship_To__r.Wrike_Account_ID__c);
        final List<SBQQ__QuoteLineGroup__c> lineGroups = [
                SELECT SBQQ__StartDate__c , SBQQ__EndDate__c
                FROM SBQQ__QuoteLineGroup__c
                WHERE SBQQ__Quote__c = :quoteId
        ];
        System.assertEquals(request.quoteStartDate, lineGroups[0].SBQQ__StartDate__c);
        System.assertEquals(request.quoteEndDate, lineGroups[0].SBQQ__EndDate__c);

    }

    @IsTest
    static void testInvalidWrikeAccountId() {
        final CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest quoteRequest = new CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest();
        quoteRequest.wrikeAccountId = 0;
        final RestHandlerService.RestResponseData response = processRequest(quoteRequest);
        System.assertEquals(false, response.getSuccess());
        System.assert(response.getError().containsIgnoreCase('Invalid Wrike Account Id'));
    }

    @IsTest
    static void testInvalidWrikeAccountName() {
        final CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest quoteRequest = new CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest();
        quoteRequest.wrikeAccountId = 123;
        final RestHandlerService.RestResponseData response = processRequest(quoteRequest);
        System.assertEquals(false, response.getSuccess());
        System.assert(response.getError().containsIgnoreCase('Invalid Wrike Account Name'));
    }

    @IsTest
    static void testInvalidDates() {
        final CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest quoteRequest = new CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest();
        quoteRequest.wrikeAccountId = 123;
        quoteRequest.wrikeAccountName = 'Test Account';
        quoteRequest.quoteStartDate = Date.today();
        quoteRequest.quoteEndDate = Date.today().addDays(-1);
        final RestHandlerService.RestResponseData response = processRequest(quoteRequest);
        System.assertEquals(false, response.getSuccess());
        System.assert(response.getError().containsIgnoreCase('Invalid quote dates'));
    }

    @IsTest
    static void testInvalidRenewalTerm() {
        final CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest quoteRequest = new CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest();
        quoteRequest.wrikeAccountId = 123;
        quoteRequest.wrikeAccountName = 'Test Account';
        quoteRequest.quoteStartDate = Date.today();
        quoteRequest.quoteEndDate = Date.today().addMonths(12).addDays(-1);
        quoteRequest.renewalTerm = 6;
        final RestHandlerService.RestResponseData response = processRequest(quoteRequest);
        System.assertEquals(false, response.getSuccess());
        System.assert(response.getError().containsIgnoreCase('Invalid renewal term'));
    }

    @IsTest
    static void testNoBillToShipTo() {
        final CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest quoteRequest = new CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest();
        quoteRequest.wrikeAccountId = 123;
        quoteRequest.wrikeAccountName = 'Test Account';
        quoteRequest.quoteStartDate = Date.today();
        quoteRequest.quoteEndDate = Date.today().addMonths(12).addDays(-1);
        quoteRequest.renewalTerm = 12;
        final RestHandlerService.RestResponseData response = processRequest(quoteRequest);
        System.assertEquals(false, response.getSuccess());
        System.assert(response.getError().containsIgnoreCase('No Bill To/Ship To data'));
    }

    @IsTest
    static void testExistingContract() {
        final Decimal wrikeAccountId = 123;
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = TestDataFactory.createCPQContract(account.Id, wrikeAccountId);
        contract.StartDate = Date.today();
        contract.EndDate = Date.today().addMonths(12).addDays(-1);
        insert contract;
        contract.Status = 'Activated';
        update contract;
        final RestHandlerService.RestResponseData response = processRequest(createValidQuoteRequest(wrikeAccountId));
        System.assertEquals(false, response.getSuccess());
        System.assert(response.getError().containsIgnoreCase('Existing Contract'));
    }

    private static CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest createValidQuoteRequest(final Decimal wrikeAccountId) {
        final CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest quoteRequest = new CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest();
        quoteRequest.wrikeAccountId = 123;
        quoteRequest.wrikeAccountName = 'Test Account';
        quoteRequest.quoteStartDate = Date.today();
        quoteRequest.quoteEndDate = Date.today().addMonths(12).addDays(-1);
        quoteRequest.renewalTerm = 12;
        quoteRequest.billTo = TestUtils.defaultBillToShipTo();
        quoteRequest.shipTo = TestUtils.defaultBillToShipTo();
        return quoteRequest;
    }

    private static RestHandlerService.RestResponseData processRequest(final CPQRestSubscribeHandler.CPQSubscriptionQuoteRequest quoteRequest) {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri ='/services/apexrest/cpq/subscription/quote';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(quoteRequest));
        RestContext.response = new RestResponse();
        CPQRestService.processRequest();
        final Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        return new RestHandlerService.RestResponseData(
                (Boolean)responseData.get('success'),
                (String)responseData.get('error'),
                responseData.get('data')
        );
    }
}
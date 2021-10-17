public class CPQRestSubscribeHandler implements RestHandlerService.RestHandler {

    public Type getRequestType() {
        return CPQSubscriptionQuoteRequest.class;
    }

    public RestHandlerService.RestResponseData processRequest(final Object requestData) {
        final CPQSubscriptionQuoteRequest request = (CPQSubscriptionQuoteRequest)requestData;
        if (!(request.wrikeAccountId > 0)) {
            return RestHandlerService.failed('Invalid Wrike Account Id.');
        }
        if (String.isBlank(request.wrikeAccountName)) {
            return RestHandlerService.failed('Invalid Wrike Account Name.');
        }
        if (request.quoteStartDate == null
                || request.quoteEndDate == null
                || request.quoteStartDate > request.quoteEndDate) {
            return RestHandlerService.failed('Invalid quote dates.');
        }
        if (request.renewalTerm != 1 && request.renewalTerm != 12) {
            return RestHandlerService.failed('Invalid renewal term: ' + request.renewalTerm);
        }
        if (request.billTo == null || request.shipTo == null) {
            return RestHandlerService.failed('No Bill To/Ship To data.');
        }
        final List<Contract> existingContracts = [
                SELECT Id
                FROM Contract
                WHERE Status = 'Activated'
                AND Wrike_Account_ID__c = :request.wrikeAccountId
        ];
        if (!existingContracts.isEmpty()) {
            return RestHandlerService.failed('Existing Contract: ' + existingContracts[0].Id);
        }
        final CPQRestQuoteService restQuoteService = CPQRestQuoteService.getInstance();
        final Id accountId = restQuoteService.findOrCreateAccountByWrikeAccountId(
                request.wrikeAccountId,
                request.wrikeAccountName
        );
        final Opportunity opp = new Opportunity(
                Name = 'eCommerce Self Service Checkout',
                OwnerId = WrikeConstants.SF_ADMIN_ID,
                CloseDate = Date.today().addDays(1),
                StageName = '0-MQL',
                AccountId = accountId,
                Wrike_Account_Id__c = request.wrikeAccountId,
                CurrencyIsoCode = 'USD',
                Type = 'New Business'
        );
        final RecordTypeInfo fastTrackType = Schema.Opportunity.getSObjectType()
                .getDescribe()
                .getRecordTypeInfosByName()
                .get('Fast Track');
        if (fastTrackType != null) {
            opp.RecordTypeId = fastTrackType.getRecordTypeId();
        }
        insert opp;
        final SBQQ__Quote__c quote = createNewQuote(accountId, opp, request.wrikeAccountId, request);
        insert quote;
        insert new SBQQ__QuoteLineGroup__c(
                Name = 'Group 1',
                SBQQ__Number__c = 1,
                SBQQ__Quote__c = quote.Id,
                SBQQ__StartDate__c = request.quoteStartDate,
                SBQQ__EndDate__c = request.quoteEndDate
        );
        return RestHandlerService.success(new Map<String, String> {
            'accountId' => accountId,
            'opportunityId' => opp.Id,
            'quoteId' => quote.Id
        });
    }

    private SBQQ__Quote__c createNewQuote(final Id accountId,
                                        final Opportunity opportunity,
                                        final Decimal wrikeAccountId,
                                        final CPQSubscriptionQuoteRequest request) {
        final CPQRestQuoteService restQuoteService = CPQRestQuoteService.getInstance();
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = accountId,
                SBQQ__Opportunity2__c = opportunity.Id,
                CurrencyIsoCode = opportunity.CurrencyIsoCode,
                WrikeAccountId__c = wrikeAccountId,
                eCommerce__c = true,
                ApprovalRequired__c = false,
                RemoveSignatureBlock__c = true,
                BypassValidationRules__c = true,
                SBQQ__LineItemsGrouped__c = true,
                SBQQ__Primary__c = true,
                SBQQ__RenewalTerm__c = request.renewalTerm,
                SBQQ__SalesRep__c = WrikeConstants.SF_ADMIN_ID,
                SBQQ__Status__c = 'Draft'
        );
        quote.QS_Bill_To__c = restQuoteService.createBillToShipTo(request.billTo, accountId, wrikeAccountId, true);
        quote.QS_Ship_To__c = restQuoteService.createBillToShipTo(request.shipTo, accountId, wrikeAccountId, false);
        final List<QS_Bill_To_Ship_To__c> contacts = [
                SELECT Id, QS_Bill_To__c, QS_Ship_To__c
                FROM QS_Bill_To_Ship_To__c
                WHERE QS_Account__c = :quote.SBQQ__Account__c
                AND Wrike_Account_ID__c = :quote.WrikeAccountId__c
                ORDER BY CreatedDate
        ];
        for (QS_Bill_To_Ship_To__c contact : contacts) {
            if (contact.QS_Bill_To__c) {
                quote.QS_Bill_To__c = contact.Id;
            } else if (contact.QS_Ship_To__c) {
                quote.QS_Ship_To__c = contact.Id;
            }
        }
        return quote;
    }

    @TestVisible
    private class CPQSubscriptionQuoteRequest {
        public Integer wrikeAccountId { get; set; }
        public String wrikeAccountName { get; set; }
        public Date quoteStartDate { get; set; }
        public Date quoteEndDate { get; set; }
        public Integer renewalTerm { get; set; }
        public CPQRestService.CPQRestBillToShipTo billTo { get; set; }
        public CPQRestService.CPQRestBillToShipTo shipTo { get; set; }
    }
}
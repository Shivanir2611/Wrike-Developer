public class CPQMyApprovalsTableController {

    private final static CPQApprovalService approvalSrv = CPQApprovalService.getInstance();
    private final static CPQQuoteQueryService quoteQuerySrv = CPQQuoteQueryService.getInstance();

    @AuraEnabled
    public static List<MyApproval> findMyApprovals() {
        final List<CPQApproval> approvals = approvalSrv.findUserApprovals(UserInfo.getUserId());
        final Set<Id> quoteIds = new Set<Id>();
        for (CPQApproval approval : approvals) {
            quoteIds.add(approval.quoteId);
        }
        final List<MyApproval> myApprovals = new List<MyApproval>();
        final List<SBQQ__Quote__c> quotes = quoteQuerySrv.findQuotesApprovalInfoByIds(quoteIds);
        for (SBQQ__Quote__c quote : quotes) {
            myApprovals.add(new MyApproval(
                    quote.Id,
                    quote.Name,
                    quote.SBQQ__SalesRep__r.Name,
                    quote.Delta_MRR__c,
                    quote.SBQQ__Status__c,
                    quote.Total_Order_Value__c,
                    quote.SBQQ__Opportunity2__r.Id,
                    quote.SBQQ__Opportunity2__r.Name,
                    quote.CurrencyIsoCode
            ));
        }
        return myApprovals;
    }

    @AuraEnabled
    public static Id getRequestedApprovalId(final Id quoteId) {
        final Id userId = UserInfo.getUserId();
        approvalSrv.prepareApprovalsBeforeDecision(quoteId, userId);
        return approvalSrv.findFirstRequestedApprovalId(quoteId, userId);
    }

    public class MyApproval {
        @AuraEnabled
        public Id quoteId {get; set;}
        @AuraEnabled
        public String quoteName {get; set;}
        @AuraEnabled
        public String quoteOwner {get; set;}
        @AuraEnabled
        public Decimal quoteMRR {get; set;}
        @AuraEnabled
        public String quoteStatus {get; set;}
        @AuraEnabled
        public Decimal quoteTotalAmount {get; set;}
        @AuraEnabled
        public Id opportunityId {get; set;}
        @AuraEnabled
        public String opportunityName {get; set;}
        @AuraEnabled
        public String currencyCode {get; set;}

        MyApproval(final Id quoteId,
                   final String quoteName,
                   final String quoteOwner,
                   final Decimal quoteMRR,
                   final String quoteStatus,
                   final Decimal quoteTotalAmount,
                   final Id opportunityId,
                   final String opportunityName,
                   final String currencyCode) {
            this.quoteId = quoteId;
            this.quoteName = quoteName;
            this.quoteOwner = quoteOwner;
            this.quoteMRR = quoteMRR;
            this.quoteStatus = quoteStatus;
            this.quoteTotalAmount = quoteTotalAmount;
            this.opportunityId = opportunityId;
            this.opportunityName = opportunityName;
            this.currencyCode = currencyCode;
        }
    }
}
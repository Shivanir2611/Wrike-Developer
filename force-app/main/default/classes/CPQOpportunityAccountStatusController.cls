public class CPQOpportunityAccountStatusController {

    private final static CPQSubscriptionService subscriptionSrv = CPQSubscriptionService.getInstance();
    private final static ContractQueryService contractQuerySrv = ContractQueryService.getInstance();
    private final static OpportunityQueryService opportunityQuerySrv = OpportunityQueryService.getInstance();

    @AuraEnabled
    public static AccountStatusResponse getAccountStatus(final Id opportunityId) {
        final Decimal wrikeAccountId = opportunityQuerySrv.findWrikeAccountId(opportunityId);
        final List<Contract> contracts = contractQuerySrv.findContractsByWrikeAccountId(wrikeAccountId);
        return new AccountStatusResponse(
                contracts,
                subscriptionSrv.findAccountActiveProducts(wrikeAccountId),
                contracts.isEmpty() ? null : contracts.get(0).CurrencyIsoCode
        );
    }

    public class AccountStatusResponse {
        @AuraEnabled
        public List<Contract> contracts {get; set;}
        @AuraEnabled
        public List<CPQSubscriptionService.SubscriptionProduct> subscriptionProducts {get; set;}
        @AuraEnabled
        public String currencyCode {get; set;}

        AccountStatusResponse(final List<Contract> contracts,
                              final List<CPQSubscriptionService.SubscriptionProduct> subscriptionProducts,
                              final String currencyCode) {
            this.contracts = contracts;
            this.subscriptionProducts = subscriptionProducts;
            this.currencyCode = currencyCode;
        }
    }
}
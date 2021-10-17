public class CPQSubscriptionService {

    public static CPQSubscriptionService getInstance() {
        return (CPQSubscriptionService)ServiceLocator.getInstance(CPQSubscriptionService.class);
    }

    private final static CPQSubscriptionQueryService subscriptionQuerySrv = CPQSubscriptionQueryService.getInstance();
    private final static CPQProductService productSrv = CPQProductService.getInstance();
    private final static ContractQueryService contractQuerySrv = ContractQueryService.getInstance();

    public List<SubscriptionProduct> findAccountActiveProducts(final Decimal wrikeAccountId) {
        final List<AggregateResult> aggregatedSubscriptions =
                subscriptionQuerySrv.findAggregatedSubscriptionsByWrikeAccountId(wrikeAccountId);
        final List<SubscriptionProduct> subscriptionProducts = new List<SubscriptionProduct>();
        for (AggregateResult subscription : aggregatedSubscriptions) {
            final String productCode = (String)subscription.get('productCode');
            final Decimal mrr = (Decimal)subscription.get('mrr');
            final Decimal renewalMrr = (Decimal)subscription.get('renewalMrr');
            final Boolean uncountable = productSrv.isUncountable(productCode);
            final Decimal quantity = uncountable ? null : (Decimal)subscription.get('quantity');

            final Decimal avgEffectivePrice = uncountable ? mrr : (mrr == 0 ? 0 : (mrr / quantity).setScale(2));
            final Decimal avgRenewalPrice = uncountable
                                            ? (productSrv.isPremiumSupportOrSuccess(productCode) ? mrr : renewalMrr)
                                            : (renewalMrr == 0 ? 0 : (renewalMrr / quantity).setScale(2));
            subscriptionProducts.add(
                    new SubscriptionProduct((String)subscription.get('name'), quantity, avgEffectivePrice,
                            avgRenewalPrice));
        }
        return subscriptionProducts;
    }

    public Boolean checkContractHasLegacySKUSubscriptions(final Id contractId) {
        final List<SBQQ__Subscription__c> subscriptions =
                subscriptionQuerySrv.findSubscriptionsByContractId(contractId);
        final Contract contract = contractQuerySrv.findContractById(contractId);
        final Set<String> legacyProductOptionCodes =
                productSrv.getProductOptionCodesByPackageProductCode(CPQProductService.WrikeSolutionLegacy);
        final Set<String> productOptionCodes =
                productSrv.getProductOptionCodesByPackageProductCode(CPQProductService.WrikeSolution);
        for (SBQQ__Subscription__c subscription : subscriptions) {
            final String productCode = subscription.SBQQ__Product__r.ProductCode;
            if (contract.EndDate == subscription.SBQQ__EndDate__c
                    && (legacyProductOptionCodes.contains(productCode)
                            && !productOptionCodes.contains(productCode)
                            || productSrv.isWrikeSolutionLegacy(productCode))) {
                return true;
            }
        }
        return false;
    }

    public Boolean checkContractHasCurrentSubscription(final Id contractId,
                                                       final String productCode) {
        final List<SBQQ__Subscription__c> subscriptions =
                subscriptionQuerySrv.findSubscriptionsByContractIdAndProductCode(contractId, productCode);
        final Contract contract = contractQuerySrv.findContractById(contractId);
        for (SBQQ__Subscription__c subscription : subscriptions) {
            if (subscription.SBQQ__EndDate__c == contract.EndDate) {
                return true;
            }
        }
        return false;
    }

    public Integer getContractBasePlanQuantity(final Id contractId) {
        final List<SBQQ__Subscription__c> subscriptions = subscriptionQuerySrv.findBasePlanSubscriptionsByContractId(contractId);
        final Contract contract = contractQuerySrv.findContractById(contractId);
        Integer quantity = 0;
        for (SBQQ__Subscription__c subscription : subscriptions) {
            final String productCode = subscription.SBQQ__Product__r.ProductCode;
            if (subscription.SBQQ__EndDate__c == contract.EndDate
                    && (productSrv.isBasePlan(productCode)
                            || productSrv.isLegacyBasePlane(productCode)
                            || productSrv.isProfessionalLicenses(productCode))) {
                quantity = quantity + subscription.SBQQ__Quantity__c.intValue();
            }
        }
        return quantity;
    }

    public class SubscriptionProduct {
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public Decimal quantity {get; set;}
        @AuraEnabled
        public Decimal avgEffectivePrice {get; set;}
        @AuraEnabled
        public Decimal avgRenewalPrice {get; set;}

        SubscriptionProduct(final String name,
                            final Decimal quantity,
                            final Decimal avgEffectivePrice,
                            final Decimal avgRenewalPrice) {
            this.name = name;
            this.quantity = quantity;
            this.avgEffectivePrice = avgEffectivePrice;
            this.avgRenewalPrice = avgRenewalPrice;
        }
    }
}
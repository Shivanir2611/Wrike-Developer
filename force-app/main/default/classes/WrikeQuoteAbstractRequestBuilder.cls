public abstract class WrikeQuoteAbstractRequestBuilder {
    protected Boolean preview;
    protected WrikeQuote quote;
    
    protected Zuora.zObject getAddedProductRatePlanData(final WrikeQuoteItem quoteItem) {
        System.assert(String.isNotBlank(quoteItem.product.zuoraProductRatePlanId), 
            'ProductRatePlanId is required for new product.');
        final Zuora.zObject ratePlanData = new Zuora.zObject('RatePlanData');
        ratePlanData.setValue('RatePlanChargeData', new List<Zuora.zObject> { getRatePlanChargeData(quoteItem) });
        final Zuora.zObject ratePlan = new Zuora.zObject('RatePlan');
        ratePlan.setValue('ProductRatePlanId', quoteItem.product.zuoraProductRatePlanId);
        ratePlanData.setValue('RatePlan', ratePlan);
        return ratePlanData;
    }
    
    protected Zuora.zObject getRemovedProductRatePlanData(final WrikeQuoteItem quoteItem) {
        System.assert(String.isNotBlank(quoteItem.product.zuoraRatePlanId), 
            'AmendmentSubscriptionRatePlanId is required for product removal.');
        final Zuora.zObject ratePlanData = new Zuora.zObject('RatePlanData');
        final Zuora.zObject ratePlan = new Zuora.zObject('RatePlan');
        ratePlan.setValue('AmendmentSubscriptionRatePlanId', quoteItem.product.zuoraRatePlanId);
        ratePlanData.setValue('RatePlan', ratePlan);
        return ratePlanData;
    }
    
    private Zuora.zObject getRatePlanChargeData(final WrikeQuoteItem quoteItem) {
        final WrikeQuoteProduct product = quoteItem.product;
        System.assert(String.isNotBlank(product.zuoraProductRatePlanChargeId),
            'ProductRatePlanChargeId is required for new product.');
        final Zuora.zObject ratePlanCharge = new Zuora.zObject('RatePlanCharge');
        ratePlanCharge.setValue('ProductRatePlanChargeId', product.zuoraProductRatePlanChargeId);
        ratePlanCharge.setValue('Quantity', product.quantity > 0 ? product.quantity : 1);
        ratePlanCharge.setValue('Price', product.getZuoraEffectivePrice());
        if(this.preview) {
            ratePlanCharge.setValue('Description', quoteItem.id);
        }
        final Zuora.zObject ratePlanChargeData = new Zuora.zObject('RatePlanChargeData');
        ratePlanChargeData.setValue('RatePlanCharge', ratePlanCharge);
        if(product.isVolumePricing()) {
            /* making sure the price format of the saved product doesn't depend on
              current Zuora settings of corresponding rate plan charge tiers. */
            final List<Zuora.zObject> ratePlanChargeTier = new List<Zuora.zObject>();
            final Zuora.zObject tier = new Zuora.zObject('RatePlanChargeTier');
            tier.setValue('RatePlanChargeId', product.zuoraProductRatePlanChargeId);
            tier.setValue('Tier', 1);
            tier.setValue('StartingUnit', 1);
            tier.setValue('PriceFormat', product.isPerUnitPrice() ? 'PerUnit' : 'FlatFee');
            tier.setValue('Price', product.getZuoraEffectivePrice());
            ratePlanChargeTier.add(tier);
            ratePlanChargeData.setValue('RatePlanChargeTier', ratePlanChargeTier);
        }
        return ratePlanChargeData;
    }
    
    protected Zuora.zApi.PreviewOptions createPreviewOptions() {
        final Zuora.zApi.PreviewOptions previewOptions = new Zuora.zApi.PreviewOptions();
        previewOptions.EnablePreviewMode = true;
        return previewOptions;
    }
}
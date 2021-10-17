public class WrikeQuoteProduct {

    private static final String LicenseSeatsMatchingProducts = 'Wrike Publish,Wrike Resource,Wrike Integrate,Wrike Lock,' +
    'Advanced Feature Add-on,Wrike Proof,Wrike for Marketers Package,Wrike for Professional Services Package,' +
    'Wrike Analyze,Wrike Performance Package,Project Syncs,Wrike Integrate Standard,Wrike Marketing Insights Standard';

    public Id id {get; set;}
    public String name {get; set;}
    public String description {get; set;}
    public Integer quantity {get; set;}
    public Integer term {get; set;}
    public String chargeType {get; set;}
    public String chargeModel {get; set;}
    public String chargeNumber {get; set;}
    public String priceFormat {get; set;}
    public String serviceType {get; set;}
    public Decimal billingIntervalListPrice {get; set;}
    public Decimal effectivePrice {get; set;}
    public Decimal effectivePricePerUserPerMonth {get; set;}
    public Decimal discount {get; set;}
    public String discountReason {get; set;}
    public String zuoraProductId {get; set;}
    public String zuoraProductRatePlanId {get; set;}
    public String zuoraProductRatePlanChargeId {get; set;}
    public String zuoraProductRatePlanChargeName {get; set;}
    public String zuoraRatePlanId {get; set;}
    public String zuoraRatePlanChargeId {get; set;}
    public Decimal mrr {get; set;}
    public String billingPeriodName {get; set;}
    public Boolean isNotTieredPricingModels {get; set;}
    public ZuoraObject.ZuoraSubscriptionProduct originalSubscriptionProduct {get; set;}
    public Boolean additionalSeats {get; set;}
    public Id product2Id {get; set;}
    private List<SelectOption> predefinedQuantityOptions;
    public Boolean softBundleDiscountApplied {get; set;}

    public WrikeQuoteProduct() {
        this.billingIntervalListPrice = 0;
        this.discount = 0;
        this.quantity = 0;
        this.isNotTieredPricingModels = false;
        this.softBundleDiscountApplied = false;
    }

    public Boolean getIsRecurrent() {
        return this.chargeType == ZuoraRestQueryService.RECURRING;
    }

    public Boolean getCollaboratorsAddon() {
        return ZuoraProductValidationService.getInstance().isCollaboratorsAddon(this.serviceType);
    }

    public Boolean getIsUnlimitedCollaborators() {
        return ZuoraProductValidationService.getInstance().isUnlimitedCollaborators(this.serviceType);
    }

    public Boolean getPartnerCommission() {
        return ZuoraProductValidationService.getInstance().isPartnerCommission(this.serviceType);
    }

    public Boolean isAdditionalStorage() {
        return ZuoraProductValidationService.getInstance().isAdditionalStorage(this.serviceType);
    }

    public Boolean isAdditionalVideoUpload() {
        return ZuoraProductValidationService.getInstance().isAdditionalVideoUpload(this.serviceType);
    }

    public Boolean isWrikeIntegrateEnhanced() {
        return ZuoraProductValidationService.getInstance().isWrikeIntegrateEnhanced(this.serviceType);
    }

    public Boolean isWrikeIntegrateStandard() {
        return ZuoraProductValidationService.getInstance().isWrikeIntegrateStandard(this.name);
    }

    public Boolean isWrikeAnalyze() {
        return ZuoraProductValidationService.getInstance().isWrikeAnalyzeAddon(this.serviceType);
    }

    public Boolean isMarketingInsightsStandard() {
        return ZuoraProductValidationService.getInstance().isMarketingInsightsStandard(this.serviceType);
    }

    public Boolean isMarketingInsightsEnhanced() {
        return ZuoraProductValidationService.getInstance().isMarketingInsightsEnhanced(this.serviceType);
    }

    public Boolean isWrikeIntegrate() {
        return ZuoraProductValidationService.getInstance().isWrikeIntegrate(this.name);
    }

    public Boolean isWrikePerformancePackage() {
        return ZuoraProductValidationService.getInstance().isPerformancePackage(this.serviceType);
    }

    public Boolean getIsPremiumSupport() {
        return ZuoraProductValidationService.getInstance().isPremiumSupport(this.serviceType);
    }

    public Integer getBillingPeriodInMonth() {
        Integer billingPeriodInMonth =
                ZuoraProductService.getInstance().getRecurringPeriodInMonth(this.billingPeriodName);
        if (billingPeriodInMonth == null) {
            return 0;
        }
        return billingPeriodInMonth;
    }

    public Boolean getIsBillingPeriodValidForTerm() {
        Integer billingPeriodInMonth = getBillingPeriodInMonth();
        if (this.term == null || billingPeriodInMonth == null) {
            return false;
        }
        return Math.mod(this.term, billingPeriodInMonth) == 0;
    }

    public Integer getBillingPeriodCount() {
        Integer billingPeriods = getBillingPeriodInMonth();
        if (this.term == null || billingPeriods == 0) {
            return 0;
        }
        return this.term / billingPeriods;
    }

    public Decimal getListPrice() {
        return this.billingIntervalListPrice;
    }

    public Decimal getMonthListPrice() {
        Integer billingPeriodInMonth = getBillingPeriodInMonth();
        if (!getIsRecurrent() || billingPeriodInMonth < 1) {
            return this.getListPrice();
        }
        return this.getListPrice() / billingPeriodInMonth;
    }

    private Decimal getMonthEffectivePrice() {
        Integer billingPeriodInMonth = getBillingPeriodInMonth();
        if (!getIsRecurrent() || billingPeriodInMonth < 1) {
            return this.effectivePrice;
        }
        return this.effectivePrice / billingPeriodInMonth;
    }

    public Decimal getTermListPrice() {
        if (!getIsRecurrent() || this.term == null) {
            return getListPrice();
        }
        return getMonthListPrice() * this.term;
    }

    public Decimal getTermEffectivePrice() {
        if (!getIsRecurrent() || this.term == null) {
            return this.effectivePrice;
        }
        return getMonthEffectivePrice() * this.term;
    }

    public String getUniqueString() {
        return String.join(new List<Object>{
                this.zuoraProductRatePlanChargeId,
                this.quantity,
                this.effectivePrice.setScale(3, RoundingMode.HALF_UP),
                this.term
                }, '');
    }

    public Integer getOriginalQuantity() {
        if (this.originalSubscriptionProduct == null) {
            return null;
        }
        return Integer.valueOf(this.originalSubscriptionProduct.quantity);
    }

    public Boolean isQuantityChanged() {
        return this.quantity != getOriginalQuantity();
    }

    public Boolean isSeatProduct() {
        return ZuoraProductService.getInstance().isSeat(this.serviceType);
    }

    public Boolean isPartnerCommission() {
        return ZuoraProductService.getInstance().isPartnerCommission(this.serviceType);
    }

    public Boolean isLicenseSeatsMatchingProduct() {
        return new Set<String>(LicenseSeatsMatchingProducts.split(',')).contains(this.name);
    }

    public Boolean isImplementation() {
        return ZuoraProductService.getInstance().isImplementation(this.serviceType);
    }

    public Boolean isPerUnitPrice() {
        return this.chargeModel == 'Per Unit Pricing' || this.priceFormat == 'Per Unit';
    }

    public Boolean isFlatFeePricing() {
        return this.chargeModel == 'Flat Fee Pricing';
    }

    public Boolean isVolumePricing() {
        return this.chargeModel == 'Volume Pricing';
    }

    public Decimal getMaxDiscount() {
        return SettingsProvider.findMaxDiscountByProductName(this.name);
    }

    public String getUnitName() {
        return isSeatProduct() || isLicenseSeatsMatchingProduct() ? 'User' : 'Unit';
    }

    public List<SelectOption> getPredefinedQuantityOptions() {
        if (this.predefinedQuantityOptions == null) {
            this.predefinedQuantityOptions = SettingsProvider.getPredefinedQuantityOptions(this.name);
        }
        return this.predefinedQuantityOptions;
    }

    public void calculateDiscountByPrice() {
        final Decimal billingPeriodEffectivePrice = getBillingPeriodEffectivePrice();
        if (this.billingIntervalListPrice != 0 && billingPeriodEffectivePrice != null) {
            if (effectivePricePerUserPerMonth != null) {
                this.effectivePrice = billingPeriodEffectivePrice;
            }
            this.discount =
                    (((billingIntervalListPrice - billingPeriodEffectivePrice) / billingIntervalListPrice) * 100)
                            .setScale(2, RoundingMode.HALF_UP);
        }
    }

    public void calculatePriceByDiscount() {
        if (this.discount == null) {
            this.discount = 0;
        }
        if (getPerUserPerMonthPriceUsage()) {
            final Integer months = getBillingPeriodInMonth();
            this.effectivePricePerUserPerMonth =
                    ((billingIntervalListPrice / (quantity * months)) * (100 - this.discount) / 100)
                            .setScale(2, RoundingMode.HALF_UP);
            this.effectivePrice = this.effectivePricePerUserPerMonth * quantity * months;
        } else {
            this.effectivePrice = (billingIntervalListPrice * (100 - this.discount) / 100)
                    .setScale(2, RoundingMode.HALF_UP);
        }
    }

    public void recalculateEffectivePriceByPricePerUserPerMonth() {
        if (getPerUserPerMonthPriceUsage()) {
            this.effectivePrice = this.effectivePricePerUserPerMonth * quantity * getBillingPeriodInMonth();
        }
    }

    public Boolean getPerUserPerMonthPriceUsage() {
        return this.quantity > 0 &&
                getBillingPeriodInMonth() > 0 &&
                getPredefinedQuantityOptions().isEmpty() &&
                !isAdditionalStorage() &&
                !isAdditionalVideoUpload();
    }

    public Decimal getBillingPeriodEffectivePrice() {
        return effectivePricePerUserPerMonth != null
               ? effectivePricePerUserPerMonth * getBillingPeriodInMonth() * quantity
               : effectivePrice;
    }

    public Decimal getZuoraEffectivePrice() {
        if (effectivePricePerUserPerMonth != null) {
            return isPerUnitPrice()
                   ? effectivePricePerUserPerMonth * getBillingPeriodInMonth()
                   : effectivePricePerUserPerMonth * getBillingPeriodInMonth() * quantity;
        }
        return isPerUnitPrice()
               ? (effectivePrice / quantity).setScale(2, RoundingMode.HALF_UP)
               : effectivePrice;
    }

    public Decimal getPricePerUserPerMonth() {
        return mrr != null
               ? mrr / quantity
               : effectivePricePerUserPerMonth;
    }

    public Decimal getPricePerUnitPerMonth() {
        if(!getIsRecurrent()) {
            return null;
        }
        final Decimal mrr = getProductMrr();
        return quantity > 1 ? (mrr/quantity).setScale(2, RoundingMode.HALF_UP) : mrr;
    }

    public Decimal getProductMrr() {
        if (mrr != null) {
            return mrr;
        }
        if (effectivePricePerUserPerMonth != null) {
            return effectivePricePerUserPerMonth * quantity;
        }
        Integer billingPeriodInMonth = getBillingPeriodInMonth();
        if (billingPeriodInMonth > 0 && effectivePrice > 0) {
            return (effectivePrice / billingPeriodInMonth).setScale(2, RoundingMode.HALF_UP);
        }
        return 0;
    }
}
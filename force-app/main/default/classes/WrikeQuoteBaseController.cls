public abstract class WrikeQuoteBaseController {

    public static final String QUOTE_DETAILS_STEP = 'QUOTE_DETAILS';
    public static final String PRODUCTS_TABLE_STEP = 'PRODUCTS_TABLE';

    public WrikeQuote wQuote {get; set;}
    public String step {get; set;}
    public WrikeQuoteProduct newProduct {get; set;}
    public String deleteItemUID {get; set;}
    public String editItemUID {get; set;}
    public Boolean isSetToFuture {get; set;}
    public Boolean disableInvoiceDate {get; set;}

    private Boolean quantityChanged {get; set;}
    private Boolean ratePlanChanged {get; set;}
    private Boolean productChanged {get; set;}
    public Boolean deploymentsAdding {get; set;}
    public Integer softBundleRecalculateOption {get; set;}

    protected Boolean hasWfMPerformance = false;
    protected Boolean hasWfPSPerformance = false;
    protected List<WrikeQuoteProduct> previewSoftBundleProducts = new List<WrikeQuoteProduct>();
    protected ValidationResult validationResults = new ValidationResult();
    protected Map<String, ZuoraProductCatalogService.Product> productCatalogMap;
    protected List<ZuoraProductCatalogService.ProductRatePlanWithCharge> productRatePlans = new List<ZuoraProductCatalogService.ProductRatePlanWithCharge>();
    protected List<String> quoteItemIdsForDelete = new List<String>();
    protected String returnUrl;
    protected Integer initialNewTerm;
    protected Integer initialNumberOfTeams;
    private final Boolean usUser = UserService.getInstance().isUsUser(UserInfo.getUserId());
    private final Boolean pro200Allowed = usUser || Settings__c.getOrgDefaults().EnablePro200Globally__c;

    protected QuoteDateService quoteDateSrv;
    protected QuoteService quoteSrv = QuoteService.getInstance();
    protected ZuoraProductService zuoraProductSrv = ZuoraProductService.getInstance();
    protected QuoteValidationService quoteValidationSrv = QuoteValidationService.getInstance();
    protected OpportunityProductService opportunityProductSrv = OpportunityProductService.getInstance();
    protected ProductService productSrv = ProductService.getInstance();

    public WrikeQuoteBaseController() {
        final Map<String, String> getParams = ApexPages.currentPage().getParameters();
        final String quoteId = getParams.get(RequestParam.QUOTE_ID);
        final String opportunityId = getParams.get(RequestParam.OPPORTUNITY_ID);
        final String zuoraAccountId = getParams.get(RequestParam.ZUORA_ACCOUNT_ID);
        final String step = getParams.get(RequestParam.STEP);
        this.returnUrl = getParams.get(RequestParam.RETURN_URL);

        this.step = getStepsOrder().get(0);
        this.isSetToFuture = false;

        initServices();

        try {
            this.disableInvoiceDate = !ProfileQueryService.getInstance().isAdminOrBillingProfile(UserInfo.getProfileId());
            if (String.isNotBlank(quoteId) && String.isNotBlank(step)) {
                if (step == QUOTE_DETAILS_STEP || step == PRODUCTS_TABLE_STEP) {
                    this.wQuote = this.quoteSrv.findWithItemsById(quoteId);
                    this.step = step;
                    this.initialNewTerm = this.wQuote.newTerm;
                    this.initialNumberOfTeams = this.wQuote.numberOfTeams;
                    updateHasSoftBundles();
                } else {
                    throw new LogicException(StringUtils.format('Step parameter is invalid:', step));
                }
            } else {
                initQuote(opportunityId, zuoraAccountId);
            }
            if (this.wQuote == null) {
                throw new LogicException('Required parameters is missing (quoteId & step or opportunityId & zuoraAccountId)');
            }
        } catch(LogicException logicExp) {
            this.validationResults.addFatal(logicExp.getMessage());
        }
    }

    protected abstract void initServices();

    protected abstract void initQuote(String opportunityId, String zuoraAccountId);

    public String getQuoteDetailsStepName() {
        return QUOTE_DETAILS_STEP;
    }

    public String getProductsTableStepName() {
        return PRODUCTS_TABLE_STEP;
    }

    protected abstract List<String> getStepsOrder();

    public ValidationResult getValidationResults() {
        return this.validationResults;
    }

    public List<WrikeQuoteProduct> getPreviewSoftBundleProducts() {
        return this.previewSoftBundleProducts;
    }

    public String getMinEffectiveDate() {
        if (this.wQuote == null) {
            return null;
        }
        return DateUtils.format(this.quoteDateSrv.getMinEffectiveDate(this.wQuote));
    }

    public String getMaxEffectiveDate() {
        if (this.wQuote == null) {
            return null;
        }
        return DateUtils.format(this.quoteDateSrv.getMaxEffectiveDate(this.wQuote));
    }

    public String getMinVaidUntilDate() {
        return DateUtils.format(this.quoteDateSrv.getMinValidUntil());
    }

    public String getMaxVaidUntilDate() {
        Date maxValidUntil = this.quoteDateSrv.getMaxValidUntil(this.wQuote);
        if (maxValidUntil == null) {
            return null;
        }
        return DateUtils.format(maxValidUntil);
    }

    public String getMinInvoiceDate() {
        return DateUtils.format(this.quoteDateSrv.getMinInvoiceDate(this.wQuote.effectiveDate));
    }

    public String getMaxInvoiceDate() {
        return DateUtils.format(this.quoteDateSrv.getMaxInvoiceDate(this.wQuote.effectiveDate));
    }

    public String getSubscriptionStartDate() {
        return DateUtils.format(this.wQuote.subscriptionStartDate);
    }

    public String getSubscriptionEndDate() {
        return DateUtils.format(this.wQuote.subscriptionEndDate);
    }

    public String getFirstDateOfCurrentMonth() {
        return DateUtils.format(Date.today().toStartOfMonth());
    }

    public String getLastDateOfEffectiveDateMonth() {
        return DateUtils.format(this.wQuote.effectiveDate.toStartOfMonth().addMonths(1).addDays(-1));
    }

    public Integer getQuoteValidDays() {
        if (this.wQuote == null || this.wQuote.validUntil == null || !this.wQuote.isBeforeRenewType()) {
            return null;
        }
        Integer quoteValidDays = Date.today().daysBetween(this.wQuote.validUntil);
        if (quoteValidDays >= 6) {
            return null;
        }
        return quoteValidDays + 1;
    }

    public String getSetToFutureLabel() {
        if (SettingsProvider.isSubscriptionStartDateInThePastAllowed()) {
            return 'Set to different date';
        } else {
            return 'Set to future';
        }
    }

    public Boolean getIsSaveQuoteDetailsVisible() {
        return String.isNotBlank(this.returnUrl);
    }

    public Boolean getIsPaidForTravelVisible() {
        ZuoraProductCatalogService.ProductRatePlanWithCharge selectedRatePlan = getSelectedRatePlan();
        return newProduct != null && zuoraProductSrv.isImplementation(newProduct.serviceType)
            && selectedRatePlan != null && selectedRatePlan.name != null && selectedRatePlan.name.toLowerCase().contains('onsite');
    }

    public void effectiveDateChangeHandler() {
        final Date minInvoiceDate = this.quoteDateSrv.getMinInvoiceDate(this.wQuote.effectiveDate);
        final Date maxInvoiceDate = this.quoteDateSrv.getMaxInvoiceDate(this.wQuote.effectiveDate);
        if (this.wQuote.effectiveDate < minInvoiceDate || this.wQuote.effectiveDate > maxInvoiceDate) {
            this.wQuote.invoiceDate = Date.today();
        } else {
            this.wQuote.invoiceDate = this.wQuote.effectiveDate;
        }
    }

    public void changeTermHandler() {
        this.validationResults.clear();
        if (getIsNeedResetProductState()) {
            this.validationResults.addWarn('Term was changed. Existing products will be removed.');
        }
        this.wQuote.renewalTerm = this.wQuote.newTerm;
    }

    public void changeNumberOfTeamsHandler() {
        this.validationResults.clear();
        if (getIsNeedResetProductState()) {
            this.validationResults.addWarn('Number of Teams or Processes was changed. Existing products will be removed.');
        }
    }

    public void changePublicityRightsRemoval() {
        if (this.wQuote.publicityRightsRemoval) {
            this.wQuote.coMarketingAddition = false;
        }
    }

    public void changeAutoRenewalRemoval() {
        if (this.wQuote.autoRenewalRemoval) {
            this.wQuote.renewalPriceProtection = null;
        }
    }

    public void changeOnetimeDiscountIncluded() {
        if (this.wQuote.onetimeDiscountIncluded) {
            this.wQuote.agencyReliefOfferDiscount = false;
        }
    }

    public void changeAgencyReliefOfferDiscount() {
        if (this.wQuote.agencyReliefOfferDiscount) {
            this.wQuote.onetimeDiscountIncluded = false;
        }
    }

    public void setToFutureChangeHandler() {
        if (this.isSetToFuture == false) {
            this.wQuote.effectiveDate = Date.today();
            effectiveDateChangeHandler();
        }
    }

    protected void resetQuoteProducts(final Boolean isNeedRemoveExisting) {
        final Integer endItemIndex = this.wQuote.items.size() - 1;
        for (Integer itemIndex = endItemIndex; itemIndex >= 0; itemIndex--) {
            final WrikeQuoteItem quoteItem = this.wQuote.items.get(itemIndex);
            if (quoteItem.getIsAdded()) {
                this.wQuote.items.remove(itemIndex);
                if (String.isNotBlank(quoteItem.id)) {
                    this.quoteItemIdsForDelete.add(quoteItem.id);
                }
            }
            if (isNeedRemoveExisting && quoteItem.getIsExisting()) {
                quoteItem.state = WrikeQuoteItem.State.REMOVED;
            }
            if (!isNeedRemoveExisting && quoteItem.getIsRemoved()) {
                quoteItem.state = WrikeQuoteItem.State.EXISTING;
            }
        }
    }

    public virtual Boolean getIsNeedResetProductState() {
        return this.initialNewTerm != null
                && this.wQuote.newTerm != null
                && this.wQuote.newTerm != this.initialNewTerm
                || this.initialNumberOfTeams != null
                        && this.wQuote.numberOfTeams != null
                        && this.wQuote.numberOfTeams != this.initialNumberOfTeams;
    }

    public void changeProductHandler() {
        this.newProduct.zuoraProductRatePlanId = null;
        this.newProduct.zuoraProductRatePlanChargeId = null;
        this.newProduct.quantity = 0;
        this.newProduct.discount = 0;
        this.newProduct.billingIntervalListPrice = 0;
        ZuoraProductCatalogService.Product selectedProduct = this.productCatalogMap.get(this.newProduct.zuoraProductId);
        if (selectedProduct != null) {
            this.newProduct.name = selectedProduct.name;
            this.newProduct.serviceType = selectedProduct.serviceType;
            if (zuoraProductSrv.isSeat(selectedProduct.serviceType)) {
                this.productRatePlans = zuoraProductSrv.filterRatePlansFromProduct(
                        selectedProduct,
                        this.wQuote.newTerm,
                        this.wQuote.renewalTerm,
                        this.wQuote.quoteCurrency);
                this.newProduct.zuoraProductRatePlanId = zuoraProductSrv.getRatePlanIdWithMaxRequrringPeriod(this.productRatePlans);
                populatePrice();
            }
        }
        if (this.editItemUID != null) {
            this.productChanged = true;
        }
    }

    private Integer findNumberOfLicenseSeats() {
        final WrikeQuoteProduct licenseProduct = findLicenseProduct();
        return licenseProduct != null ? licenseProduct.quantity : 0;
    }

    private WrikeQuoteProduct findLicenseProduct() {
        for(WrikeQuoteItem item : wQuote.items) {
            if((item.getIsAdded() || item.getIsExisting()) && zuoraProductSrv.isSeat(item.product.serviceType)) {
                return item.product;
            }
        }
        return null;
    }

    public void changeQuantity() {
        final ZuoraObject.ZuoraRatePlanChargeTier matchingTier = findMatchingTier(getSelectedRatePlan());
        if (matchingTier != null) {
            if (this.newProduct.isPerUnitPrice()) {
                this.newProduct.billingIntervalListPrice = matchingTier.price * this.newProduct.quantity;
            } else {
                this.newProduct.billingIntervalListPrice = matchingTier.price;
            }
            this.newProduct.calculatePriceByDiscount();
        }

        if (this.editItemUID != null) {
            this.quantityChanged = true;
        }
    }

    public void populatePrice() {
        this.newProduct.isNotTieredPricingModels = false;
        final ZuoraProductCatalogService.Product selectedZuoraProduct = this.productCatalogMap.get(this.newProduct.zuoraProductId);
        final ZuoraProductCatalogService.ProductRatePlanWithCharge selectedRatePlan = getSelectedRatePlan();
        if (selectedRatePlan == null) {
            return;
        }
        this.newProduct.zuoraProductRatePlanChargeName = selectedRatePlan.name;
        this.newProduct.billingPeriodName = selectedRatePlan.billingPeriodName;
        this.newProduct.chargeType = selectedRatePlan.chargeType;
        this.newProduct.chargeModel = selectedRatePlan.chargeModel;
        this.newProduct.term = this.wQuote.newTerm;
        this.newProduct.name = selectedZuoraProduct.name;
        this.newProduct.description = selectedZuoraProduct.description;
        this.newProduct.serviceType = selectedZuoraProduct.serviceType;
        this.newProduct.zuoraProductRatePlanChargeId = selectedRatePlan.productRatePlanChargeId;
        this.newProduct.billingPeriodName = selectedRatePlan.billingPeriodName;
        if (!newProduct.getIsRecurrent() && String.isEmpty(this.newProduct.billingPeriodName)) {
            this.newProduct.billingPeriodName = 'One-Time';
        }
        this.newProduct.zuoraProductRatePlanChargeName = selectedRatePlan.name;
        if (this.newProduct.quantity == null || this.newProduct.quantity == 0) {
            if(this.newProduct.isAdditionalStorage()
                    || this.newProduct.isAdditionalVideoUpload()
                    || this.newProduct.isWrikeIntegrateEnhanced()
                    || this.newProduct.isMarketingInsightsEnhanced()) {
                this.newProduct.quantity = 1;
            } else if(!this.newProduct.getPredefinedQuantityOptions().isEmpty()) {
                this.newProduct.quantity = Integer.valueOf(this.newProduct.getPredefinedQuantityOptions().get(0).getValue());
            } else if(this.newProduct.isLicenseSeatsMatchingProduct()) {
                final Integer licenseSeats = findNumberOfLicenseSeats();
                this.newProduct.quantity = licenseSeats > 0 ? licenseSeats : 5;
            } else if (selectedZuoraProduct.isSeatOrAddon()) {
                this.newProduct.quantity = 5;
            } else if(selectedZuoraProduct.isCollaboratorsAddon()) {
                this.newProduct.quantity = 100;
            } else {
                this.newProduct.quantity = selectedRatePlan.minQuantity;
            }
        }
        final ZuoraObject.ZuoraRatePlanChargeTier currentTier = findMatchingTier(selectedRatePlan);
        if(currentTier != null) {
            this.newProduct.isNotTieredPricingModels = newProduct.isFlatFeePricing();
            this.newProduct.priceFormat = currentTier.priceFormat;
            final Boolean listPriceIgnored = SettingsProvider.isCustomRatePlan(this.newProduct.zuoraProductRatePlanChargeName);
            if(listPriceIgnored) {
                this.newProduct.billingIntervalListPrice = 0;
                this.newProduct.effectivePrice = null;
                this.newProduct.effectivePricePerUserPerMonth = null;
            } else if (this.newProduct.getIsUnlimitedCollaborators()) {
                this.newProduct.billingIntervalListPrice = 0;
                this.newProduct.effectivePricePerUserPerMonth = null;
                this.newProduct.effectivePrice = 0;
            } else if (this.newProduct.getIsPremiumSupport()) {
                this.newProduct.billingIntervalListPrice = 0;
                this.newProduct.effectivePrice = calculatePriceByUserProducts();
            } else if(this.newProduct.getPerUserPerMonthPriceUsage()) {
                final Integer billingPeriodMonths = this.newProduct.getBillingPeriodInMonth();
                if(this.newProduct.isPerUnitPrice()) {
                    this.newProduct.billingIntervalListPrice = currentTier.price*this.newProduct.quantity;
                    this.newProduct.effectivePricePerUserPerMonth =
                            (currentTier.price/billingPeriodMonths)
                                    .setScale(2, RoundingMode.HALF_UP);
                } else {
                    this.newProduct.billingIntervalListPrice = currentTier.price;
                    this.newProduct.effectivePricePerUserPerMonth =
                            (currentTier.price/(this.newProduct.quantity*billingPeriodMonths))
                                    .setScale(2, RoundingMode.HALF_UP);
                }
                this.newProduct.effectivePrice = this.newProduct.effectivePricePerUserPerMonth*this.newProduct.quantity*billingPeriodMonths;
            } else {
                this.newProduct.billingIntervalListPrice = currentTier.price;
                this.newProduct.effectivePrice = currentTier.price;
                this.newProduct.effectivePricePerUserPerMonth = null;
            }
            this.newProduct.discount = 0;
        }

        if (this.editItemUID != null) {
            this.ratePlanChanged = true;
        }
    }

    private ZuoraObject.ZuoraRatePlanChargeTier findMatchingTier(final ZuoraProductCatalogService.ProductRatePlanWithCharge ratePlan) {
        final Boolean isOnlyOneInterval = ratePlan.tiers.size() == 1
                && ratePlan.tiers[0].startingUnit == 0
                && (ratePlan.tiers[0].endingUnit == null || ratePlan.tiers[0].endingUnit == 0);
        if (isOnlyOneInterval) {
            return ratePlan.tiers[0];
        }
        for (ZuoraObject.ZuoraRatePlanChargeTier currentTier : ratePlan.tiers) {
            final Boolean isQuantityInInterval = this.newProduct.quantity >= currentTier.startingUnit
                    && this.newProduct.quantity <= currentTier.endingUnit;
            if (isQuantityInInterval) {
                return currentTier;
            }
            final Boolean perUnitOpenTier = currentTier.isPerUnit()
                    && currentTier.endingUnit == null
                    && this.newProduct.quantity >= currentTier.startingUnit;
            if (perUnitOpenTier == true) {
                return currentTier;
            }
        }
        return null;
    }

    public void recalculateByPrice() {
        if(this.newProduct.billingIntervalListPrice > 0) {
            this.newProduct.calculateDiscountByPrice();
        } else {
            this.newProduct.recalculateEffectivePriceByPricePerUserPerMonth();
        }
    }

    public void recalculateByDiscount() {
        this.newProduct.calculatePriceByDiscount();
    }

    public PageReference showNewProductSection() {
        this.newProduct = new WrikeQuoteProduct();
        initZProducts();
        this.deploymentsAdding = false;
        return null;
    }

    public PageReference showNewDeploymentSection() {
        this.newProduct = new WrikeQuoteProduct();
        initZProducts();
        this.deploymentsAdding = true;
        return null;
    }

    public PageReference cancelNewProduct() {
        this.validationResults.clear();
        this.editItemUID = null;
        this.newProduct = null;
        return null;
    }

    public PageReference addNewProduct() {
        this.validationResults.clear();
        if (String.isBlank(this.newProduct.zuoraProductId)
            || String.isBlank(this.newProduct.zuoraProductRatePlanId)
            || this.newProduct.quantity == null
            || this.newProduct.effectivePrice == null
            || this.newProduct.discount == null) {
            this.validationResults.addError('Please fill out all required fields.');
            return null;
        }
        if (this.newProduct.effectivePrice < 0 && this.newProduct.getPartnerCommission() == false) {
            this.validationResults.addError('Effective Price should be positive.');
            return null;
        }
        if (this.newProduct.discount > 100) {
            this.validationResults.addError('Discount should not be more then 100%.');
            return null;
        }
        if (this.newProduct.isAdditionalStorage() || this.newProduct.isAdditionalVideoUpload()) {
            if(this.newProduct.discount > 20) {
                this.validationResults.addError(this.newProduct.name + ' can not be discounted for more than 20%.');
                return null;
            }
            if(this.newProduct.quantity > 100) {
                this.validationResults.addError('We can not sell more than 100 ' + this.newProduct.name + ' packages per customer.');
                return null;
            }
            if(this.newProduct.quantity <= 0) {
                this.validationResults.addError('Please provide a valid quantity.');
                return null;
            }
        }

        ZuoraProductCatalogService.ProductRatePlanWithCharge selectedZuoraProductRatePlan = getSelectedRatePlan();

        if (this.newProduct.quantity > selectedZuoraProductRatePlan.maxQuantity
            || this.newProduct.quantity < selectedZuoraProductRatePlan.minQuantity) {
            this.validationResults.addError(StringUtils.format('Quantity should include in the interval from {0} to {1}.',
                selectedZuoraProductRatePlan.minQuantity, selectedZuoraProductRatePlan.maxQuantity));
            return null;
        }

        final Boolean isUserProduct = this.newProduct.isSeatProduct() || this.newProduct.isLicenseSeatsMatchingProduct();

        if (this.editItemUID == null) {
            removeDuplicatedProducts(this.newProduct, this.newProduct.additionalSeats == true);
            final WrikeQuoteItem item = this.wQuote.addItem(WrikeQuoteItem.State.ADDED, this.newProduct);
            recalculateDeployments(item);
        } else {
            final WrikeQuoteItem item = this.wQuote.getItemByUID(this.editItemUID);
            if (item != null) {
                item.product = (WrikeQuoteProduct)this.newProduct.clone();
                quoteSrv.mapToStandardProduct(item);
                recalculateDeployments(item);
            }
            this.editItemUID = null;
        }
        this.wQuote.items.sort();

        if (isUserProduct) {
            final WrikeQuoteItem premiumSupportItem = this.wQuote.getAddedItemByServiceType('PremiumSupport');
            if (premiumSupportItem != null) {
                premiumSupportItem.product.effectivePrice = calculatePriceByUserProducts();
            }
        }
        updateHasSoftBundles();
        this.newProduct = null;
        return null;
    }

    private void recalculateDeployments(final WrikeQuoteItem item) {
        final WrikeProduct wrikeProduct = productSrv.findProductById(item.product.product2Id);
        if (!wrikeProduct.isDeployment() && (isProductChangedOrAdded() || this.quantityChanged == true)) {
            if (this.productChanged == true || this.quantityChanged == true) {
                resetRelatedDeployments(item.uid);
            }
            if (this.productChanged == true) {
                resetDeploymentsWithoutRequiredProduct();
            }
            addAutoDeployments(item);
            if (isProductChangedOrAdded() && (wrikeProduct.isWfPSPackage() || wrikeProduct.isWfMPackage())) {
                recalculateDeploymentsForPerformancePackage();
            }
        } else if (wrikeProduct.isDeployment() && (isProductChangedOrAdded() || this.ratePlanChanged == true)) {
            item.parentItemUID = null;
            linkDeploymentWithExistingParentProduct(item);
            if (isProductChangedOrAdded()) {
                linkDeploymentWithExistingSeatProduct(item);
            }
        }
        this.productChanged = false;
        this.ratePlanChanged = false;
        this.quantityChanged = false;
    }

    private void recalculateDeploymentsForPerformancePackage() {
        final WrikeQuoteItem item = this.wQuote.getAddedItemByServiceType('WrikePerformancePackage');
        if (item != null) {
            resetRelatedDeployments(item.uid);
            addAutoDeployments(item);
        }
    }

    private Boolean isProductChangedOrAdded() {
        return this.editItemUID == null || this.productChanged == true;
    }

    public void removeProduct() {
        this.validationResults.clear();

        if (this.deleteItemUID == null) {
            return;
        }
        WrikeQuoteItem quoteItem = this.wQuote.getItemByUID(this.deleteItemUID);
        if (quoteItem.state == WrikeQuoteItem.State.EXISTING) {
            quoteItem.state = WrikeQuoteItem.State.REMOVED;
        } else if (quoteItem.state == WrikeQuoteItem.State.ADDED) {
            final Integer itemIndex = this.wQuote.items.indexOf(quoteItem);
            WrikeQuoteItem wrikeQuoteItemForDelete = this.wQuote.items.remove(itemIndex);
            if (wrikeQuoteItemForDelete.id != null) {
                quoteItemIdsForDelete.add(wrikeQuoteItemForDelete.id);
            }
        }
        if (quoteItem.product.getIsRecurrent()) {
            resetRelatedDeployments(this.deleteItemUID);
            resetDeploymentsWithoutRequiredProduct();
        }
        if (quoteItem.product.isSeatProduct() || quoteItem.product.isLicenseSeatsMatchingProduct()) {
            final WrikeQuoteItem premiumSupportItem = this.wQuote.getAddedItemByServiceType('PremiumSupport');
            if (premiumSupportItem != null) {
                premiumSupportItem.product.effectivePrice = calculatePriceByUserProducts();
            }
        }
        updateHasSoftBundles();
        this.deleteItemUID = null;
    }

    private void updateHasSoftBundles() {
        this.hasWfMPerformance = getQuoteHasWfMPerformance();
        this.hasWfPSPerformance = getQuoteHasWfPSPerformance();
        this.softBundleRecalculateOption = 1;
        changeSoftBundleRecalculateOption();
    }

    private Boolean isReplaceNeeded(final WrikeQuoteItem item,
                                    final WrikeQuoteProduct newProduct,
                                    final Boolean additionalSeats) {
        if(item.getIsRemoved()) {
            return false;
        }
        final Boolean newMainLicenseProduct = newProduct.isSeatProduct();
        final Boolean newUserProduct = newProduct.isLicenseSeatsMatchingProduct();
        final Boolean mainLicenseItem = item.product.isSeatProduct();
        final Boolean userProductItem = item.product.isLicenseSeatsMatchingProduct();
        final Boolean sameProduct = newProduct.zuoraProductId == item.product.zuoraProductId;
        final Boolean sameRatePlan = newProduct.zuoraProductRatePlanId == item.product.zuoraProductRatePlanId;
        final Boolean implementation = newProduct.isImplementation();
        if(newMainLicenseProduct && mainLicenseItem) {
            return item.getIsAdded() || (item.getIsExisting() && !additionalSeats);
        }
        if(newUserProduct && userProductItem) {
            return sameProduct && (item.getIsAdded() || (item.getIsExisting() && !additionalSeats));
        }
        return (!implementation && sameProduct) || (implementation && sameRatePlan && item.getIsAdded());
    }

    private void removeDuplicatedProducts(final WrikeQuoteProduct newProduct, final Boolean additionalSeats) {
        final List<WrikeQuoteItem> updatedItems = new List<WrikeQuoteItem>();
        for(WrikeQuoteItem item : this.wQuote.items) {
            if (isReplaceNeeded(item, newProduct, additionalSeats)) {
                if (item.getIsExisting()) {
                    item.state = WrikeQuoteItem.State.REMOVED;
                    updatedItems.add(item);
                } else if (item.id != null) {
                    quoteItemIdsForDelete.add(item.id);
                }
            } else {
                updatedItems.add(item);
            }
        }
        this.wQuote.items = updatedItems;
    }

    public void restoreProduct() {
        this.validationResults.clear();

        WrikeQuoteItem quoteItem = this.wQuote.getItemByUID(this.deleteItemUID);
        if (this.deleteItemUID == null) {
            return;
        }
        removeDuplicatedProducts(quoteItem.product, false);
        if (quoteItem.state == WrikeQuoteItem.State.REMOVED) {
            quoteItem.state = WrikeQuoteItem.State.EXISTING;
        }
        this.deleteItemUID = null;
    }

    public void editProduct() {
        initZProducts();
        if (this.editItemUID == null) {
            return;
        }
        WrikeQuoteItem quoteItem = this.wQuote.getItemByUID(this.editItemUID);
        if (!quoteItem.getIsAdded()) {
            this.editItemUID = null;
            return;
        }
        this.newProduct = (WrikeQuoteProduct)quoteItem.product.clone();
        if (this.newProduct.quantity == 0) {
            this.newProduct.isNotTieredPricingModels = true;
        }
        getProductPlanOptions();
    }

    public List<SelectOption> getProductOptions() {
        final List<ZuoraProductCatalogService.Product> products = new List<ZuoraProductCatalogService.Product>();
        for (ZuoraProductCatalogService.Product product : this.productCatalogMap.values()) {
            if (isAllowedProduct(product)) {
                products.add(product);
            }
        }
        final List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', ''));
        products.sort();
        for(ZuoraProductCatalogService.Product product : products) {
            options.add(new SelectOption(product.id, product.name));
        }
        return options;
    }

    private Boolean isAllowedProduct(final ZuoraProductCatalogService.Product product) {
        return this.deploymentsAdding == true
                && product.isImplementation()
                && (!product.isSelfStart()
                        && !product.isSmartStart()
                        || this.wQuote.getIsSubscription())
                || this.deploymentsAdding == false
                        && !product.isImplementation()
                        && (!product.isWrikeIntegrate()
                                || (this.wQuote.getIsAmendment()
                                        && this.wQuote.hasWrikeIntegrate()))
                        && (!product.isWrikePerformancePackage()
                                || (this.wQuote.getIsAmendment()
                                        && this.wQuote.hasWrikePerformancePackage()));
    }

    public List<SelectOption> getProductPlanOptions() {
        final List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', ''));

        final ZuoraProductCatalogService.Product selectedProduct = this.productCatalogMap.get(this.newProduct.zuoraProductId);
        if (selectedProduct == null) {
            return options;
        }

        this.productRatePlans = zuoraProductSrv.filterRatePlansFromProduct(
                selectedProduct,
                this.wQuote.newTerm,
                this.wQuote.renewalTerm,
                this.wQuote.quoteCurrency);

        final Map<String, String> ratePlanIdByName = new Map<String, String>();
        for (ZuoraProductCatalogService.ProductRatePlanWithCharge plan : this.productRatePlans) {
            if (!plan.name.contains('Jumpstart')
                    || !usUser
                    || !Settings__c.getOrgDefaults().DisableJumpstartForUSUsers__c) {
                ratePlanIdByName.put(plan.name, plan.productRatePlanId);
            }
        }
        final List<String> ratePlanNames = new List<String>(ratePlanIdByName.keySet());
        if (!selectedProduct.name.endsWith(' Remote') && !selectedProduct.name.endsWith(' Onsite')) {
            ratePlanNames.sort();
        }
        for (String ratePlanName : ratePlanNames) {
            options.add(new SelectOption(ratePlanIdByName.get(ratePlanName), ratePlanName));
        }
        return options;
    }

    public PageReference next() {
        this.validationResults.clear();
        initZProducts();
        if (!nextStepHandler()) {
            return null;
        }
        this.step = getNextStepName();
        return null;
    }

    protected abstract Boolean nextStepHandler();

    public PageReference previous() {
        if (String.isNotBlank(this.returnUrl)) {
            return new PageReference(this.returnUrl);
        }
        List<String> stepOrder = getStepsOrder();
        if (stepOrder != null && stepOrder.size() > 0 && this.step == stepOrder.get(0)) {
            return goToOpportunity();
        }
        this.validationResults.clear();
        previousStepHandler();
        if (this.step == getProductsTableStepName()) {
            cancelNewProduct();
            resetQuoteProducts(false);
        }
        this.step = getPreviousStepName();
        return null;
    }

    protected abstract void previousStepHandler();

    protected Boolean validateQuoteDetails() {
        Boolean isNameNotFilled = String.isBlank(this.wQuote.name);
        Boolean isCompanyNotFilled = String.isBlank(this.wQuote.companyName);
        Boolean isEffectiveDateNotFilled = this.wQuote.effectiveDate == null;
        Boolean isValidUntilNotFilled = this.wQuote.validUntil == null;
        Boolean isInvoiceDateNotFilled = this.wQuote.invoiceDate == null;
        Boolean isTermNotFilled = this.wQuote.newTerm == null;
        Boolean isNumberOfTeamsNotSelected = this.wQuote.numberOfTeams == -1;

        if (isNameNotFilled || isCompanyNotFilled || isEffectiveDateNotFilled || isValidUntilNotFilled
                || isTermNotFilled || isInvoiceDateNotFilled || isNumberOfTeamsNotSelected) {
            validationResults.addError('Please fill out all required fields.');
            return false;
        }

        if (this.wQuote.name.length() > QuoteService.QUOTE_NAME_LENGTH) {
            validationResults.addError(StringUtils.format('Maximum Qute Name length is {0}.', QuoteService.QUOTE_NAME_LENGTH));
            return false;
        }

        Date minEffectiveDate = this.quoteDateSrv.getMinEffectiveDate(this.wQuote);
        Date maxEffectiveDate = this.quoteDateSrv.getMaxEffectiveDate(this.wQuote);
        if (this.wQuote.effectiveDate < minEffectiveDate || this.wQuote.effectiveDate > maxEffectiveDate) {
            addDateValidationError(wQuote.getEffectiveDateLabel(), minEffectiveDate, maxEffectiveDate);
            return false;
        }

        Date minValidUntil = this.quoteDateSrv.getMinValidUntil();
        Date maxValidUntil = this.quoteDateSrv.getMaxValidUntil(this.wQuote);
        if (this.wQuote.validUntil < minValidUntil || this.wQuote.validUntil > maxValidUntil) {
            addDateValidationError('Valid Until', minValidUntil, maxValidUntil);
            return false;
        }

        if (this.wQuote.newTerm < 1 || this.wQuote.newTerm > 60) {
            validationResults.addError('Term is invalid. Possible values from 1 to 60.');
            return false;
        }

        final Date minInvoiceDate = this.quoteDateSrv.getMinInvoiceDate(this.wQuote.effectiveDate);
        final Date maxInvoiceDate = this.quoteDateSrv.getMaxInvoiceDate(this.wQuote.effectiveDate);
        if (this.wQuote.invoiceDate < minInvoiceDate || this.wQuote.invoiceDate > maxInvoiceDate) {
            addDateValidationError('Invoice Date', minInvoiceDate, maxInvoiceDate);
            return false;
        }
        return true;
    }

    protected void addDateValidationError(String dateName, Date startDate, Date endDate) {
        List<String> messagePattern = new List<String>();
        messagePattern.add(dateName);
        messagePattern.add('should be');
        if (startDate != null) {
            messagePattern.add('greater than {0}');
        }
        if (messagePattern.size() == 3 && endDate != null) {
            messagePattern.add('and');
        }
        if (endDate != null) {
            messagePattern.add('less than {1}');
        }
        this.validationResults.addError(StringUtils.format(String.join(messagePattern, ' '), startDate, endDate));
    }

    public PageReference saveQuoteDetails() {
        this.validationResults.clear();
        if (!validateQuoteDetails()) {
            return null;
        }
        try {
            if (getIsNeedResetProductState()) {
                resetQuoteProducts(true);
                this.quoteSrv.deleteQuoteItemByIds(this.quoteItemIdsForDelete);
                this.quoteItemIdsForDelete.clear();
            }
            this.wQuote = quoteSrv.upsertQuote(this.wQuote);
            quoteSrv.upsertQuoteItems(this.wQuote.items);
        } catch (LogicException logicExp) {
            this.validationResults.addError(logicExp.getMessage());
            return null;
        }
        return getViewQuotePageRedirect();
    }

    public PageReference saveQuote() {
        if (save()) {
            return getViewQuotePageRedirect();
        }
        return null;
    }

    private PageReference getViewQuotePageRedirect() {
        PageReference quoteViewPage = Page.ViewQuote;
        quoteViewPage.getParameters().put(RequestParam.ID_PARAM, this.wQuote.id);
        quoteViewPage.setRedirect(true);
        return quoteViewPage;
    }

    private Boolean save() {
        validateAndSetApprovals();
        if (this.validationResults.getIsNotValid()) {
            return false;
        }
        try {
            if (wQuote.getIsSubscription()
                    && wQuote.getOutbound() == false
                    && String.isBlank(wQuote.id)) {
                final QuoteService.ZuoraAccountResult zuoraAccountResult = this.quoteSrv.sendNewQuoteToWrike(this.wQuote);
                this.wQuote.zuoraAccountId = zuoraAccountResult.getZuoraAccountId();
                this.wQuote.dataCenter = zuoraAccountResult.getDataCenter();
            }
            final Boolean wasPrimary = this.wQuote.primary;
            this.wQuote = this.quoteSrv.upsertQuoteWithProducts(this.wQuote);
            if (wasPrimary == true && this.wQuote.primary == false) {
                this.opportunityProductSrv.deleteOpportunityLineItems(this.wQuote);
            }
            this.quoteSrv.deleteQuoteItemByIds(this.quoteItemIdsForDelete);
            this.quoteItemIdsForDelete.clear();
            return true;
        } catch(final LogicException logicExp) {
            this.validationResults.addError(logicExp.getMessage());
        }
        return false;
    }

    private void validateAndSetApprovals() {
        quoteValidationSrv.updateSummaryFields(this.wQuote);

        this.validationResults.clear();
        final QuoteValidator quoteValidator = QuoteValidatorService.getInstance().createValidator(wQuote);
        if (Settings__c.getInstance().Product2QuoteValidator__c == true) {
            for (String message : quoteValidator.getErrorMessages()) {
                this.validationResults.addError(message);
            }
        } else {
            this.validationResults.addError(quoteValidationSrv.validateQuoteProductsBeforeSave(this.wQuote));
        }
        if (!getQuoteHasCustomDeployment()) {
            final List<String> missingDeploymentNames = quoteValidator.getMissingDeploymentNames();
            this.wQuote.missingDeployments = missingDeploymentNames.isEmpty()
                                             ? null
                                             : String.join(missingDeploymentNames, ', ').left(255);
        }
        this.wQuote.maxDeploymentDiscount = quoteValidator.getMaxDiscount();
        this.wQuote.additionalCollaboratorDiscount = quoteValidator.getAdditionalCollaboratorDiscount();
        this.wQuote.hasWrikeIntegrate = quoteValidator.getHasAddedWrikeIntegrate();
        this.wQuote.hasFTE = quoteValidator.getHasFTE();
        this.wQuote.hasWrikePerformancePackage = quoteValidator.getHasWrikePerformancePackage();
        this.wQuote.hasOldWrikeIntegrateAddon = quoteValidator.getHasOldWrikeIntegrateAddon();
        this.wQuote.hasCustomDeployment = quoteValidator.getHasCustomDeployment();
        this.wQuote.noPSIntegrate = quoteValidator.getHasAddedWrikeIntegrate() && !quoteValidator.getHasWrikeIntegratePS();
        this.wQuote.hasUnlimitedCollaborators = quoteValidator.getHasUnlimitedCollaborators();
        this.wQuote.premiumSupportMismatch = getPremiumSupportMismatch();
        this.wQuote.selfStartDiscount = quoteValidator.getSelfStartDiscount();
        this.wQuote.smartStartDiscount = quoteValidator.getSmartStartDiscount();
        this.wQuote.wrikeIntegrateEnhancedDiscount = quoteValidator.getWrikeIntegrateEnhancedDiscount();
    }

    public PageReference goToOpportunity() {
        PageReference opportunityPage = new PageReference('/' + this.wQuote.opportunityId);
        opportunityPage.setRedirect(true);
        return opportunityPage;
    }

    protected WrikeQuote setValues(WrikeQuote quote, OpportunityDto opportunityDtoForQuote) {
        quote.opportunityId = opportunityDtoForQuote.id;
        quote.opportunityName = opportunityDtoForQuote.Name;
        quote.name = opportunityDtoForQuote.Name;
        quote.accountId = opportunityDtoForQuote.accountId;
        quote.companyName = opportunityDtoForQuote.accountName;
        quote.wrikeAccountId = opportunityDtoForQuote.wrikeAccountId;
        quote.legalTerms = (String)Schema.SObjectType.Quote__c.fields.LegalTerms__c.getDefaultValue();
        quote.verticalSegment = opportunityDtoForQuote.verticalSegment;
        return quote;
    }

    protected void initZProducts() {
        if (this.productCatalogMap == null) {
            this.productCatalogMap = zuoraProductSrv.getZuoraProductCatalog(wQuote.quoteCurrency);
        }
    }

    protected String getNextStepName() {
        List<String> stepsOrder = getStepsOrder();
        if (stepsOrder == null || stepsOrder.isEmpty()) {
            throw new LogicException('Steps order do not determined.');
        }
        for (Integer stepIndex = 0; stepIndex < stepsOrder.size(); stepIndex++) {
            String currentStep = stepsOrder.get(stepIndex);
            if (this.step == currentStep) {
                Integer nextStepIndex = stepIndex + 1;
                if (nextStepIndex < stepsOrder.size()) {
                    return stepsOrder[nextStepIndex];
                } else {
                    return currentStep;
                }
            }
        }
        return stepsOrder[0];
    }

    protected String getPreviousStepName() {
        List<String> stepsOrder = getStepsOrder();
        if (stepsOrder == null || stepsOrder.isEmpty()) {
            throw new LogicException('Steps order do not determined.');
        }
        for (Integer stepIndex = 0; stepIndex < stepsOrder.size(); stepIndex++) {
            String currentStep = stepsOrder.get(stepIndex);
            if (this.step == currentStep) {
                Integer previousStepIndex = stepIndex - 1;
                if (previousStepIndex < stepsOrder.size()) {
                    return stepsOrder[previousStepIndex];
                } else {
                    return currentStep;
                }
            }
        }
        return stepsOrder[0];
    }

    private ZuoraProductCatalogService.ProductRatePlanWithCharge getRatePlanById(List<ZuoraProductCatalogService.ProductRatePlanWithCharge> ratePlans, String ratePlanId) {
        for (ZuoraProductCatalogService.ProductRatePlanWithCharge currentRatePlan : ratePlans) {
            if (currentRatePlan.productRatePlanId == ratePlanId) {
                return currentRatePlan;
            }
        }
        return null;
    }

    private ZuoraProductCatalogService.ProductRatePlanWithCharge getSelectedRatePlan() {
        return getRatePlanById(this.productRatePlans, this.newProduct.zuoraProductRatePlanId);
    }

    private Boolean getQuoteHasCustomDeployment() {
        for (WrikeQuoteItem item : this.wQuote.items) {
            if (item.product.product2Id == Settings__c.getOrgDefaults().CustomDeploymentId__c) {
                return true;
            }
        }
        return false;
    }

    private void addAutoDeployments(final WrikeQuoteItem item) {
        final WrikeProduct wrikeProduct = productSrv.findProductById(item.product.product2Id);
        final Integer quantity = item.product.quantity;
        if (this.wQuote.numberOfTeams != 0 || (wrikeProduct.isPremium() && this.pro200Allowed && quantity <= 200)) {
            final Integer numberOfTeams = this.wQuote.numberOfTeams;
            if ((wrikeProduct.isSeat() && numberOfTeams == 6 || quantity > 200) && !getQuoteHasCustomDeployment()) {
                final WrikeProduct customDeployment =
                        productSrv.findProductById(Settings__c.getOrgDefaults().CustomDeploymentId__c);
                addDeployment(customDeployment, null);
            } else if (wrikeProduct.isWrikeIntegrate() || wrikeProduct.isWrikeIntegrateStandard()) {
                this.validationResults.addWarn('Please add appropriate Integrate Services package.');
            } else {
                final List<WrikeProduct> requiredDeployments =
                        productSrv.getProductRequiredDeployments(wrikeProduct, this.wQuote);
                for (WrikeProduct deployment : requiredDeployments) {
                    addDeployment(deployment, item.uid);
                }
            }
        }
    }

    private void addDeployment(final WrikeProduct deployment, final String parentItemUID) {
        this.newProduct = new WrikeQuoteProduct();
        this.newProduct.zuoraProductId = deployment.zuoraProductId;
        this.newProduct.zuoraProductRatePlanId = deployment.zuoraRatePlanId;
        this.newProduct.serviceType = deployment.zuoraServiceType;
        this.productRatePlans = this.productCatalogMap.get(deployment.zuoraProductId).plans;
        removeDuplicatedProducts(this.newProduct, false);
        populatePrice();
        final WrikeQuoteItem deploymentItem =
                this.wQuote.addItem(WrikeQuoteItem.State.ADDED, this.newProduct);
        deploymentItem.parentItemUID = parentItemUID;
        this.newProduct = null;
    }

    private void resetRelatedDeployments(final String parentItemUID) {
        for (WrikeQuoteItem item : this.wQuote.getImplementationItems()) {
            if (item.parentItemUID == parentItemUID) {
                WrikeQuoteItem wrikeQuoteItemForDelete = this.wQuote.items.remove(this.wQuote.items.indexOf(item));
                if (wrikeQuoteItemForDelete.id != null) {
                    quoteItemIdsForDelete.add(wrikeQuoteItemForDelete.id);
                }
            }
        }
    }

    private void resetDeploymentsWithoutRequiredProduct() {
        for (WrikeQuoteItem item : this.wQuote.getImplementationItems()) {
            final WrikeProduct product = productSrv.findProductById(item.product.product2Id);
            if (product.requiredProductServiceType != null
                    && this.wQuote.getAddedItemByServiceType(product.requiredProductServiceType) == null) {
                WrikeQuoteItem wrikeQuoteItemForDelete = this.wQuote.items.remove(this.wQuote.items.indexOf(item));
                if (wrikeQuoteItemForDelete.id != null) {
                    quoteItemIdsForDelete.add(wrikeQuoteItemForDelete.id);
                }
            }
        }
    }

    private void linkDeploymentWithExistingSeatProduct(final WrikeQuoteItem deploymentItem) {
        final WrikeProduct deploymentProduct = productSrv.findProductById(deploymentItem.product.product2Id);
        for (WrikeQuoteItem item : this.wQuote.getNonImplementationItems()) {
            if (deploymentProduct.maxNumberOfTeams != null && item.product.isSeatProduct()) {
                resetRelatedDeployments(item.uid);
                deploymentItem.parentItemUID = item.uid;
            }
        }
    }

    private void linkDeploymentWithExistingParentProduct(final WrikeQuoteItem deploymentItem) {
        final WrikeProduct deploymentProduct = productSrv.findProductById(deploymentItem.product.product2Id);
        for (WrikeQuoteItem item : this.wQuote.getNonImplementationItems()) {
            if (deploymentProduct.parentProductId == item.product.product2Id) {
                deploymentItem.parentItemUID = item.uid;
            }
        }
    }

    private Decimal calculatePriceByUserProducts() {
        Decimal newPrice = 0;
        Integer billingPeriod = null;
        for (WrikeQuoteItem item : this.wQuote.items) {
            if ((item.product.isSeatProduct()
                    || item.product.isLicenseSeatsMatchingProduct())
                    && !item.getIsRemoved()) {
                newPrice += 0.1 * item.product.getBillingPeriodEffectivePrice();
                billingPeriod = item.product.getBillingPeriodInMonth();
            }
        }
        final Decimal floor = 300 * billingPeriod;
        return newPrice > floor ? newPrice.setScale(2, RoundingMode.HALF_UP) : floor;
    }

    public Boolean getPremiumSupportMismatch() {
        final WrikeQuoteItem premiumSupportItem = this.wQuote.getExistingItemByServiceType('PremiumSupport');
        return premiumSupportItem != null
                && this.wQuote.hasAddedOrRemovedUserProducts()
                && (premiumSupportItem.product.effectivePrice < calculatePriceByUserProducts()
                        || premiumSupportItem.product.effectivePrice <  300 * premiumSupportItem.product.getBillingPeriodInMonth());
    }

    private Boolean getQuoteHasWfMPerformance() {
        Boolean wfmPackage = false;
        Boolean wrikeAnalyze = false;
        Boolean marketingInsightsStandard = false;
        for (WrikeQuoteItem item : this.wQuote.items) {
            if (item.getIsAdded()) {
                if (zuoraProductSrv.isWfmPackage(item.product.serviceType)) {
                    wfmPackage = true;
                }
                if (item.product.isWrikeAnalyze()) {
                    wrikeAnalyze = true;
                }
                if (item.product.isMarketingInsightsStandard()) {
                    marketingInsightsStandard = true;
                }
            }
        }
        return wrikeAnalyze && wfmPackage && marketingInsightsStandard;
    }

    private Boolean getQuoteHasWfPSPerformance() {
        Boolean wfpsPackage = false;
        Boolean wrikeAnalyze = false;
        Boolean wrikeIntegrateStandard = false;
        for (WrikeQuoteItem item : this.wQuote.items) {
            if (item.getIsAdded()) {
                if (zuoraProductSrv.isWfpsPackage(item.product.serviceType)) {
                    wfpsPackage = true;
                }
                if (item.product.isWrikeAnalyze()) {
                    wrikeAnalyze = true;
                }
                if (item.product.isWrikeIntegrateStandard()) {
                    wrikeIntegrateStandard = true;
                }
            }
        }
        return wrikeAnalyze && wfpsPackage && wrikeIntegrateStandard;
    }

    public Boolean getNeedRecalculateSoftBundleDiscount() {
        for (WrikeQuoteItem item : this.wQuote.items) {
            if (item.getIsAdded() && needRecalculateProduct(item.product)) {
                return true;
            }
        }
        return false;
    }

    public void recalculateSoftBundlePrice() {
        for (WrikeQuoteItem item : this.wQuote.items) {
            final WrikeQuoteProduct product = item.product;
            if (item.getIsAdded() && needRecalculateProduct(product)) {
                recalculateProductSoftBundleDiscount(product);
                product.softBundleDiscountApplied = !product.softBundleDiscountApplied;
            }
        }
    }

    private Boolean needRecalculateProduct(final WrikeQuoteProduct product) {
        if (product.isWrikeIntegrateStandard()
                && (this.hasWfPSPerformance && !product.softBundleDiscountApplied
                        || !this.hasWfPSPerformance && product.softBundleDiscountApplied)) {
            return true;
        }
        if (product.isMarketingInsightsStandard()
                && (this.hasWfMPerformance && !product.softBundleDiscountApplied
                        || !this.hasWfMPerformance && product.softBundleDiscountApplied)) {
            return true;
        }
        if (product.isWrikeAnalyze()
                && ((this.hasWfMPerformance || this.hasWfPSPerformance) && !product.softBundleDiscountApplied
                        || !this.hasWfMPerformance && !this.hasWfPSPerformance && product.softBundleDiscountApplied)) {
            return true;
        }
        return false;
    }

    private void recalculateProductSoftBundleDiscount(final WrikeQuoteProduct product) {
        final Decimal newListPrice = product.softBundleDiscountApplied
                                     ? product.getListPrice() + 5 * product.getBillingPeriodInMonth() * product.quantity
                                     : product.getListPrice() - 5 * product.getBillingPeriodInMonth() * product.quantity; // from catalog ?
        product.billingIntervalListPrice = newListPrice;
        if (this.softBundleRecalculateOption == 1) {
            product.calculateDiscountByPrice();
        } else if (this.softBundleRecalculateOption == 2) {
            product.calculatePriceByDiscount();
        }
    }

    public void changeSoftBundleRecalculateOption() {
        this.previewSoftBundleProducts.clear();
        for (WrikeQuoteItem item : this.wQuote.items) {
            final WrikeQuoteProduct product = item.product;
            if (item.getIsAdded() && needRecalculateProduct(product)) {
                final WrikeQuoteProduct clonedProduct = (WrikeQuoteProduct)product.clone();
                recalculateProductSoftBundleDiscount(clonedProduct);
                this.previewSoftBundleProducts.add(clonedProduct);
            }
        }
    }

    public Boolean getHasWfMPerformance() {
        return this.hasWfMPerformance;
    }

    public Boolean getHasWfPSPerformance() {
        return this.hasWfPSPerformance;
    }
}
public class QuoteValidatorImpl implements QuoteValidator {

    private List<WrikeProduct> addedLicenseProducts = new List<WrikeProduct>();
    private Set<String> licenseProductServiceTypes = new Set<String>();

    private Boolean hasWfPSPackage = false;
    private Boolean hasWrikePerformancePackage = false;
    private Boolean hasAddedWrikeIntegrate = false;
    private Boolean hasOldWrikeIntegrateAddon = false;
    private Boolean hasWfMPackage = false;
    private Boolean hasFTE = false;
    private Boolean hasCustomDeployment = false;
    private Boolean hasWrikeIntegratePS = false;
    private Boolean hasUnlimitedCollaborators = false;

    private Set<String> repeatedProducts = new Set<String>();
    private Map<String, String> includedInPackageProducts = new Map<String, String>();
    private Map<String, String> incompatibleProducts = new Map<String, String>();
    private Set<WrikeProduct> unavailableProducts = new Set<WrikeProduct>();

    private Integer addedProfessionalSeats = null;
    private List<WrikeQuoteProduct> productsWithExceededDiscount = new List<WrikeQuoteProduct>();
    private Set<Integer> billingPeriods = new Set<Integer>();
    private List<WrikeQuoteProduct> productNotCorrespondQuoteTerm = new List<WrikeQuoteProduct>();
    private Boolean licenseQuantityInvalid = false;
    private Boolean professionalUsersLimitExceeded = false;
    private Map<String, Integer> productQuantityMap = new Map<String, Integer>();

    private List<WrikeProduct> requiredDeployments = new List<WrikeProduct>();
    private List<WrikeProduct> deployments = new List<WrikeProduct>();
    private Decimal maxDeploymentDiscount = 0;
    private Decimal additionalCollaboratorDiscount = null;
    private Decimal selfStartDiscount = null;
    private Decimal smartStartDiscount = null;
    private Decimal wrikeIntegrateEnhancedDiscount = null;

    private final ProductService productSrv = ProductService.getInstance();

    public QuoteValidatorImpl(final WrikeQuote quote) {
        for (WrikeQuoteItem item : quote.items) {
            if (!item.getIsRemoved()) {
                final WrikeQuoteProduct product = item.product;
                final WrikeProduct wrikeProduct = productSrv.findProductById(product.product2Id);

                if (wrikeProduct.isWfPSPackage()) {
                    this.hasWfPSPackage = true;
                }
                if (wrikeProduct.isWrikePerformancePackage()) {
                    this.hasWrikePerformancePackage = true;
                }
                if (wrikeProduct.isOldWrikeIntegrate()) {
                    this.hasOldWrikeIntegrateAddon = true;
                }
                if (wrikeProduct.isFTE()) {
                    this.hasFTE = true;
                }
                if (wrikeProduct.isWfMPackage()) {
                    this.hasWfMPackage = true;
                }
                if ((wrikeProduct.isSelfStart() || wrikeProduct.isQuickStart())
                        && (this.selfStartDiscount == null
                                || product.discount > this.selfStartDiscount)) {
                    this.selfStartDiscount = product.discount;
                }
                if (wrikeProduct.isSmartStart()
                        && (this.smartStartDiscount == null
                                || product.discount > this.smartStartDiscount)) {
                    this.smartStartDiscount = product.discount;
                }
                if (wrikeProduct.isWrikeIntegrateEnhanced()
                        && (this.wrikeIntegrateEnhancedDiscount == null
                                || product.discount > this.wrikeIntegrateEnhancedDiscount)) {
                    this.wrikeIntegrateEnhancedDiscount = product.discount;
                }
                if (wrikeProduct.isCustomDeployment()) {
                    this.hasCustomDeployment = true;
                }
                if (wrikeProduct.isDeployment()) {
                    this.deployments.add(wrikeProduct);
                    if (product.discount > this.maxDeploymentDiscount) {
                        this.maxDeploymentDiscount = product.discount;
                    }
                }
                if (SettingsProvider.isWrikeIntegratePS(product.name, product.zuoraProductRatePlanChargeName)) {
                    this.hasWrikeIntegratePS = true;
                }

                compareProductWithOthers(wrikeProduct, quote.items);

                if (item.getIsAdded()) {
                    if(!wrikeProduct.isPremium()) {
                        this.requiredDeployments.addAll(productSrv.getProductRequiredDeployments(wrikeProduct, quote));
                    }

                    if (wrikeProduct.isAdditionalCollaboratorLicenses()
                            && (this.additionalCollaboratorDiscount == null
                                    || product.discount > this.additionalCollaboratorDiscount)) {
                        this.additionalCollaboratorDiscount = product.discount;
                    }
                    if (wrikeProduct.isWrikeIntegrate()
                            || wrikeProduct.isWrikeIntegrateStandard()
                            || wrikeProduct.isWrikePerformancePackage()) {
                        this.hasAddedWrikeIntegrate = true;
                    }
                    if (wrikeProduct.isUnlimitedCollaborators()) {
                        this.hasUnlimitedCollaborators = true;
                    }
                }

                final Decimal maxDiscount = product.getMaxDiscount();
                if (maxDiscount != null && product.discount > maxDiscount) {
                    this.productsWithExceededDiscount.add(product);
                }

                if (wrikeProduct.isDeployment() && product.discount > maxDiscount) {
                    maxDiscount = product.discount;
                }

                if (wrikeProduct.isSeat()) {
                    this.licenseProductServiceTypes.add(wrikeProduct.zuoraServiceType);

                    if (item.getIsAdded()) {
                        this.addedLicenseProducts.add(wrikeProduct);
                        if(wrikeProduct.isPremium()) {
                            this.addedProfessionalSeats = product.quantity;
                        }
                    }

                    final Boolean isAnyQuoteTypeOrRenewalWithChangedQuantity =
                            quote.getIsSubscription() || quote.getIsAmendment() ||
                            (quote.getIsRenewal() && product.isQuantityChanged());
                    if (product.quantity > 15 && wrikeProduct.isPremium() &&
                            isAnyQuoteTypeOrRenewalWithChangedQuantity &&
                            !SettingsProvider.isUnlimitedProfessionalLicense()) {
                        this.professionalUsersLimitExceeded = true;
                    }

                    final Boolean isQuantityValid = Math.mod(product.quantity, 5) == 0;
                    if (!isQuantityValid && !SettingsProvider.isCustomUserLicenseTiers() &&
                            isAnyQuoteTypeOrRenewalWithChangedQuantity) {
                        licenseQuantityInvalid = true;
                    }
                }
                if (item.product.isSeatProduct() || item.product.isLicenseSeatsMatchingProduct()) {
                    final String productId = item.product.zuoraProductId;
                    final Integer quantity = this.productQuantityMap.get(productId);
                    if (quantity != null) {
                        this.productQuantityMap.put(productId, quantity + item.product.quantity);
                    } else {
                        this.productQuantityMap.put(productId, item.product.quantity);
                    }
                }
                if (product.getIsRecurrent()) {
                    if (quote.newTerm < product.getBillingPeriodInMonth()) {
                        this.productNotCorrespondQuoteTerm.add(product);
                    }
                    this.billingPeriods.add(product.getBillingPeriodInMonth());
                }
            }
        }
        if (licenseProductServiceTypes.size() == 1) {
            final String licenseServiceType = new List<String>(licenseProductServiceTypes).get(0);
            for (WrikeQuoteItem item : quote.items) {
                final WrikeProduct wrikeProduct = productSrv.findProductById(item.product.product2Id);
                if (!wrikeProduct.isSeat() && !wrikeProduct.isAvailablePlan(licenseServiceType)) {
                    this.unavailableProducts.add(wrikeProduct);
                }
            }
        }
    }

    public List<String> getErrorMessages() {
        final Set<String> messages = new Set<String>();

        if (licenseProductServiceTypes.isEmpty()) {
            messages.add('You should have at least one licence product in the quote.');
        }

        if (licenseProductServiceTypes.size() > 1) {
            messages.add('You can\'t have different license products per Zuora subscription.');
        }

        if (addedLicenseProducts.size() > 1) {
            messages.add('Please do not add multiple base license products.');
        }

        for (WrikeProduct unavailableProduct : unavailableProducts) {
            messages.add(unavailableProduct.name + ' is only available for ' +
                    unavailableProduct.getEnabledLicensesAsString() + ' licenses.');
        }

        for (String productName : repeatedProducts) {
            messages.add(productName + ' is repeated.');
        }

        for (String productName : includedInPackageProducts.keySet()) {
            final String packageName = includedInPackageProducts.get(productName);
            messages.add(productName + ' is already included in ' + packageName + '.');
        }

        for (String productName : incompatibleProducts.keySet()) {
            final String otherProductName = incompatibleProducts.get(productName);
            messages.add(productName + ' can not be combined with ' + otherProductName + '.');
        }

        for (WrikeQuoteProduct product : productsWithExceededDiscount) {
            messages.add(product.name + ' can not be discounted more than ' + product.getMaxDiscount() + '%');
        }

        if (hasWrikePerformancePackage && !hasWfPSPackage && !hasWfMPackage) {
            messages.add('Wrike Performance Package can only be included if WfPS or WfM is included ' +
                    'or has already been purchased.');
        }

        if (billingPeriods.size() > 1) {
            messages.add('Billing frequency (selected in Rate Plan) should be the same ' +
                    'for all recurring product in the quote.');
        }

        if (licenseQuantityInvalid) {
            messages.add('Please enter a valid quantity for the license product. ' +
                    'Possible options are increments of 5 (5, 10, 15, 20, 25 etc.).');
        }

        if (professionalUsersLimitExceeded) {
            messages.add('We do not sell professional in tiers higher than 15 users. ' +
                    'Please upgrade to enterprise if you would like to send a quote for more than 15 users.');
        }

        for (WrikeQuoteProduct product : productsWithExceededDiscount) {
            messages.add(product.name + ' can not be discounted more than ' + product.getMaxDiscount() + '%');
        }

        for (WrikeQuoteProduct product : productNotCorrespondQuoteTerm) {
            messages.add('Billing frequency of ' + product.name + ' (selected in Rate Plan) ' +
                    'doesn\'t correspond to initial or renewal contract term.');
        }

        if (new Set<Integer>(productQuantityMap.values()).size() != 1) {
            messages.add('Quantity mismatch for add-on seats.');
        }

        return new List<String>(messages);
    }

    public List<WrikeProduct> getRequiredDeployments() {
        return this.requiredDeployments;
    }

    public Decimal getMaxDiscount() {
        return this.maxDeploymentDiscount;
    }

    public Decimal getAdditionalCollaboratorDiscount() {
        return this.additionalCollaboratorDiscount;
    }

    public Decimal getSelfStartDiscount() {
        return this.selfStartDiscount;
    }

    public Decimal getSmartStartDiscount() {
        return this.smartStartDiscount;
    }

    public Decimal getWrikeIntegrateEnhancedDiscount() {
        return this.wrikeIntegrateEnhancedDiscount;
    }

    public Boolean getHasUnlimitedCollaborators() {
        return this.hasUnlimitedCollaborators;
    }

    public List<String> getMissingDeploymentNames() {
        final Boolean pro200Allowed = UserService.getInstance().isUsUser(UserInfo.getUserId())
                || Settings__c.getOrgDefaults().EnablePro200Globally__c;
        final List<String> missingDeploymentNames = new List<String>();
        if(pro200Allowed && this.addedProfessionalSeats > 20) {
            final String missingDeployment = findMissingProfessionalLicenseDeployment(this.addedProfessionalSeats);
            if(missingDeployment != null) {
                missingDeploymentNames.add(missingDeployment);
            }
        }
        for (WrikeProduct deployment : this.requiredDeployments) {
            if (!hasRequiredDeployment(deployment) &&
                    !SettingsProvider.isWrikeIntegratePS(deployment.zuoraProductName, deployment.zuoraRatePlanName)) {
                missingDeploymentNames.add(deployment.name);
            }
        }
        return missingDeploymentNames;
    }

    private Boolean hasRequiredDeployment(final WrikeProduct requiredDeployment) {
        for (WrikeProduct quoteDeployment : this.deployments) {
            if (quoteDeployment.maxSeats >= requiredDeployment.maxSeats) {
                if (requiredDeployment.zuoraRatePlanId == quoteDeployment.zuoraRatePlanId) {
                    return true;
                }
                if (requiredDeployment.zuoraProductName.endsWith(' Remote')
                        && quoteDeployment.zuoraProductName.endsWith(' Onsite')) {
                    return true;
                }
                if (quoteDeployment.zuoraProductId == requiredDeployment.zuoraProductId
                        && requiredDeployment.maxNumberOfTeams != null) {
                    return true;
                }
                if (requiredDeployment.zuoraRatePlanName.split('Team')[0].split('Corporate')[0]
                        == quoteDeployment.zuoraRatePlanName.split('Team')[0].split('Corporate')[0]) {
                    return true;
                }
            }
        }
        return false;
    }

    private String findMissingProfessionalLicenseDeployment(final Integer seats) {
        for (WrikeProduct quoteDeployment : this.deployments) {
            if(quoteDeployment.matchProfessionalLicenseDeployment(seats, true) >= 0) { // contains a required or a larger deployment
                return null;
            }
        }
        return productSrv.findDeploymentForProLicense(seats)?.name;
    }

    public Boolean getHasAddedWrikeIntegrate() {
        return this.hasAddedWrikeIntegrate;
    }

    public Boolean getHasWrikeIntegratePS() {
        return this.hasWrikeIntegratePS;
    }

    public Boolean getHasCustomDeployment() {
        return this.hasCustomDeployment;
    }

    public Boolean getHasFTE() {
        return this.hasFTE;
    }

    public Boolean getHasWrikePerformancePackage() {
        return this.hasWrikePerformancePackage;
    }
    public Boolean getHasOldWrikeIntegrateAddon() {
        return this.hasOldWrikeIntegrateAddon;
    }
    
    private void compareProductWithOthers(final WrikeProduct wrikeProduct, final List<WrikeQuoteItem> items) {
        Integer repeatedProductCount = 0;
        for (WrikeQuoteItem otherItem : items) {
            final WrikeProduct otherWrikeProduct = productSrv.findProductById(otherItem.product.product2Id);
            if (wrikeProduct != otherWrikeProduct) {
                if (wrikeProduct.includes(otherWrikeProduct)) {
                    includedInPackageProducts.put(otherWrikeProduct.name, wrikeProduct.name);
                }
                if (!wrikeProduct.isCompatible(otherWrikeProduct)) {
                    incompatibleProducts.put(otherWrikeProduct.name, wrikeProduct.name);
                }
            } else {
                repeatedProductCount++;
            }
        }
        if (repeatedProductCount > 1) {
            repeatedProducts.add(wrikeProduct.name);
        }
    }
}
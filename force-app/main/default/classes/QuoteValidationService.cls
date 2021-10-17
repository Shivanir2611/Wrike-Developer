public class QuoteValidationService {

    public static QuoteValidationService getInstance() {
        return (QuoteValidationService)ServiceLocator.getInstance(QuoteValidationService.class);
    }

    private static final String ACCOUNT_STATUS_CANCELED = 'Canceled';

    private ZuoraProductService zuoraProductSrv = ZuoraProductService.getInstance();
    private ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();
    private UserRecordAccessService userRecordAccessSrv = UserRecordAccessService.getInstance();
    private QuoteDateService quoteDateSrv = SubscriptionQuoteDateService.getInstance();

    public QuoteValidationService() {}

    public Result validateQuote(final Quote__c wQuote) {
        if(wQuote.QuoteType__c != WrikeQuote.QuoteType.SUBSCRIPTION_OUTBOUND.name()) {
            if (wQuote.WrikeAccountId__c == null && wQuote.WrikeAccountId__c <= 0) {
                return new Result('INVALID_WRIKE_ACCOUNT_ID', 'Wrike Account Id is not set for the Quote.');
            }
            if (String.isBlank(wQuote.Zuora_Account_Id__c)) {
                return new Result('INVALID_ZUORA_ACCOUNT_ID', 'The quote does not have a related Zuora Account. Please contact the developer team to research the issue.');
            }
        }
        if(wQuote.WrikeAccountId__c > 0 && String.isNotBlank(wQuote.Zuora_Account_Id__c)) {
            final String zuoraAccountValidationResult = validateZuoraAccount(wQuote);
            if (String.isNotBlank(zuoraAccountValidationResult)) {
                return new Result('INVALID_ZUORA_ACCOUNT', zuoraAccountValidationResult);
            }
            final List<ZuoraObject.ZuoraSubscription> subscriptions =
                    zuoraRestQuerySrv.findSubscriptionsByZuoraAccountId(wQuote.Zuora_Account_Id__c);

            final Boolean isAmendmentOrRenewal = wQuote.QuoteType__c == WrikeQuote.QuoteType.AMENDMENT.name()
                    || wQuote.QuoteType__c == WrikeQuote.QuoteType.RENEWAL.name();
            if (isAmendmentOrRenewal) {
                final String subscriptionValidationResult =
                        validateRelatedSubscription(wQuote.Zuora_Account_Id__c, wQuote.Zuora_Subscription_Id__c, subscriptions);
                if (String.isNotBlank(subscriptionValidationResult)) {
                    return new Result('INVALID_ZUORA_SUBSCRIPTION', subscriptionValidationResult);
                }
            } else if (wQuote.QuoteType__c == WrikeQuote.QuoteType.SUBSCRIPTION.name()
                        || wQuote.QuoteType__c == WrikeQuote.QuoteType.SUBSCRIPTION_OUTBOUND.name()) {
                if (!subscriptions.isEmpty()) {
                    return new Result('INVALID_ZUORA_SUBSCRIPTION',
                            StringUtils.format('Active subscription already exist for account with id = {0}.', wQuote.Zuora_Account_Id__c));
                }
            }
        }

        if (wQuote.ValidUntil__c < Date.today()) {
            return new Result('EXPIRED_QUOTE', 'Quote is invalid. Valid until date in the past.');
        }

        final Date minInvoiceDate = quoteDateSrv.getMinInvoiceDate(wQuote.EffectiveDate__c);
        final Date maxInvoiceDate = quoteDateSrv.getMaxInvoiceDate(wQuote.EffectiveDate__c);
        if (wQuote.InvoiceDate__c < minInvoiceDate || wQuote.InvoiceDate__c > maxInvoiceDate) {
            return new Result('INVALID_INVOICE_DATE', 'Invoice date can not be before effective date.');
        }

        Boolean isCurrentUserHasAccessToOpportunity =
            this.userRecordAccessSrv.hasEditAndDeleteAccess(UserInfo.getUserId(), wQuote.Id);
        if (!isCurrentUserHasAccessToOpportunity) {
            return new Result('NO_PERMISSION', 'Insufficient permissions for the Quote record.');
        }

        if (wQuote.Total__c < 0) {
            return new Result('NEGATIVE_TOTAL', 'Total charge amount is negative. Such quotes are not allowed.');
        }

        return new Result(null, null);
    }

    public String validateRelatedSubscription(String zuoraAccountId, String currentSubscriptionId, List<ZuoraObject.ZuoraSubscription> subscriptions) {
        if (subscriptions.isEmpty()) {
            return StringUtils.format('Active subscriptions for account with id = {0} not found.', zuoraAccountId);
        } else if (subscriptions.size() > 1) {
            return StringUtils.format('There are more then 1 active subscriptions for account with id = {0}', zuoraAccountId);
        } else if (String.isNotBlank(currentSubscriptionId) && subscriptions[0].id != currentSubscriptionId) {
            return 'The Quote is out of date. Corresponding Zuora Subscription has different version.';
        }
        if (subscriptions.get(0).isEvergreen()) {
            return 'Zuora Subscription is set to Evergreen. That type is not supported. Please contact the billing team.';
        }
        return null;
    }

    private String validateZuoraAccount(final Quote__c wQuote) {
        final String zuoraAccountId = wQuote.Zuora_Account_Id__c;
        final Decimal wrikeAccountId = wQuote.WrikeAccountId__c;
        final List<ZuoraObject.ZuoraAccount> zuoraAccounts =
                zuoraRestQuerySrv.getZuoraAccounts(zuoraAccountId, wrikeAccountId, ACCOUNT_STATUS_CANCELED);

        if (zuoraAccounts.size() == 0) {
            return StringUtils.format('Zuora Account with id = {0} not found or canceled.', zuoraAccountId);
        }
        final ZuoraObject.ZuoraAccount zAccount = zuoraAccounts[0];
        if (zAccount.id == zuoraAccountId && Decimal.valueOf(zAccount.accountNumber) != wrikeAccountId) {
            return StringUtils.format('Zuora Account with id = {0} is related to different Wrike Account with id = {1}.',
                zuoraAccountId, wrikeAccountId);
        }
        if (zAccount.id != zuoraAccountId && Decimal.valueOf(zAccount.accountNumber) == wrikeAccountId) {
            return StringUtils.format('Wrike Account with id = {0} is related to different Zuora Account with id = {1}.',
                wrikeAccountId, zuoraAccountId);
        }
        if (zAccount.status == 'Active' && zAccount.currencyCode != wQuote.CurrencyIsoCode) {
            return StringUtils.format(
					'Currency of the quote ({0}) does not match the existing Zuora Account ({1}). Please create a new Quote.',
                    wQuote.CurrencyIsoCode, zAccount.currencyCode);
        }
        return null;
    }

    public void updateSummaryFields(final WrikeQuote wQuote) {
        wQuote.licenseDiscount = null;
        wQuote.deploymentDiscount = null;
        wQuote.resourceManagementDiscount = null;
        wQuote.deploymentName = null;
        wQuote.proofingAddonQuantity = null;
        wQuote.advancedFeatureAddonQuantity = null;
        wQuote.newProductName = null;
        wQuote.newQuantity = 0;
        wQuote.newPricePerUserPerMonth = null;
        wQuote.oldProductName = null;
        wQuote.oldQuantity = null;
        wQuote.oldPricePerUserPerMonth = null;
        wQuote.wfmDiscount = null;
        wQuote.wfpsDiscount = null;
        wQuote.wrikePerformancePackageDiscount = null;
        wQuote.projectSyncsDiscount = null;
        wQuote.wrikeAnalyzeDiscount = null;
        wQuote.wrikeIntegrateDiscount = null;
        wQuote.wrikeLockDiscount = null;
        wQuote.wrikeProofDiscount = null;
        wQuote.wrikePublishDiscount = null;
        wQuote.bronzeCertificationDiscount = null;
        wQuote.silverCertificationDiscount = null;

        final List<WrikeQuoteProduct> licenseProducts = new List<WrikeQuoteProduct>();
        final List<WrikeQuoteProduct> addedLicenseProducts = new List<WrikeQuoteProduct>();
        final List<WrikeQuoteProduct> oldLicenseProducts = new List<WrikeQuoteProduct>();
        Decimal deploymentPrice = -1;
        wQuote.baseLicenseMrr = 0;
        wQuote.userDeltaMrr = 0;

        Decimal newMrr = 0;
        Decimal oldMrr = 0;

        for (WrikeQuoteItem quoteItem : wQuote.items) {
            final WrikeQuoteProduct product = quoteItem.product;
            final Boolean isSeatProduct = product.isSeatProduct();

            if (isSeatProduct || product.isLicenseSeatsMatchingProduct()) {
                if (quoteItem.getIsRemoved()) {
                    wQuote.userDeltaMrr = wQuote.userDeltaMrr - product.mrr;
                } else if (quoteItem.getIsAdded()) {
                    wQuote.userDeltaMrr = wQuote.userDeltaMrr + product.getPricePerUserPerMonth() * product.quantity;
                }
            }

            if (isSeatProduct) {
                if (!quoteItem.getIsRemoved()) {
                    licenseProducts.add(quoteItem.product);
                }
                if (quoteItem.getIsAdded()) {
                    addedLicenseProducts.add(quoteItem.product);
                } else {
                    oldLicenseProducts.add(quoteItem.product);
                }
            }

            if (product.getIsRecurrent()) {
                if (quoteItem.getIsAdded() || quoteItem.getIsExisting()) {
                    newMRR = newMRR + product.getProductMrr();
                }
                if (quoteItem.getIsRemoved() || quoteItem.getIsExisting()) {
                    oldMRR = oldMRR + product.getProductMrr();
                }
            }

            if (quoteItem.getIsAdded()) {
                if (zuoraProductSrv.isProofingAddon(product.serviceType)) {
                    wQuote.proofingAddonQuantity = product.quantity;
                    wQuote.wrikeProofDiscount = product.discount;
                }
                if (zuoraProductSrv.isIntegrateAddon(product.serviceType)) {
                    wQuote.wrikeIntegrateDiscount = product.discount;
                }
                if (zuoraProductSrv.isPerformancePackage(product.serviceType)) {
                    wQuote.wrikePerformancePackageDiscount = product.discount;
                }
                if (zuoraProductSrv.isAdvancedFeatureAddon(product.serviceType)) {
                    wQuote.advancedFeatureAddonQuantity = product.quantity;
                }
                if (zuoraProductSrv.isImplementation(product.serviceType)
                        && product.billingIntervalListPrice > deploymentPrice
                        && !product.zuoraProductRatePlanChargeName.containsIgnoreCase('5 Hours Services Support')) {
                    deploymentPrice = product.billingIntervalListPrice;
                    wQuote.deploymentName = product.zuoraProductRatePlanChargeName;
                    wQuote.deploymentDiscount = product.discount;
                }
                if (zuoraProductSrv.isResourceManagementAddon(product.serviceType)) {
                    wQuote.resourceManagementDiscount = product.discount;
                }
                if (zuoraProductSrv.isWfpsPackage(product.serviceType)) {
                    wQuote.wfpsDiscount = product.discount;
                }
                if (zuoraProductSrv.isWfmPackage(product.serviceType)) {
                    wQuote.wfmDiscount = product.discount;
                }
                if (zuoraProductSrv.isWrikeLockAddon(product.serviceType)) {
                    wQuote.wrikeLockDiscount = product.discount;
                }
                if (zuoraProductSrv.isDAMAddon(product.serviceType)) {
                    wQuote.wrikePublishDiscount = product.discount;
                }
                if (zuoraProductSrv.isBronzeCertification(product.name)) {
                    wQuote.bronzeCertificationDiscount = product.discount;
                }
                if (zuoraProductSrv.isSilverCertification(product.name)) {
                    wQuote.silverCertificationDiscount = product.discount;
                }
                if (zuoraProductSrv.isWrikeAnalyzeAddon(product.serviceType)) {
                    wQuote.wrikeAnalyzeDiscount = product.discount;
                }
                if (zuoraProductSrv.isProjectSyncsAddon(product.serviceType)) {
                    wQuote.projectSyncsDiscount = product.discount;
                }
            }
        }

        for(WrikeQuoteProduct licenseProduct : licenseProducts) {
            wQuote.baseLicenseMrr = wQuote.baseLicenseMrr + licenseProduct.getPricePerUserPerMonth()*licenseProduct.quantity;
            wQuote.newQuantity = wQuote.newQuantity + licenseProduct.quantity;
        }
        if(!oldLicenseProducts.isEmpty()) {
            wQuote.oldQuantity = 0;
            for(WrikeQuoteProduct licenseProduct : oldLicenseProducts) {
                wQuote.oldQuantity = wQuote.oldQuantity + licenseProduct.quantity;
            }
            wQuote.oldProductName = oldLicenseProducts[0].name;
            wQuote.oldPricePerUserPerMonth = oldLicenseProducts[0].effectivePricePerUserPerMonth;
        }
        final WrikeQuoteProduct mainLicenseProduct = addedLicenseProducts.isEmpty()
                                                     ? (licenseProducts.isEmpty() ? null : licenseProducts[0] )
                                                     : addedLicenseProducts[0];
        if(mainLicenseProduct != null) {
            wQuote.newProductName = mainLicenseProduct.name;
            wQuote.newPricePerUserPerMonth = mainLicenseProduct.effectivePricePerUserPerMonth;
            wQuote.licenseDiscount = mainLicenseProduct.discount;
            wQuote.billingPeriodName = mainLicenseProduct.billingPeriodName;
        }

        if (oldMrr != 0) {
            wQuote.priceIncreasePercent = (newMrr / oldMrr - 1) * 100;
        }
    }

    public String validateQuoteProductsBeforeSave(final WrikeQuote wQuote) {
        if (wQuote.hasOnlyExistingProducts() && !wQuote.getIsRenewal()) {
            return 'There are no changes in existing Zuora Subscription.';
        }
        final Boolean pro200Allowed = UserService.getInstance().isUsUser(UserInfo.getUserId())
                || Settings__c.getOrgDefaults().EnablePro200Globally__c;
        final List<WrikeQuoteProduct> licenseProducts = new List<WrikeQuoteProduct>();
        final List<WrikeQuoteProduct> addedLicenseProducts = new List<WrikeQuoteProduct>();
        Integer creativeProductCount = 0;
        Integer billingPeriod = null;
        Boolean proofingAddon = false;
        Boolean wrikeIntegrateAddon = false;
        Boolean wrikeIntegrateStandard = false;
        Boolean wrikeIntegrateEnhanced = false;
        Boolean marketingInsightsEnhanced = false;
        Boolean marketingInsightsStandard = false;
        Boolean wfmPackage = false;
        Boolean wfpsPackage = false;
        Boolean wrikePublishAddon = false;
        Boolean wrikeResourceAddon = false;
        Boolean wrikeLockAddon = false;
        Boolean wrikeAnalyzeAddon = false;
        Boolean wrikePerformancePackage = false;
        Boolean selfStart = false;
        Boolean quickStart = false;
        Boolean smartStart = false;
        Boolean hasDeployments = false;

        for (WrikeQuoteItem quoteItem : wQuote.items) {
            final WrikeQuoteProduct product = quoteItem.product;
            final Boolean isSeatProduct = product.isSeatProduct();

            if(isSeatProduct) {
                if (!quoteItem.getIsRemoved()) {
                    licenseProducts.add(quoteItem.product);
                }
                if (quoteItem.getIsAdded()) {
                    addedLicenseProducts.add(quoteItem.product);
                }
            }

            if(!quoteItem.getIsRemoved()) {
                final Boolean isProofingAddonProduct = zuoraProductSrv.isProofingAddon(product.serviceType);
                final Boolean isPremiumProduct = zuoraProductSrv.isPremium(product.serviceType);
                final Boolean isCreativeProduct = zuoraProductSrv.isCreative(product.serviceType);
                final Decimal maxDiscount = product.getMaxDiscount();

                if(maxDiscount != null && product.discount > maxDiscount) {
                    return product.name + ' can not be discounted more than ' + maxDiscount + '%';
                }
                if (isProofingAddonProduct) {
                    proofingAddon = true;
                }
                if (isCreativeProduct) {
                    creativeProductCount++;
                }
                if(zuoraProductSrv.isWrikeIntegrate(product.name)) {
                    wrikeIntegrateAddon = true;
                }

                if(zuoraProductSrv.isWrikeIntegrateStandard(product.name)) {
                    wrikeIntegrateStandard = true;
                }

                if(zuoraProductSrv.isWrikeIntegrateEnhanced(product.serviceType)) {
                    wrikeIntegrateEnhanced = true;
                }

                if(zuoraProductSrv.isMarketingInsightsStandard(product.serviceType)) {
                    marketingInsightsStandard = true;
                }

                if(zuoraProductSrv.isMarketingInsightsEnhanced(product.serviceType)) {
                    marketingInsightsEnhanced = true;
                }

                if(zuoraProductSrv.isDAMAddon(product.serviceType)) {
                    wrikePublishAddon = true;
                }

                if(zuoraProductSrv.isResourceManagementAddon(product.serviceType)) {
                    wrikeResourceAddon = true;
                }

                if(zuoraProductSrv.isWrikeLockAddon(product.serviceType)) {
                    wrikeLockAddon = true;
                }

                if(zuoraProductSrv.isWrikeAnalyzeAddon(product.serviceType)) {
                    wrikeAnalyzeAddon = true;
                }

                if(zuoraProductSrv.isPerformancePackage(product.serviceType)) {
                   wrikePerformancePackage = true;
                }

                if(zuoraProductSrv.isWfmPackage(product.serviceType)) {
                    wfmPackage = true;
                }

                if(zuoraProductSrv.isWfpsPackage(product.serviceType)) {
                    wfpsPackage = true;
                }

                if(zuoraProductSrv.isImplementation(product.serviceType)) {
                    if(zuoraProductSrv.isSelfStart(product.name)) {
                        selfStart = true;
                    } else if(zuoraProductSrv.isQuickStart(product.name)) {
                        quickStart = true;
                    } else if(zuoraProductSrv.isSmartStart(product.name)) {
                        smartStart = true;
                    }  else {
                        hasDeployments = true;
                    }
                }

                if (isSeatProduct) {
                    final Boolean isAnyQuoteTypeOrRenewalWithChangedQuantity = wQuote.getIsSubscription()
                            || wQuote.getIsAmendment()
                            || (wQuote.getIsRenewal() && product.isQuantityChanged());
                    final Integer maxProUsers = pro200Allowed ? 200 : 15;
                    if (product.quantity > maxProUsers
                            && isPremiumProduct
                            && isAnyQuoteTypeOrRenewalWithChangedQuantity
                            && !SettingsProvider.isUnlimitedProfessionalLicense()
                    ) {
                        return 'We do not sell professional in tiers higher than ' + maxProUsers + ' users. ' +
                                'Please upgrade to enterprise if you would like to send a quote for more than ' +
                                maxProUsers + ' users.';
                    }

                    final Boolean isQuantityValid = Math.mod(product.quantity, 5) == 0;
                    if (!isQuantityValid
                            && !SettingsProvider.isCustomUserLicenseTiers()
                            && isAnyQuoteTypeOrRenewalWithChangedQuantity) {
                        return 'Please enter a valid quantity for the license product. Possible options are increments of 5 (5, 10, 15, 20, 25 etc.).';
                    }
                }
                if (product.getIsRecurrent()) {
                    if (wQuote.newTerm < product.getBillingPeriodInMonth()) {
                        return 'Billing frequency (selected in Rate Plan) doesn\'t correspond to initial or renewal contract term.';
                    }
                    if (billingPeriod == null) {
                        billingPeriod = product.getBillingPeriodInMonth();
                    }
                    if (product.getBillingPeriodInMonth() != billingPeriod) {
                        return 'Billing frequency (selected in Rate Plan) should be the same for all recurring product in the quote.';
                    }
                }
            }
        }

        if (licenseProducts.isEmpty()) {
            return 'You should have at least one licence product in the quote.';
        }
        if(addedLicenseProducts.size() > 1) {
            return 'Please do not add multiple base license products.';
        }
        final Set<String> licenseProductIds = new Set<String>();
        for(WrikeQuoteProduct licenseProduct : licenseProducts) {
            licenseProductIds.add(licenseProduct.zuoraProductId);
        }
        if(licenseProductIds.size() > 1) {
            return 'Base license products must have the same type.';
        }

        final WrikeQuoteProduct mainLicenseProduct = addedLicenseProducts.isEmpty() ? licenseProducts[0] : addedLicenseProducts[0];
        if (proofingAddon && creativeProductCount > 0) {
            return 'You can not sell P&A add-on together with Wrike For Marketing / Wrike For Marketing Enterprise.';
        }
        final Map<String, Integer> userProductQuantityMap = getUserProductQuantityMap(wQuote.items);
        if(new Set<Integer> (userProductQuantityMap.values()).size() != 1) {
            return 'Quantity mismatch for add-on seats.';
        }
        final Boolean premium = zuoraProductSrv.isPremium(mainLicenseProduct.serviceType);
        if(premium) {
            if (pro200Allowed
                    && mainLicenseProduct.getBillingPeriodInMonth() != 3
                    && mainLicenseProduct.getBillingPeriodInMonth() != 12
                    && mainLicenseProduct.getBillingPeriodInMonth() != 1) {
                return 'Please use Annual or Quarterly or Monthly Billing for Professional Licenses License.';
            }
            final Integer totalUsers = userProductQuantityMap.values()[0];
            if(totalUsers <= 15 && mainLicenseProduct.getBillingPeriodInMonth() == 3) {
                return 'Quarterly Billing is allowed for Professional Licenses accounts with more than 15 users.';
            }
        }
        if(wrikePublishAddon && (premium || zuoraProductSrv.isCreative(mainLicenseProduct.serviceType))) {
            return 'Wrike Publish Add-on is not available for Professional, WfM, and WfM Enterprise licenses.';
        }
        if(wfmPackage && (premium || zuoraProductSrv.isCreative(mainLicenseProduct.serviceType))) {
            return 'Wrike for Marketers Package is not available for Professional, WfM, and WfM Enterprise Licenses.';
        }
        if(wfmPackage && (wrikePublishAddon || proofingAddon)) {
            return 'Wrike for Marketers Package can not be combined with Wrike Publish or Proofing Addons.';
        }
        if(wfpsPackage && premium) {
            return 'Wrike for Professional Services Package is not available for Professional License.';
        }
        if(wfpsPackage && wrikeResourceAddon) {
            return 'Wrike Resource Addon is already included in Wrike for Professional Services Package.';
        }
        if(wrikeAnalyzeAddon && premium) {
            return 'Wrike Analyze Addon is not available for Professional License.';
        }
        if(wrikePerformancePackage && wrikeAnalyzeAddon) {
            return 'Wrike Analyze Addon is already included in Wrike Performance Package.';
        }
        if(wrikePerformancePackage && wrikeIntegrateAddon) {
            return 'Wrike Integrate Addon is already included in Wrike Performance Package.';
        }
        if((wrikePerformancePackage || wrikeIntegrateAddon) && wrikeIntegrateStandard) {
            return 'Wrike Integrate Standard cannot be sold with Wrike Integrate or Wrike Performance Package.';
        }
        if(wrikeIntegrateEnhanced && !wrikeIntegrateStandard) {
            return 'Wrike Integrate Enhanced can only be sold with Wrike Integrate Standard.';
        }
        if(wrikeLockAddon && !zuoraProductSrv.isEnterprise(mainLicenseProduct.serviceType)) {
            return 'Wrike Lock is not available for a non-Enterprise License.';
        }
        if(wrikeLockAddon && wrikePerformancePackage) {
            return 'Wrike Lock cannot be sold with Wrike Performance Package at this time. Please remove one of them in order to save this quote.';
        }
        if(wrikePerformancePackage && !wfpsPackage && !wfmPackage) {
            return 'Wrike Performance Package can only be included if WfPS or WfM is included or has already been purchased.';
        }
        if(selfStart || quickStart) {
            final String deploymentName = selfStart ? 'Self Start' : 'Quick Start';
            if(hasDeployments || smartStart) {
                return deploymentName + ' cannot be sold with any other deployments.';
            }
            if(mainLicenseProduct.quantity > 15) {
                return deploymentName + ' can only be sold to a max of 15 users.';
            }
        }

        if(smartStart && (hasDeployments || selfStart || quickStart)) {
            return 'Smart Start cannot be sold with any other deployments.';
        }
        if(smartStart && mainLicenseProduct.quantity > 15 && !premium) {
            return 'Smart Start can only be sold to a max of 15 users.';
        }
        if(marketingInsightsEnhanced && (!wfmPackage || !marketingInsightsStandard)) {
            return 'Wrike Marketing Insights Enhanced can only be sold with combination of ' +
                    'Wrike for Marketers Package and Wrike Marketing Insights Standard.';
        }
        if(marketingInsightsStandard && !wfmPackage) {
            return 'Wrike Marketing Insights Standard can only be sold with Wrike for Marketers Package.';
        }
        for(WrikeQuoteItem quoteItem : wQuote.items) {
            if(!quoteItem.getIsRemoved()) {
                final WrikeQuoteProduct product = quoteItem.product;
                if(zuoraProductSrv.isResourceManagementAddon(product.serviceType)
                        && zuoraProductSrv.isPremium(mainLicenseProduct.serviceType)) {
                    return 'Wrike Resource Add-on is only available for Business or Enterprise licenses.';
                }
                if(product.getCollaboratorsAddon()
                        && zuoraProductSrv.isPremium(mainLicenseProduct.serviceType)) {
                    return 'Wrike Collaborator product is only available for Business or Enterprise level licenses.';
                }
            }
        }
        return null;
    }

    private Map<String, Integer> getUserProductQuantityMap(final List<WrikeQuoteItem> items) {
        final Map<String, Integer> productQuantityMap = new Map<String, Integer>();
        for(WrikeQuoteItem item : items) {
            if(!item.getIsRemoved() && (item.product.isSeatProduct() || item.product.isLicenseSeatsMatchingProduct())) {
                final String productId = item.product.zuoraProductId;
                final Integer quantity = productQuantityMap.get(productId);
                if(quantity != null) {
                    productQuantityMap.put(productId, quantity + item.product.quantity);
                } else {
                    productQuantityMap.put(productId, item.product.quantity);
                }
            }
        }
        return productQuantityMap;
    }

    public class Result {
        private final String code;
        private final String message;

        public Result(final String code, final String message) {
            this.code = code;
            this.message = message;
        }

        public String getCode() {
            return this.code;
        }

        public String getMessage() {
            return this.message;
        }
    }
}
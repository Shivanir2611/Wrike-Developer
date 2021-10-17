public class WrikeQuote {

    public static final String AMEND_ON_RENEWAL = WrikeQuote.AmendmentType.AMEND_ON_RENEWAL.name();
    public static final String AMEND_BEFORE_RENEWAL = WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL.name();
    public static final String AMEND_BEFORE_RENEWAL_AND_RENEW = WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL_AND_RENEW.name();
    public static final String START_NEW_BILLING_CYCLE = WrikeQuote.AmendmentType.START_NEW_BILLING_CYCLE.name();
    public static final String CANCEL_ON_RENEWAL = WrikeQuote.AmendmentType.CANCEL_ON_RENEWAL.name();

    public static final String SENT = WrikeQuote.Status.SENT.name();
    public static final String DRAFT = WrikeQuote.Status.DRAFT.name();

    private static final Set<WrikeQuote.AmendmentType> beforeAmendmentTypes = new Set<AmendmentType> {
        WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL,
        WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL_AND_RENEW,
        WrikeQuote.AmendmentType.START_NEW_BILLING_CYCLE
    };

    public static final String NET_30 = 'Net 30';
    public static final String NET_45 = 'Net 45';
    public static final String NET_60 = 'Net 60';
    private static final Map<String, Integer> dueDaysMap = new Map<String, Integer> {
        NET_30 => 30,
        NET_45 => 45,
        NET_60 => 60
    };
    private static Map<String, String> legalTermsMap = new Map<String, String>();

    private static Map<String, WrikeQuote.AmendmentType> nameToAmendmentType = new Map<String, WrikeQuote.AmendmentType>();
    private static Map<String, WrikeQuote.QuoteType> nameToQuoteType = new Map<String, WrikeQuote.QuoteType>();
    private static Map<String, WrikeQuote.Status> nameToStatus = new Map<String, WrikeQuote.Status>();
    private static Map<String, ZuoraCurrency> currencyMap = new Map<String, ZuoraCurrency>();

    static {
        for (WrikeQuote.AmendmentType currentType : WrikeQuote.AmendmentType.values()) {
            nameToAmendmentType.put(currentType.name(), currentType);
        }
        for (WrikeQuote.QuoteType currentType : WrikeQuote.QuoteType.values()) {
            nameToQuoteType.put(currentType.name(), currentType);
        }
        for (WrikeQuote.Status currentStatus : WrikeQuote.Status.values()) {
            nameToStatus.put(currentStatus.name(), currentStatus);
        }
        for (ZuoraCurrency currencyCode : ZuoraCurrency.values()) {
            currencyMap.put(currencyCode.name(), currencyCode);
        }
        final List<Schema.PicklistEntry> legalTermsOptions = Schema.SObjectType.Quote__c.fields.LegalTerms__c.getPicklistValues();
        for(Schema.PicklistEntry entry : legalTermsOptions) {
            legalTermsMap.put(entry.getValue(), entry.getLabel());
        }
    }

    public Id id {get; set;}
    public String name {get; set;}
    public Boolean primary {get; set;}
    public String companyName {get; set;}
    public String contactEmail {get; set;}
    public String companyAddress {get; set;}
    public String salesEmail {get; set;}
    public String salesName {get; set;}
    public String salesPhone {get; set;}
    public Status status {get; set;}
    public String quoteNumber {get; set;}
    public ZuoraCurrency quoteCurrency {get; set;}
    public QuoteType quoteType {get; set;}
    public AmendmentType amendmentType {get; set;}
    public String accountId {get; set;}
    public Id opportunityId {get; set;}
    public String opportunityName {get; set;}
    public Integer wrikeAccountId {get; set;}
    public DateTime createdDate {get; set;}
    public Date effectiveDate {get; set;}
    public Date validUntil {get; set;}
    public String zuoraAccountId {get; set;}
    public String zuoraAccountName {get; set;}
    public String zuoraSubscriptionId {get; set;}
    public String zuoraSubscriptionName {get; set;}
    public String zuoraCreditCardId {get; set;}
    public Integer currentTerm {get; set;}
    public Integer renewalTerm {get; set;}
    public Integer newTerm {get; set;}
    public List<WrikeQuoteItem> items {get; set;}
    public String paymentTerm {get; set;}
    public String legalTerms {get; set;}
    public Date legalTermsEffectiveDate {get; set;}
    public Date subscriptionStartDate {get; set;}
    public Date subscriptionEndDate {get; set;}
    public OpportunityDto opportunity {get; set;}
    public ContactBean contact {get; set;}
    public String creditCardLink {get; set;}
    public String attachemntId {get; set;}
    public String pdfId {get; set;}
    public Decimal total {get; set;}
    public Decimal deltaMrr {get; set;}
	public Decimal baseLicenseMrr {get; set;}
    public Decimal userDeltaMrr {get; set;}
    public Date targetInvoiceDate {get; set;}
    public Date invoiceDate {get; set;}
    public Integer savedHashCode {get; set;}
    public String approvalReason {get; set;}
    public String discountReason {get; set;}
    public Datetime lastEditDateTime {get; set;}
    public String lastEditBy {get; set;}
    public Boolean taxExempt {get; set;}
    public String taxExemptCertificateId {get; set;}
    public String dataCenter {get; set;}
    public String ownerName {get; set;}
    public String ownerEmail {get; set;}
    public String ownerPhone {get; set;}
    public String originalQuoteId {get; set;}
    public String originalQuoteName {get; set;}
    public Boolean isOriginalQuoteApproved {get; set;}
    public Decimal licenseDiscount {get; set;}
    public Decimal deploymentDiscount {get; set;}
    public Decimal resourceManagementDiscount {get; set;}
	public Decimal collaboratorBaseLicenseRate {get; set;}
    public String deploymentName {get; set;}
    public String oldProductName {get; set;}
    public String newProductName {get; set;}
    public String billingPeriodName {get; set;}
    public Integer oldQuantity {get; set;}
    public Integer newQuantity {get; set;}
    public Integer proofingAddonQuantity {get; set;}
    public Integer advancedFeatureAddonQuantity {get; set;}
    public Decimal oldPricePerUserPerMonth {get; set;}
    public Decimal newPricePerUserPerMonth {get; set;}
    public Boolean isTravelPaid {get; set;}
    public Boolean noPSIntegrate {get; set;}
    public Decimal priceIncreasePercent {get; set;}
    public Boolean onetimeDiscountIncluded {get; set;}
    public Boolean agencyReliefOfferDiscount {get; set;}
    public String verticalSegment {get; set;}
    public Integer numberOfTeams {get; set;}
    public Boolean deploymentOnly {get; set;}
    public String missingDeployments {get; set;}
    public Boolean hasWrikeIntegrate {get; set;}
    public Decimal maxDeploymentDiscount {get; set;}
    public Boolean hasFTE {get; set;}
    public Boolean hasWrikePerformancePackage {get; set;}
    public Boolean hasOldWrikeIntegrateAddon {get; set;}
    public Boolean hasCustomDeployment {get; set;}
    public Boolean additionalUsers {get; set;}
    public Boolean autoRenewalRemoval {get; set;}
    public String renewalPriceProtection {get; set;}
    public Boolean publicityRightsRemoval {get; set;}
    public Boolean coMarketingAddition {get; set;}
    public String governingLaw {get; set;}
    public String termsDataCenter {get; set;}
    public Decimal wfmDiscount {get; set;}
    public Decimal wfpsDiscount {get; set;}
    public Decimal wrikePerformancePackageDiscount {get; set;}
    public Decimal projectSyncsDiscount {get; set;}
    public Decimal wrikeAnalyzeDiscount {get; set;}
    public Decimal wrikeIntegrateDiscount {get; set;}
    public Decimal wrikeIntegrateEnhancedDiscount {get; set;}
    public Decimal wrikeLockDiscount {get; set;}
    public Decimal wrikeProofDiscount {get; set;}
    public Decimal wrikePublishDiscount {get; set;}
    public Decimal additionalCollaboratorDiscount {get; set;}
    public Decimal bronzeCertificationDiscount {get; set;}
    public Decimal silverCertificationDiscount {get; set;}
    public Boolean hasUnlimitedCollaborators {get; set;}
    public Boolean premiumSupportMismatch {get; set;}
    public Decimal selfStartDiscount {get; set;}
    public Decimal smartStartDiscount {get; set;}

    public Integer getDefaultNewTermValue() {
        if (getIsAmendBeforeRenewal() || getIsAmendBeforeRenewalAndRenew()) {
            return this.currentTerm;
        }
        return this.renewalTerm;
    }

    public String getOriginalName() {
        String resultName = this.name;
        String quoteNumberPattern = StringUtils.format('{0} - ', this.quoteNumber);
        if (this.name.startsWith(quoteNumberPattern)) {
            resultName = this.name.substring(quoteNumberPattern.length() - 1);
        }
        return resultName.trim();
    }

    public Boolean needsRenewal() {
        return this.quoteType == WrikeQuote.QuoteType.RENEWAL ||
               this.amendmentType == WrikeQuote.AmendmentType.AMEND_ON_RENEWAL ||
               this.amendmentType == WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL_AND_RENEW;
    }

    public Boolean isNewBillingCycle() {
        return isNewBillingCycleAmendment() ||
            (this.currentTerm != this.newTerm &&
                 (this.quoteType == WrikeQuote.QuoteType.RENEWAL ||
                  this.amendmentType == WrikeQuote.AmendmentType.AMEND_ON_RENEWAL));
    }

    public Boolean getRestoreAvailable() {
        return !isNewBillingCycle();
    }

    public void setCurrency(final String value) {
        this.quoteCurrency = currencyMap.containsKey(value) ? currencyMap.get(value) : ZuoraCurrency.USD;
    }

    public String getCurrencyCode() {
        return this.quoteCurrency.name();
    }

    public String getAmendmentTypeAsString() {
        if (this.amendmentType == null) {
            return '';
        }
        return this.amendmentType.name();
    }

    public void setAmendmentTypeAsString(String amendmentTypeString) {
        this.amendmentType = nameToAmendmentType.get(amendmentTypeString);
    }

    public String getQuoteTypeAsString() {
        if (this.quoteType == null) {
            return '';
        }
        return this.quoteType.name();
    }

    public void setQuoteTypeAsString(String quoteTypeString) {
        this.quoteType = nameToQuoteType.get(quoteTypeString);
    }

    public String getStatusAsString() {
        if (this.status == null) {
            return '';
        }
        return this.status.name();
    }

    public void setStatusAsString(String statusString) {
        this.status = nameToStatus.get(statusString);
    }

    public String getEffectiveDateAsString() {
        return DateUtils.format(this.effectiveDate);
    }

    public void setEffectiveDateAsString(String effectiveDateString) {
        this.effectiveDate = DateUtils.parse(effectiveDateString);
    }

    public String getValidUntilAsString() {
        return DateUtils.format(this.validUntil);
    }

    public void setValidUntilAsString(String effectiveDateString) {
        this.validUntil = DateUtils.parse(effectiveDateString);
    }

    public String getInvoiceDateAsString() {
        return DateUtils.format(this.invoiceDate);
    }

    public void setInvoiceDateAsString(final String invoiceDateValue) {
        this.invoiceDate = DateUtils.parse(invoiceDateValue);
    }

    public String getLegalTermsEffectiveDateAsString() {
        return DateUtils.format(this.legalTermsEffectiveDate);
    }

    public void setLegalTermsEffectiveDateAsString(final String legalTermsEffectiveDateValue) {
        this.legalTermsEffectiveDate = DateUtils.parse(legalTermsEffectiveDateValue);
    }

    public boolean getExistingLegalTermsType() {
        return this.legalTerms == 'EXISTING' || this.legalTerms == 'EXISTING_MSA';
    }

    public String getEncryptedId() {
        return id != null ? WrikeUtil.encryptAndEncode(id) : '';
    }

    public Date getEndDate() {
        if (this.subscriptionEndDate == null) {
            return null;
        }
        if (isBeforeRenewType() && !isNewBillingCycleAmendment()) {
            return this.subscriptionEndDate.addDays(-1);
        }
        return this.subscriptionEndDate;
    }

    public Date getTermEndDate() {
        return this.effectiveDate.addMonths(this.newTerm).addDays(-1);
    }

    public WrikeQuote() {
        this.items = new List<WrikeQuoteItem>();
        this.taxExempt = false;
        this.isOriginalQuoteApproved = false;
        this.isTravelPaid = true;
        this.noPSIntegrate = false;
        this.autoRenewalRemoval = false;
        this.publicityRightsRemoval = false;
        this.opportunity = new OpportunityDto();
    }

    public WrikeQuoteItem addItem(WrikeQuoteItem.State itemState, WrikeQuoteProduct quoteProduct) {
        WrikeQuoteItem quoteItem = new WrikeQuoteItem();
        quoteItem.state = itemState;
        quoteItem.product = quoteProduct;
        QuoteService.getInstance().mapToStandardProduct(quoteItem);
        this.items.add(quoteItem);
        return quoteItem;
    }

    public Boolean isRenewalOrAmendOnRenewal() {
        return getIsRenewal() || (getIsAmendment() && this.amendmentType == WrikeQuote.AmendmentType.AMEND_ON_RENEWAL);
    }

    public Boolean isBeforeRenewType() {
        return beforeAmendmentTypes.contains(this.amendmentType);
    }

    public Boolean getIsAmendment() {
        return this.quoteType == WrikeQuote.QuoteType.AMENDMENT;
    }

    public Boolean getIsSubscription() {
        return this.quoteType == WrikeQuote.QuoteType.SUBSCRIPTION || getOutbound();
    }

    public Boolean getOutbound() {
        return this.quoteType == WrikeQuote.QuoteType.SUBSCRIPTION_OUTBOUND;
    }

    public Boolean getIsRenewal() {
        return this.quoteType == WrikeQuote.QuoteType.RENEWAL;
    }


    public Boolean isNewBillingCycleAmendment() {
        return this.amendmentType == WrikeQuote.AmendmentType.START_NEW_BILLING_CYCLE;
    }

    public WrikeQuote cloneQuote() {
        return cloneQuote(false);
    }

    public WrikeQuote cloneQuote(final Boolean resetIds) {
        WrikeQuote wQuote = (WrikeQuote)this.clone();
        if (resetIds) {
            wQuote.id = null;
        }
        if (this.items != null) {
            wQuote.items = new List<WrikeQuoteItem>();
            for (WrikeQuoteItem item : this.items) {
                wQuote.items.add(item.cloneItem(resetIds));
            }
        }
        return wQuote;
    }

    public override Integer hashCode() {
        if (this.items == null || this.items.isEmpty()) {
            return 0;
        }
        List<String> itemsUniqueStrings = new List<String>();

        List<WrikeQuoteItem> sortedItems = this.items.clone();
        sortedItems.sort();
        for (WrikeQuoteItem quoteItem : sortedItems) {
            itemsUniqueStrings.add(quoteItem.getUniqueString());
        }
        String quotesUniqueString = getUniqueString() + String.join(itemsUniqueStrings, '');
        return quotesUniqueString.hashCode();
    }

    public String getUniqueString() {
        return String.join(new List<Object>{
            this.getQuoteTypeAsString(),
            this.getAmendmentTypeAsString(),
            this.opportunityId,
            this.getOutbound() ? 0 : this.wrikeAccountId,
            DateUtils.format(this.effectiveDate),
            this.getOutbound() ? '' : this.zuoraAccountId,
            this.newTerm,
            this.currentTerm,
            this.renewalTerm,
            this.paymentTerm,
            this.isTravelPaid
        }, '');
    }

    public Boolean getIsChanged() {
        return this.savedHashCode != hashCode();
    }

    public Boolean hasOnlyExistingProducts() {
        if (this.items == null || this.items.isEmpty()) {
            return false;
        }
        for (WrikeQuoteItem item : this.items) {
            if (!item.getIsExisting()) {
                return false;
            }
        }
        return true;
    }

    public Boolean hasOnlyRemovedProducts() {
        if (this.items == null || this.items.isEmpty()) {
            return false;
        }
        for (WrikeQuoteItem item : this.items) {
            if (!item.getIsRemoved()) {
                return false;
            }
        }
        return true;
    }

    public Boolean hasAddedOrRemovedUserProducts() {
        if (this.items == null || this.items.isEmpty()) {
            return false;
        }
        for (WrikeQuoteItem item : this.items) {
            if ((item.product.isSeatProduct() || item.product.isLicenseSeatsMatchingProduct())
                    && (item.getIsRemoved() || item.getIsAdded())) {
                return true;
            }
        }
        return false;
    }

    public Boolean getIsDraft() {
        return this.status == WrikeQuote.Status.DRAFT;
    }

    public Boolean getIsTrial() {
        return this.status == WrikeQuote.Status.TRIAL;
    }

    public Boolean getIsPendingApproval() {
        return this.status == WrikeQuote.Status.PENDING_APPROVAL;
    }

    public Boolean getIsApproved() {
        return this.status == WrikeQuote.Status.APPROVED;
    }
    public Boolean getIsEditable() {
        return getIsDraft() || getIsTrial() || getIsApproved();
    }

    public Boolean getIsProposal() {
        return this.status == WrikeQuote.Status.PROPOSAL;
    }

    public Boolean getIsSent() {
        return this.status == WrikeQuote.Status.SENT;
    }

    public Boolean getIsCancelled() {
        return this.status == WrikeQuote.Status.CANCEL;
    }

    public Boolean getIsApprovalPending() {
        if (String.isBlank(this.id)) {
            return false;
        }
        return getIsPendingApproval();
    }

    public Boolean getIsTermChanged() {
        return this.newTerm != getDefaultNewTermValue();
    }

    public Boolean getIsAmendBeforeRenewal() {
        return this.amendmentType == WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL;
    }

    public Boolean getIsAmendBeforeRenewalAndRenew() {
        return this.amendmentType == WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL_AND_RENEW;
    }

    public Integer getPaymentTermDueDays() {
        return dueDaysMap.containsKey(this.paymentTerm) ? dueDaysMap.get(this.paymentTerm) : 0;
    }

	public String getLegalTermsLabel() {
		return legalTermsMap.get(this.legalTerms);
	}

    public static Map<String, String> getLegalTermsMap() {
        return legalTermsMap;
    }

    public List<SelectOption> getLegalTermsSelectOptions() {
        final List<SelectOption> options = new List<SelectOption>();
        for(String value : legalTermsMap.keySet()) {
            options.add(new SelectOption(value, legalTermsMap.get(value)));
        }
        return options;
    }

    public Boolean getIsEmptyOrOnlyExistingOrRemovedProducts() {
        return this.items == null || this.items.isEmpty()
            || (getIsAmendment() && hasOnlyExistingProducts()) || (getIsAmendment() && hasOnlyRemovedProducts())
            || (getIsRenewal() && hasOnlyRemovedProducts());
    }

    public String getEffectiveDateLabel() {
        if (getIsSubscription()) {
            return 'Subscription Start Date';
        } else if (getIsAmendment()) {
            return 'Effective Date';
        } else if (getIsRenewal()) {
            return 'Renewal Date';
        }
        return 'Effective Date';
    }

    public WrikeQuoteItem getItemByUID(final String uid) {
        for (WrikeQuoteItem item : this.items) {
            if (item.uid == uid) {
                return item;
            }
        }
        return null;
    }

    public WrikeQuoteProduct getImplementationProduct() {
        return getProductByServiceType(ZuoraProductValidationService.IMPLEMENTATION);
    }

    public List<WrikeQuoteItem> getImplementationItems() {
        final List<WrikeQuoteItem> implementationItems = new List<WrikeQuoteItem>();
        for (WrikeQuoteItem quoteItem : this.items) {
            if (quoteItem.product != null &&
                            quoteItem.product.serviceType == ZuoraProductValidationService.IMPLEMENTATION) {
                implementationItems.add(quoteItem);
            }
        }
        return implementationItems;
    }

    public List<WrikeQuoteItem> getNonImplementationItems() {
        final List<WrikeQuoteItem> implementationItems = new List<WrikeQuoteItem>();
        for (WrikeQuoteItem quoteItem : this.items) {
            if (quoteItem.product != null &&
                            quoteItem.product.serviceType != ZuoraProductValidationService.IMPLEMENTATION) {
                implementationItems.add(quoteItem);
            }
        }
        return implementationItems;
    }

    public String getNumberOfTeamsStringValue() {
        if (this.numberOfTeams == 6) {
            return '6+';
        } else if (this.numberOfTeams == 0) {
            return 'No deployment';
        } else {
            return String.valueOf(this.numberOfTeams);
        }
    }

    public WrikeQuoteProduct getProductByServiceType(final String serviceType) {
        for (WrikeQuoteItem quoteItem : this.items) {
            if (quoteItem.product != null && quoteItem.product.serviceType == serviceType) {
                return quoteItem.product;
            }
        }
        return null;
    }

    public WrikeQuoteItem getAddedItemByServiceType(final String serviceType) {
        for (WrikeQuoteItem item : this.items) {
            if (item.getIsAdded() && item.product != null && item.product.serviceType == serviceType) {
                return item;
            }
        }
        return null;
    }

    public WrikeQuoteItem getExistingItemByServiceType(final String serviceType) {
        for (WrikeQuoteItem item : this.items) {
            if (!item.getIsRemoved() && item.product != null && item.product.serviceType == serviceType) {
                return item;
            }
        }
        return null;
    }

    public Boolean hasWrikeIntegrate() {
        for (WrikeQuoteItem item : this.items) {
            if (!item.getIsRemoved() && item.product != null && item.product.isWrikeIntegrate()) {
                return true;
            }
        }
        return false;
    }

    public Boolean hasWrikePerformancePackage() {
        for (WrikeQuoteItem item : this.items) {
            if (!item.getIsRemoved() && item.product != null && item.product.isWrikePerformancePackage()) {
                return true;
            }
        }
        return false;
    }

    public Boolean getIsAgencyVertical() {
        return this.verticalSegment != null && this.verticalSegment.contains('Agencies');
    }

    public Integer getDeltaSeats(final String serviceType) {
        Integer deltaSeats = 0;
        for (WrikeQuoteItem item : items) {
            if (item.product.serviceType.equals(serviceType)) {
                if (item.getIsAdded()) {
                    deltaSeats = deltaSeats + item.product.quantity;
                } else if (item.getIsRemoved()) {
                    deltaSeats = deltaSeats - item.product.quantity;
                }
            }
        }
        return deltaSeats;
    }

    public enum Status {
        DRAFT,
        TRIAL,
        PENDING_APPROVAL,
        APPROVED,
        PROPOSAL,
        SENT,
        CANCEL
    }

    public enum QuoteType {
        SUBSCRIPTION,
        SUBSCRIPTION_OUTBOUND,
        AMENDMENT,
        RENEWAL
    }

    public enum AmendmentType {
        AMEND_ON_RENEWAL,
        AMEND_BEFORE_RENEWAL,
        AMEND_BEFORE_RENEWAL_AND_RENEW,
        START_NEW_BILLING_CYCLE,
        CANCEL_ON_RENEWAL
    }
}
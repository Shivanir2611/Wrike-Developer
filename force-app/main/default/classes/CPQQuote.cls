public class CPQQuote {

    private static final String UpfrontBilling = 'Upfront';
    public static final String CustomBilling = 'Custom schedule';

    public static final String Draft = 'Draft';
    public static final String PendingApproval = 'PendingApproval';
    public static final String Approved = 'Approved';
    public static final String Rejected = 'Rejected';
    public static final String PendingDocument = 'PendingDocument';
    public static final String DocumentGenerated = 'DocumentGenerated';
    public static final String DocuSignSent = 'DocuSignSent';
    public static final String DocuSignSigned = 'DocuSignSigned';
    public static final String DocuSignDeclined = 'DocuSignDeclined';
    public static final String Ordered = 'Ordered';
    public static final String Cancelled = 'Cancelled';

    @AuraEnabled
    public Id id {get; set;}
    @AuraEnabled
    public String name {get; set;}
    @AuraEnabled
    public String status {get; set;}
    @AuraEnabled
    public Date startDate {get; set;}
    @AuraEnabled
    public Date endDate {get; set;}
    public Decimal term {get; set;}
    public Integer numberOfInvoices {get; set;}
    public Integer numberOfTeams {get; set;}
    public Boolean legacyBasePlansAllowed {get; set;}
    public String billingPeriodName {get; set;}
    @AuraEnabled
    public Decimal subscriptionTotal {get; set;}
    @AuraEnabled
    public Decimal oneTimeTotal {get; set;}
    public Decimal subscriptionMonthlyRate {get; set;}
    public Boolean approvalRequired {get; set;}
    public String approvalStatus {get; set;}
    @AuraEnabled
    public Id existingRenewalQuoteId {get; set;}
    public Id existingRenewalQuoteOpportunityId {get; set;}
    public Boolean documentHasDraftWatermark {get; set;}
    public Boolean preSignDocument {get; set;}
    public Boolean purchasingByPO {get; set;}
    public Date expirationDate {get; set;}
    @AuraEnabled
    public Boolean primary {get; set;}
    @AuraEnabled
    public String currencyCode {get; set;}
    public String type {get; set;}
    public String quoteType {get; set;}
    public String quoteSubType {get; set;}
    @AuraEnabled
    public Decimal deltaMrr {get; set;}
    @AuraEnabled
    public Id accountId {get; set;}
    @AuraEnabled
    public String accountName {get; set;}
    @AuraEnabled
    public Id pdfId {get; set;}
    public Id billToId {get; set;}
    public Id shipToId {get; set;}
    public Id cancelledContractId {get; set;}
    public Id endCustomerId {get; set;}
    public Id restructureNewQuoteId {get; set;}
    public String governingTerms {get; set;}
    public Date agreementDate {get; set;}
    public String customGoverningTerms {get; set;}
    @AuraEnabled
    public Decimal wrikeAccountId {get; set;}
    @AuraEnabled
    public Id opportunityId {get; set;}
    @AuraEnabled
    public String opportunityName {get; set;}
    public Decimal opportunityWrikeAccountId {get; set;}
    public Id renewedContractId {get; set;}
    public Id amendedContractId {get; set;}
    @AuraEnabled
    public Id orderId {get; set;}
    @AuraEnabled
    public String orderNumber {get; set;}
    public String docuSignEnvelopeExternalId {get; set;}
    public String vatNumber {get; set;}
    public String billToCountryCode {get; set;}
    public String billToStateCode {get; set;}
    public String billToZip {get; set;}
    public String paymentTerms {get; set;}
    public Decimal billingFrequency {get; set;}
    public Id resellerAccountId {get; set;}
    public Id opportunityRecordTypeId {get; set;}
    @AuraEnabled
    public List<CPQQuoteLineItem> items {get; set;}
    @AuraEnabled
    public List<CPQBillingSchedule> billingSchedules {get; set;}

    @AuraEnabled
    public Boolean getIsCustomBilling() {
        return CustomBilling.equalsIgnoreCase(billingPeriodName);
    }

    public Boolean getIsUpfrontBilling() {
        return UpfrontBilling.equalsIgnoreCase(billingPeriodName);
    }

    public Boolean getIsRestructureNewQuote() {
        return 'Restart Contract (new contract - create)'.equalsIgnoreCase(quoteSubType);
    }

    public Boolean getIsRestructureCancellationQuote() {
        return 'Restart Contract (old contract - cancel)'.equals(quoteSubType);
    }

    public Boolean getIsOrderNullification() {
        return 'Downsell'.equals(quoteType) && 'Nullify an Order'.equals(quoteSubType);
    }

    public Id getChangedContractId() {
        if (getIsRenewal()) {
            return renewedContractId;
        }
        if (getIsAmendment()) {
            return amendedContractId;
        }
        if (getIsRestructureNewQuote()) {
            return cancelledContractId;
        }
        return null;
    }

    @AuraEnabled
    public Boolean getIsRenewal() {
        return 'Renewal'.equalsIgnoreCase(type);
    }

    @AuraEnabled
    public Boolean getIsAmendment() {
        return 'Amendment'.equalsIgnoreCase(type);
    }

    public Boolean getIsNewSubscription() {
        return 'Quote'.equalsIgnoreCase(type);
    }

    @AuraEnabled
    public Boolean getIsDraft() {
        return Draft.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsPendingApproval() {
        return PendingApproval.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsApproved() {
        return Approved.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsRejected() {
        return Rejected.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsPendingDocument() {
        return PendingDocument.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsDocumentGenerated() {
        return DocumentGenerated.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsDocuSignSent() {
        return DocuSignSent.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsDocuSignSigned() {
        return DocuSignSigned.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsDocuSignDeclined() {
        return DocuSignDeclined.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsOrdered() {
        return Ordered.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public Boolean getIsCancelled() {
        return Cancelled.equalsIgnoreCase(status);
    }

    @AuraEnabled
    public String getPdfLink() {
        return URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + pdfId;
    }

    @AuraEnabled
    public Boolean getAddPartnerAllowed() {
        return getIsDraft()
                && !getIsAmendment()
                && (CPQSettings__c.getOrgDefaults().EnableAddPartnerButton__c || getIsAdminOrBilling());
    }

    @AuraEnabled
    public Boolean getDeletionAllowed() {
        return FeatureManagement.checkPermission('CPQQuoteDeletion')
                || OrganizationService.getInstance().isSandbox();
    }

    @AuraEnabled
    public List<List<String>> getStatusPicklistValues() {
        final List<List<String>> values = new List<List<String>>();
        for (PicklistEntry entry : SBQQ__Quote__c.SBQQ__Status__c.getDescribe().getPicklistValues()) {
            if (isValidStatus(entry.getValue())) {
                values.add(new List<String>{entry.getValue(), entry.getLabel()});
            }
        }
        return values;
    }

    private Boolean isValidStatus(final String status) {
        if (status != CPQQuote.Approved
                && status != CPQQuote.Rejected
                && status != CPQQuote.DocuSignSigned
                && status != CPQQuote.DocuSignDeclined
                && status != CPQQuote.Ordered
                && status != CPQQuote.Cancelled) {
            return true;
        }
        if (status == CPQQuote.Rejected && getIsRejected()) {
            return true;
        }
        if (status == CPQQuote.Approved && !getIsRejected()) {
            return true;
        }
        if (status == CPQQuote.DocuSignSigned && !getIsDocuSignDeclined()) {
            return true;
        }
        if (status == CPQQuote.DocuSignDeclined && getIsDocuSignDeclined()) {
            return true;
        }
        if (status == CPQQuote.Ordered && !getIsCancelled()) {
            return true;
        }
        if (status == CPQQuote.Cancelled && getIsCancelled()) {
            return true;
        }
        return false;
    }

    @AuraEnabled
    public String getPreviewMessage() {
        if (items.isEmpty()) {
            return 'Please add products.';
        }
        if (startDate > endDate) {
            return 'Start date is later than end date.';
        }
        return null;
    }

    @AuraEnabled
    public String getStartApprovalMessage() {
        if (items.isEmpty()) {
            return 'Please add products.';
        }
        if (startDate > endDate) {
            return 'Start date is later than end date.';
        }
        if (getIsCustomBilling()
                && !CPQBillingScheduleService.getInstance().validateBillingSchedulesTotal(this)) {
            return 'Please set custom billing schedule.';
        }
        if ('Add Deployment Only'.equals(quoteSubType) && subscriptionTotal != 0) {
            return 'This is a deployment only quote - you can\'t change the amount a customer pays for their ' +
                    'subscription here. Please use "Upgrade subscription" quote subtype instead.';
        }
        if (getIsRestructureCancellationQuote()) {
            if (restructureNewQuoteId == null) {
                return 'Restructure Cancellation Quote must be linked to Restructure New Quote.';
            }
            final CPQQuote restructureNewQuote = CPQQuoteService.getInstance().findQuoteById(restructureNewQuoteId);
            if (restructureNewQuote.startDate != startDate) {
                return 'Restructure Cancellation Quote can\'t be activated while its start date doesn\'t match ' +
                        'Restructure New Quote start date.';
            }
        }
        if (getIsRestructureNewQuote()
                && CPQQuoteService.getInstance().hasRestructureStartDatesMismatch(id, startDate)) {
            return 'Restructure New Quote can\'t be activated while its start date doesn\'t match each of related ' +
                    'Restructure Cancel Quote start dates.';
        }
        if ((governingTerms == 'Existing MSA'
                || governingTerms == 'Custom Pilot')
                && agreementDate == null) {
            return 'Please specify the Agreement Date for the Existing MSA with a customer. ' +
                    'If in doubt, please check with the Legal team.';
        }
        if ((governingTerms == 'Custom Terms'
                || governingTerms == 'Partner Agreement')
                && String.isBlank(customGoverningTerms)) {
            return 'Please specify Custom Governing Terms for the Custom Terms/Partner Agreement.';
        }
        if (resellerAccountId != null) {
            final Boolean oneTimeDiscountAllowed = getIsAdminOrBilling()
                    && opportunityRecordTypeId == SchemaUtils.getRecordTypeIdByName(Opportunity.getSObjectType(), 'CPQ Migration');
            if (!oneTimeDiscountAllowed) {
                for (CPQQuoteLineItem item : items) {
                    if (item.nonRenewableDiscount != null && item.nonRenewableDiscount != 0) {
                        return 'Non-renewable discounts are not allowed for Partner quotes.';
                    }
                }
            }
        }
        return null;
    }

    @AuraEnabled
    public String getCreateOrderMessage() {
        if (!primary) {
            return 'Quote is not primary.';
        }
        if (documentHasDraftWatermark) {
            return 'Quote document has "Draft" watermark. Please regenerate document to remove watermark.';
        }
        if (restructureNewQuoteId != null) {
            final CPQQuote restructureNewQuote = CPQQuoteService.getInstance().findQuoteById(restructureNewQuoteId);
            if (!restructureNewQuote.getIsOrdered()) {
                return 'Restructure Cancellation Quote can\'t be ordered while Restructure New Quote isn\'t ordered.';
            }
        }
        if (!OrganizationService.getInstance().isSandbox() && !getIsAdminOrBilling()) {
            return 'Please switch the opportunity into "Close/Won - Pending" status for the Billing Team to process the order.';
        }
        return null;
    }

    @AuraEnabled
    public Boolean getIsAdminOrBilling() {
        return ProfileQueryService.getInstance().isAdminOrBillingProfile(UserInfo.getProfileId());
    }

    @AuraEnabled
    public String getSendViaDocuSignMessage() {
        if (!primary) {
            return 'Quote is not primary.';
        }
        if (documentHasDraftWatermark) {
            return 'Quote document has "Draft" watermark. Please regenerate document to remove watermark.';
        }
        if (purchasingByPO) {
            return 'Purchasing by PO only option is chosen. Send the quote to the billing department if ' +
                    'Purchasing by PO only is approved by the legal department and stated in the MSA. If not, ' +
                    'please, uncheck the checkbox.';
        }
        if (getIsOrderNullification()) {
            return 'Order Nullification quotes can\'t be sent for signature.';
        }
        return null;
    }

    @AuraEnabled
    public Boolean getQuoteBlocked() {
        return getBlockedQuoteMessage() != null || getRenewalQuoteExists();
    }

    @AuraEnabled
    public Boolean getRenewalQuoteExists() {
        return getIsRenewal()
                && existingRenewalQuoteId != null
                && existingRenewalQuoteOpportunityId != opportunityId;
    }

    public Boolean getOpportunityPartnersInconsistent() {
        final List<Partner__c> opportunityPartners =
                OpportunityQueryService.getInstance().findOpportunityResellerPartners(opportunityId);
        return opportunityPartners.size() != 1 || opportunityPartners.get(0).Partner__c != resellerAccountId;
    }

    @AuraEnabled
    public String getBlockedQuoteMessage() {
        if (!primary) {
            final String existingPrimaryQuoteStatus =
                    CPQQuoteQueryService.getInstance().findExistingPrimaryQuoteStatus(opportunityId);
            if (DocuSignSent.equalsIgnoreCase(existingPrimaryQuoteStatus) ||
                    DocuSignDeclined.equalsIgnoreCase(existingPrimaryQuoteStatus)) {
                return 'Current primary quote on this opportunity is already sent via Docusing. ' +
                        'Please cancel that Docusign before making this quote Primary.';
            }
            if (DocuSignSigned.equalsIgnoreCase(existingPrimaryQuoteStatus) ||
                    Ordered.equalsIgnoreCase(existingPrimaryQuoteStatus)) {
                return 'This quote can\'t be make primary - the current primary quote has already been signed or ordered.';
            }
        }
        if (resellerAccountId != null && getOpportunityPartnersInconsistent()) {
            return 'There is more than one reseller on the opportunity or the reseller on the opportunity ' +
                    'doesn\'t match the one on the quote. Please fix before going forward with this quote.';
        }
        if (getIsCancelled()) {
            return 'Quote is cancelled.';
        }
        return null;
    }

    @AuraEnabled
    public Boolean getHasPartnerAccount() {
        return resellerAccountId != null;
    }

    @AuraEnabled
    public String getGenerateDocumentMessage() {
        if (billToId == null || shipToId == null) {
            return 'Bill To/Ship To is not set.';
        }
        if (getHasPartnerAccount() && endCustomerId == null) {
            return 'End Customer\'s address needs to be filled in for Partner Deals.';
        }
        if (wrikeAccountId == null) {
            return 'Please set Wrike account ID.';
        }
        final AddressService addressSrv = AddressService.getInstance();
        if (!getIsAdminOrBilling() && addressSrv.isVatNumberRequired(billToCountryCode)) {
            final String vatNumberWithoutCountyCode = String.isNotBlank(vatNumber)
                                                              && CountryUtil.isValidCountryCode(vatNumber.substring(0, 2))
                                                      ? vatNumber.substring(2).trim()
                                                      : vatNumber;
            if (String.isBlank(vatNumberWithoutCountyCode)) {
                return 'Valid VAT numbers are required for the EU countries and UK.';
            }
            final VatNumberDto vatNumberDto = addressSrv.checkVatNumber(
                    billToCountryCode,
                    vatNumberWithoutCountyCode
            );
            if (!vatNumberDto.isValid) {
                return 'Provided VAT number is invalid. Please fix the VAT number to create PDF.';
            }
        }
        return null;
    }

    @AuraEnabled
    public String getGenerateDocumentWarningMessage() {
        if (!primary) {
            return 'To remove "Draft" watermark make the quote primary.';
        }
        return null;
    }

    @AuraEnabled
    public Boolean getIsWrikeAccountIdMismatch() {
        return wrikeAccountId != opportunityWrikeAccountId;
    }

    @AuraEnabled
    public Boolean getShowOrderLink() {
        return SettingsProvider.isAdmin() || SettingsProvider.isBillingProfile();
    }

    public Boolean hasItemWithProductId(final Id productId) {
        for (CPQQuoteLineItem item : items) {
            if (item.product.Id == productId) {
                return true;
            }
        }
        return false;
    }
}
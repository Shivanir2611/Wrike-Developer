public class CPQQuoteService {

    public static CPQQuoteService getInstance() {
        return (CPQQuoteService)ServiceLocator.getInstance(CPQQuoteService.class);
    }

    private CPQQuoteQueryService quoteQuerySrv = CPQQuoteQueryService.getInstance();
    private CPQBillingScheduleService billingScheduleSrv = CPQBillingScheduleService.getInstance();
    private BillToShipToService billToShipToSrv = BillToShipToService.getInstance();
    private BillToShipToQueryService billToShipToQuerySrv = BillToShipToQueryService.getInstance();
    private CPQProductService productSrv = CPQProductService.getInstance();
    private CPQDeploymentSuggestionService deploymentSuggestionSrv = CPQDeploymentSuggestionService.getInstance();

    public CPQQuote findQuoteById(final Id quoteId) {
        final SBQQ__Quote__c quote = quoteQuerySrv.findQuoteById(quoteId);
        return CPQQuoteMapper.mapToCPQQuoteWithLineItems(quote);
    }

    public String getStatusById(final Id quoteId) {
        final SBQQ__Quote__c quote = quoteQuerySrv.findWithStatusForUpdateById(quoteId);
        return quote == null ? null : quote.SBQQ__Status__c;
    }

    public void makePrimary(final CPQQuote quote) {
        final Id primaryQuoteId = quoteQuerySrv.findExistingPrimaryQuoteId(quote.opportunityId);
        if (primaryQuoteId != null) {
            update new SBQQ__Quote__c(
                    Id = primaryQuoteId,
                    SBQQ__Primary__c = false
            );
        }
        if (quote.getIsWrikeAccountIdMismatch()) {
            update new Opportunity(
                    Id = quote.opportunityId,
                    Wrike_Account_Id__c = quote.wrikeAccountId
            );
        }
        final SBQQ__Quote__c record = new SBQQ__Quote__c(
                Id = quote.id,
                SBQQ__Primary__c = true
        );
        update record;
    }

    public void startApproval(final CPQQuote quote, final Boolean approvalRequired) {
        calculateBillingScheduleAndUpdateQuote(quote.id);
        if (quote.getIsRenewal()) {
            setContractActivatedRenewalQuote(quote.id, quote.renewedContractId);
        }
        final List<String> missingDeploymentNames = getMissingDeployments(quote);
        update new SBQQ__Quote__c(
                Id = quote.id,
                SBQQ__Status__c = approvalRequired
                                  ? CPQQuote.PendingApproval
                                  : CPQQuote.Approved,
                MissingDeployments__c = missingDeploymentNames.isEmpty()
                                        ? null
                                        : String.join(missingDeploymentNames, ', ')
        );
        if (approvalRequired) {
            SBAA.ApprovalAPI.submit(quote.id, SBAA__Approval__c.Quote__c);
        }
    }

    public void updateQuoteBeforeApprovalPreview(final CPQQuote quote) {
        final List<String> missingDeploymentNames = getMissingDeployments(quote);
        update new SBQQ__Quote__c(
                Id = quote.Id,
                MissingDeployments__c = missingDeploymentNames.isEmpty()
                                        ? null
                                        : String.join(missingDeploymentNames, ', ')
        );
    }

    private List<String> getMissingDeployments(final CPQQuote quote) {
        final Id customDeploymentId = Settings__c.getOrgDefaults().CustomDeploymentId__c;
        final List<String> missingDeploymentNames = new List<String>();
        if (!quote.hasItemWithProductId(customDeploymentId) && !quote.getIsRenewal()) {
            for (Product2 deployment : deploymentSuggestionSrv.getMissingDeployments(quote)) {
                missingDeploymentNames.add(deployment.Name);
            }
        }
        return missingDeploymentNames;
    }

    public void recallApproval(final Id quoteId) {
        SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
    }

    public void updateBillToShipTo(final Id quoteId,
                                   final Id billToId,
                                   final Id shipToId,
                                   final Id endCustomerId) {
        update new SBQQ__Quote__c(
                Id = quoteId,
                QS_Bill_To__c = billToId,
                QS_Ship_To__c = shipToId,
                EndCustomer__c = endCustomerId
        );
    }

    public void updateCustomBilling(final Id quoteId) {
        update new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__BillingFrequency__c = CPQQuote.CustomBilling
        );
    }

    public void setQuoteFieldsFromResellerAccount(final SBQQ__Quote__c quote, final Account partnerAccount) {
        quote.ResellerAccount__c = partnerAccount.Id;
        quote.SBQQ__PaymentTerms__c = partnerAccount.PaymentTerms__c;
        quote.Governing_Terms__c = 'Partner Agreement';
        quote.Date_of_Agreement__c = partnerAccount.GoverningTermsDate__c;
        quote.Automatic_Renewal__c = 'No';
        quote.PartnerAgreementType__c = partnerAccount.AgreementType__c;
        quote.CustomGoverningTerms__c = partnerAccount.GoverningTerms__c;
        quote.Tax_Exempt__c = partnerAccount.TaxExempt__c;
        quote.OnetimeFeesCommission__c = partnerAccount.OnetimeFeesCommission__c;
        quote.Display_Partner_Discount__c = true;
        quote.DisplayAnnualPartnerRate__c = true;
        quote.DisplayPartnerPurchasePrice__c = true;
        quote.Display_Annual_List_Rate__c = false;
        quote.Display_Annual_Effective_Rate__c = true;
        quote.Display_Line_Total__c = false;
        if ('Renewal'.equals(quote.QuoteType__c)) {
            quote.SubscriptionCommission__c = partnerAccount.RenewalSubscriptionCommission__c;
        } else {
            quote.SubscriptionCommission__c = partnerAccount.NewSubscriptionCommission__c;
        }
        final SBQQ__Quote__c quoteWithContacts = quoteQuerySrv.findWithBillToShipToById(quote.Id);
        quote.QS_Bill_To__c = billToShipToSrv.getPartnerContactId(quoteWithContacts.QS_Bill_To__r, partnerAccount.Id, quoteWithContacts.SBQQ__Account__c, true, false);
        quote.QS_Ship_To__c = billToShipToSrv.getPartnerContactId(quoteWithContacts.QS_Ship_To__r, partnerAccount.Id, quoteWithContacts.SBQQ__Account__c, false, true);
    }

    public void updateQuoteLinesPartnerCommission(final Id quoteId,
                                                  final Boolean migration,
                                                  final Decimal subscriptionCommission,
                                                  final Decimal oneTimeCommission)  {
        final List<SBQQ__QuoteLine__c> quoteLines = quoteQuerySrv.findQuoteLinesByQuoteId(quoteId);
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            quoteLine.SBQQ__PartnerDiscount__c = 'One-Time'.equalsIgnoreCase(quoteLine.SBQQ__ChargeType__c)
                                                 ? oneTimeCommission
                                                 : subscriptionCommission;
            if (!migration
                    && quoteLine.NonRenewableDiscount__c != null
                    && quoteLine.NonRenewableDiscount__c != 0) {
                quoteLine.NonRenewableDiscount__c = null;
            }
        }
        if (!quoteLines.isEmpty()) {
            update quoteLines;
        }
    }

    public void setDocumentGeneratedStatus(final Id quoteId) {
        update new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__Status__c = CPQQuote.DocumentGenerated,
                DocuSignEnvelope__c = null,
                DocuSignStatus__c = null
        );
    }

    public void setDocuSignSignedStatus(final Id quoteId) {
        update new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__Status__c = CPQQuote.DocuSignSigned
        );
    }

    public void cancelQuote(final CPQQuote quote) {
        update new SBQQ__Quote__c(
                Id = quote.id,
                SBQQ__Status__c = CPQQuote.Cancelled
        );
        if (quote.getIsRenewal()) {
            updateContractActivatedRenewalQuote(quote);
        }
    }

    public void setDocuSignDeclinedStatus(final Id quoteId) {
        update new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__Status__c = CPQQuote.DocuSignDeclined
        );
    }

    public Boolean hasRestructureStartDatesMismatch(final Id quoteId, final Date startDate) {
        final List<SBQQ__Quote__c> cancelQuotes = [
                SELECT SBQQ__StartDate__c
                FROM SBQQ__Quote__c
                WHERE RestructureNewQuote__c = :quoteId
        ];
        for (SBQQ__Quote__c cancelQuote : cancelQuotes) {
            if (cancelQuote.SBQQ__StartDate__c != startDate) {
                return true;
            }
        }
        return false;
    }

    public void deleteDocument(final Id quoteId) {
        update new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__Status__c = CPQQuote.Approved,
                DocumentHasDraftWatermark__c = false
        );
        delete [
                SELECT Id
                  FROM SBQQ__QuoteDocument__c
                 WHERE SBQQ__Quote__c = :quoteId
        ];
    }

    public void createOrder(final Id quoteId) {
        update new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__Status__c = CPQQuote.Ordered,
                SBQQ__Ordered__c = true
        );
    }

    public void resetQuoteToDraft(final CPQQuote quote) {
        if (quote.getIsRenewal()) {
            updateContractActivatedRenewalQuote(quote);
        }
        update new SBQQ__Quote__c(
                Id = quote.id,
                SBQQ__Status__c = CPQQuote.Draft,
                MissingDeployments__c = null,
                ApprovalRequired__c = true,
                ApprovalStatus__c = quote.approvalStatus != null ? 'Recalled' : null
        );
        if (!quote.getIsCustomBilling()) {
            deleteBillingScheduleByQuoteId(quote.id);
        }
    }

    public void setContractActivatedRenewalQuote(final Id quoteId, final Id contractId) {
        update new Contract(
                Id = contractId,
                ActivatedRenewalQuote__c = quoteId
        );
    }

    public void updateContractActivatedRenewalQuote(final CPQQuote quote) {
        final List<SBQQ__Quote__c> activatedQuotes =
                quoteQuerySrv.findActivatedRenewalQuotesByContract(quote.renewedContractId);
        Id renewalQuoteId = null;
        for (SBQQ__Quote__c activatedQuote : activatedQuotes) {
            if (activatedQuote.Id != quote.existingRenewalQuoteId) {
                renewalQuoteId = activatedQuote.Id;
            }
        }
        setContractActivatedRenewalQuote(renewalQuoteId, quote.renewedContractId);
    }

    public void calculateBillingScheduleAndUpdateQuote(final Id quoteId) {
        final CPQQuote cpqQuote = findQuoteById(quoteId);
        if (!cpqQuote.getIsCustomBilling()) {
            final List<CPQBillingSchedule> billingSchedules = billingScheduleSrv.calculateBillingSchedule(cpqQuote);
            if (!cpqQuote.billingSchedules.isEmpty()) {
                deleteBillingSchedule(cpqQuote.billingSchedules);
            }
            insertBillingSchedule(billingSchedules);
        }
    }

    public void insertBillingSchedule(final List<CPQBillingSchedule> cpqBillingSchedules) {
        final List<Billing_Schedule__c> billingSchedules = CPQQuoteMapper.mapToBillingSchedules(cpqBillingSchedules);
        insert billingSchedules;
    }

    // TEMPORARY
    public void updateDiscountAndWatermarkFlags(final Id quoteId) {
        final SBQQ__Quote__c quote = [
                SELECT Id, QS_Bill_To__c, QS_Ship_To__c, SBQQ__Primary__c,
                       (SELECT Id, NonRenewableDiscount__c, SBQQ__PartnerDiscount__c FROM SBQQ__LineItems__r)
                  FROM SBQQ__Quote__c
                 WHERE Id = :quoteId
        ].get(0);
        Boolean hasOneTimeDiscount = false;
        Boolean hasPartnerDiscount = false;
        for (SBQQ__QuoteLine__c item : quote.SBQQ__LineItems__r) {
            if (item.NonRenewableDiscount__c != null && item.NonRenewableDiscount__c != 0) {
                hasOneTimeDiscount = true;
            }
            if (item.SBQQ__PartnerDiscount__c != null && item.SBQQ__PartnerDiscount__c != 0) {
                hasPartnerDiscount = true;
            }
        }
        update new SBQQ__Quote__c(
                Id = quoteId,
                Display_One_Time_Discount__c = hasOneTimeDiscount,
                Display_Partner_Discount__c = hasPartnerDiscount,
                SBQQ__WatermarkShown__c = quote.QS_Bill_To__c == null
                        || quote.QS_Ship_To__c == null
                        || !quote.SBQQ__Primary__c
        );
    }

    public void initiateDocumentGeneration(final CPQQuote quote) {
        updateDiscountAndWatermarkFlags(quote.id); // TEMPORARY
        update new SBQQ__Quote__c(
                Id = quote.id,
                SBQQ__Status__c = CPQQuote.PendingDocument,
                DocumentHasDraftWatermark__c = !quote.primary
        );
        billToShipToSrv.updateWrikeAccountId(quote.billToId, quote.wrikeAccountId);
        billToShipToSrv.updateWrikeAccountId(quote.shipToId, quote.wrikeAccountId);
        SBQQ.QuoteDocumentController.saveProposal(
                'en_US',
                quote.id,
                CPQSettings__c.getOrgDefaults().QuoteDocumentTemplateId__c,
                'Quote Document',
                'PDF',
                'Default',
                new List<String>{quote.id}
        );
    }

    private void deleteBillingSchedule(final List<CPQBillingSchedule> billingSchedules) {
        final List<Billing_Schedule__c> recordsToDelete = new List<Billing_Schedule__c>();
        for (CPQBillingSchedule billingSchedule : billingSchedules) {
            recordsToDelete.add(new Billing_Schedule__c(Id = billingSchedule.id));
        }
        delete recordsToDelete;
    }

    public void deleteBillingScheduleByQuoteId(final Id quoteId) {
        delete [
                SELECT Id
                FROM Billing_Schedule__c
                WHERE Quote__c = :quoteId
        ];
    }

    public void deleteQuoteLinesByIds(final List<Id> quoteLineIds) {
        final List<SBQQ__QuoteLine__c> recordsToDelete = new List<SBQQ__QuoteLine__c>();
        for (Id quoteLineId : quoteLineIds) {
            recordsToDelete.add(new SBQQ__QuoteLine__c(Id = quoteLineId));
        }
        delete recordsToDelete;
    }

    public WrikeAccountRegistrationResult registerNewWrikeAccount(final String email) {
        final Map<String, Object> response = WrikeUtil.sendWrikeRequest(0,
                new Map<String, String> {
                    'action' => 'register_new_account',
                    'email' => email,
                    'platform' => 'cpq'
                }
        );
        final String message = (String)response.get('message');
        final Integer wrikeAccountId = (Integer)response.get('wrikeAccountId');
        return new WrikeAccountRegistrationResult(wrikeAccountId, message);
    }

    public List<WrikeAccountInfo> findWrikeAccountsByEmail(final String email) {
        final Map<String, Object> response = WrikeUtil.sendWrikeRequest(0,
                new Map<String, String> {
                    'action' => 'find_accounts',
                    'email' => email
                }
        );
        final List<WrikeAccountInfo> accounts = new List<WrikeAccountInfo>();
        for (Object account : (List<Object>)response.get('userAccountInfoList')) {
            accounts.add(new WrikeAccountInfo((Map<String, Object>)account));
        }
        return accounts;
    }

    public void setOutboundWrikeAccount(final Id quoteId, final Integer wrikeAccountId) {
        update new SBQQ__Quote__c(
                Id = quoteId,
                WrikeAccountId__c = wrikeAccountId
        );
    }

    public void nullifyQuoteLinesQuantity(final Id quoteId) {
        final List<SBQQ__QuoteLine__c> lines = [
                SELECT Id
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
        ];
        if (!lines.isEmpty()) {
            for (SBQQ__QuoteLine__c line : lines) {
                line.SBQQ__Quantity__c = 0;
            }
            update lines;
        }
    }

    public class WrikeAccountRegistrationResult {
        private final Integer wrikeAccountId;
        private final String message;

        public WrikeAccountRegistrationResult(final Integer wrikeAccountId,
                                              final String message) {
            this.wrikeAccountId = wrikeAccountId;
            this.message = message;
        }

        public Integer getWrikeAccountId() {
            return wrikeAccountId;
        }

        public String getMessage() {
            return message;
        }
    }

    public class WrikeAccountInfo {
        @AuraEnabled
        public Decimal id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public Boolean owner {get; set;}
        @AuraEnabled
        public Boolean admin {get; set;}
        @AuraEnabled
        public String role {get; set;}

        WrikeAccountInfo(final Map<String, Object> accountInfo) {
            this.id = (Decimal)accountInfo.get('accountId');
            this.name = (String)accountInfo.get('accountName');
            this.owner = (Boolean)accountInfo.get('owner');
            this.admin = (Boolean)accountInfo.get('admin');
            this.role = (String)accountInfo.get('role');
        }
    }
}
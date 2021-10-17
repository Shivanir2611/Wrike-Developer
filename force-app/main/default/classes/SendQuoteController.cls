public with sharing class SendQuoteController {

    public WrikeQuote wQuote {get; set;}
    public Boolean isVatNumberValid {get; set;}
    public Boolean isVatValidationIgnored {get; set;}
    public String docuSignId {get; set;}
    public String purchaseOrderNumber {get; set;}
    public Opportunity relatedOpportunity {get; set;}

    private ValidationResult validationResults = new ValidationResult();
    private ValidationResult sendResults = new ValidationResult();
    private BillingInfo existingBillingInfo;
    private BillingInfo creditCardBillingInfo;
    private BillingInfo quoteBillingInfo;
    private BillingInfo selectedBillingInfo;
    private String paymentMethod;
    private Boolean opportunityValidationSuccess;

    private QuoteService quoteSrv = QuoteService.getInstance();
    private AddressService addressSrv = AddressService.getInstance();
    private ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();
    private ZuoraService zuoraSrv = ZuoraService.getInstance();
    private DatabaseService databaseSrv = DatabaseService.getInstance();
    private OpportunityBillingContactService oppBillingSrv = OpportunityBillingContactService.getInstance();

    public SendQuoteController() {
        final String quoteId = ApexPages.currentPage().getParameters().get(RequestParam.ID_PARAM);
        try {
            if (String.isBlank(quoteId)) {
                throw new LogicException('Required parameters is missing: id.');
            }
            QuoteService.WrikeQuoteWithValidation wQuoteWithValidation = this.quoteSrv
                    .findWithItemsAndOpportunityAndContactById(quoteId, true);
            this.wQuote = wQuoteWithValidation.wQuote;
            if (String.isNotBlank(wQuoteWithValidation.message)) {
                throw new LogicException(wQuoteWithValidation.message);
            }
            if (!this.wQuote.getIsProposal()) {
                throw new LogicException(StringUtils.format('Only a quote in {0} status can be sent to Zuora.', WrikeQuote.Status.PROPOSAL.name()));
            }
            final ContactBean billingContact = this.wQuote.contact;
            this.quoteBillingInfo = billingContact != null ? billingContact.getBillingInfo() : null;
            this.existingBillingInfo = zuoraSrv.findBillingInfo(this.wQuote.zuoraAccountId);

            this.creditCardBillingInfo = zuoraRestQuerySrv.findCreditCardInfoByAccountId(wQuote.zuoraAccountId);
            if(this.creditCardBillingInfo == null) {
                this.creditCardBillingInfo = zuoraRestQuerySrv.findCreditCardInfoById(wQuote.zuoraCreditCardId, false);
            }
            if(this.creditCardBillingInfo != null) {
                this.paymentMethod = 'zuoraCreditCard';
            } else if(this.quoteBillingInfo != null
                        && this.quoteBillingInfo.getPopulated()
                        && !this.existingBillingInfo.getPopulated()) {
                this.paymentMethod = 'billingContactInvoice';
            } else {
                this.paymentMethod = 'zuoraInvoice';
            }
            this.selectedBillingInfo = billingInfoByPaymentMethod(this.paymentMethod);
            this.docuSignId = DocuSignUtil.findCompletedDocuSign(this.wQuote.pdfId);
            this.isVatNumberValid = true;
            this.isVatValidationIgnored = false;
            this.relatedOpportunity = new Opportunity(
                Id = this.wQuote.opportunityId,
                StageName = 'Closed Won - Pending',
                Competitor_Lost_To__c = this.wQuote.opportunity.competitorLostTo,
                Reasons_Lost__c = this.wQuote.opportunity.reasonsLostTo,
                Sub_Reason__c = this.wQuote.opportunity.subReason,
                Lost_Reason_Detail__c = this.wQuote.opportunity.lostReasonDetail,
                Other_Competitors_Won_Lost_To__c = this.wQuote.opportunity.otherCompetitorsWonLostTo,
                Other_Won_Lost_Reasons__c = this.wQuote.opportunity.otherWonLostReasons
            );
        } catch(LogicException logicExp) {
            this.validationResults.addError(logicExp.getMessage());
        }
    }

    public ValidationResult getValidationResults() {
        return this.validationResults;
    }

    public ValidationResult getSendResults() {
        return this.sendResults;
    }

    public Boolean getIsAdmin() {
        return SettingsProvider.isAdmin();
    }

    public PageReference selectPaymentMethod() {
        this.paymentMethod = ApexPages.currentPage().getParameters().get('paymentMethod');
        this.selectedBillingInfo = billingInfoByPaymentMethod(this.paymentMethod);
        return null;
    }

    public String getPaymentMethod() {
        return this.paymentMethod;
    }

    public BillingInfo getCreditCardBillingInfo() {
        return this.creditCardBillingInfo;
    }

    public BillingInfo getExistingBillingInfo() {
        return this.existingBillingInfo;
    }

    public BillingInfo getQuoteBillingInfo() {
        return this.quoteBillingInfo;
    }

    public BillingInfo getSelectedBillingInfo() {
        return this.selectedBillingInfo;
    }

    private BillingInfo billingInfoByPaymentMethod(final String method) {
        if(method == 'zuoraCreditCard') {
            return this.creditCardBillingInfo;
        } else if(method == 'zuoraInvoice') {
            return this.existingBillingInfo;
        } else if(method == 'billingContactInvoice') {
            return this.quoteBillingInfo;
        }
        return null;
    }

    public Boolean getVatNumberRequired() {
        return this.wQuote.quoteType == WrikeQuote.QuoteType.SUBSCRIPTION && addressSrv.isVatNumberRequired(this.selectedBillingInfo.country);
    }

    public Boolean getNextAvailable() {
        return (!getVatNumberRequired() || this.isVatValidationIgnored || (String.isNotBlank(this.selectedBillingInfo.vatNumber) && this.isVatNumberValid))
                && (SettingsProvider.isDocusignOptional() || this.docuSignId != null)
                && EmailUtil.isValidEmail(this.selectedBillingInfo.email)
                && selectedBillingInfo.getPopulated()
                && String.isNotBlank(relatedOpportunity.Competitor_Lost_To__c)
                && String.isNotBlank(relatedOpportunity.Reasons_Lost__c);
    }

    public PageReference back() {
        PageReference quoteViewPage = Page.ViewQuote;
        quoteViewPage.getParameters().put(RequestParam.ID_PARAM, this.wQuote.id);
        quoteViewPage.setRedirect(true);
        return quoteViewPage;
    }

    public void checkVatNumber() {
        this.isVatValidationIgnored = false;
        ApexPages.getMessages().clear();
        if(String.isBlank(this.selectedBillingInfo.country) || String.isBlank(this.selectedBillingInfo.vatNumber)) {
            return;
        }
        if (this.selectedBillingInfo.country == this.wQuote.opportunity.billingCountryCode
                && this.selectedBillingInfo.vatNumber == this.wQuote.opportunity.vat
                && this.wQuote.opportunity.vatValidStatus == AddressService.VAT_VALID) {
            this.isVatNumberValid = true;
            return;
        }
        VatNumberDto vatNumberDto = addressSrv.checkVatNumber(this.selectedBillingInfo.country, this.selectedBillingInfo.vatNumber);
        if (!vatNumberDto.isValidationServiceAvalible) {
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, 'VAT Number validation not available.'));
            this.isVatNumberValid = false;
        }
        this.isVatNumberValid = vatNumberDto.isValid;
        if(vatNumberDto.isValid) {
            final String companyName = vatNumberDto.name != null ? vatNumberDto.name : 'No Name';
            final String companyAddress = vatNumberDto.address != null ? vatNumberDto.address : '';
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.CONFIRM, companyName + ' ' + companyAddress));
        } else {
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Not valid VAT Number for ' + this.selectedBillingInfo.country));
        }
    }

    public void validateSendQuoteOperation() {
        Savepoint opportunitySavePoint = Database.setSavepoint();
        this.opportunityValidationSuccess = updateOpportunity(this.wQuote.opportunityId, this.selectedBillingInfo, this.wQuote.opportunity.billingContact);
        if(!opportunityValidationSuccess){
            return;
        }
        Database.rollback(opportunitySavePoint);
        quoteSrv.addSendQuoteOperation(this.wQuote.Id); // Acquire send operation lock
    }

    public PageReference sendQuote() {
        if(!opportunityValidationSuccess){
            return null;
        }
        this.sendResults.clear();
        if(!getNextAvailable()) {
            this.sendResults.addError('Send action is not available.');
        } else {
            final AvalaraValidationService.Result validation = AvalaraValidationService.validate(this.selectedBillingInfo);
            if(!validation.isValid()) {
                this.sendResults.addError('Please provide a valid postal code for the selected state.');
            } else {
                this.selectedBillingInfo.taxExempt = this.wQuote.taxExempt;
                this.selectedBillingInfo.taxExemptCertificateId = this.wQuote.taxExemptCertificateId;
                final SendQuoteRequest request = new SendQuoteRequest.Builder(this.wQuote.Id)
                        .setBillingInfo(this.selectedBillingInfo)
                        .setVatNumber(this.selectedBillingInfo.vatNumber)
                        .setCreditCardId(this.paymentMethod == 'zuoraCreditCard' ? this.creditCardBillingInfo.id : null)
                        .setPurchaseOrderNumber(purchaseOrderNumber)
                        .build();
                final Boolean restMode = Settings__c.getOrgDefaults().ZuoraRestSubscriptions__c == true;
                final WrikeQuoteZuoraService.SubscriptionResult subscriptionResult = restMode
                        ? ZuoraQuoteSubscriptionService.getInstance().sendQuote(request)
                        : WrikeQuoteZuoraService.getInstance().sendQuote(request);
                if(subscriptionResult.isSuccess()) {
                    updateOpportunity(this.wQuote.opportunityId, this.selectedBillingInfo, this.wQuote.opportunity.billingContact);
                    return back();
                }
                final String errorMessage = subscriptionResult.getErrorMessage();
                this.sendResults.addError(errorMessage != null ? errorMessage : 'Unexpected error during sending quote to Zuora.');
            }
        }
        quoteSrv.removeSendQuoteOperation(this.wQuote.Id); // Quote was not sent, release operation lock
        return null;
    }

    public Boolean getVatOptional() {
        return SettingsProvider.isVatOptional();
    }
    
    private Boolean updateOpportunity(Id oppId, BillingInfo billingAddress, String billingContact) {
        final Opportunity opportunity = new Opportunity(
            Id = oppId,
            StageName = 'Closed Won - Pending',
            Competitor_Lost_To__c = this.relatedOpportunity.Competitor_Lost_To__c,
            Reasons_Lost__c = this.relatedOpportunity.Reasons_Lost__c,
            Sub_Reason__c = this.relatedOpportunity.Sub_Reason__c,
            Lost_Reason_Detail__c = this.relatedOpportunity.Lost_Reason_Detail__c,
            Other_Competitors_Won_Lost_To__c = this.relatedOpportunity.Other_Competitors_Won_Lost_To__c,
            Other_Won_Lost_Reasons__c = this.relatedOpportunity.Other_Won_Lost_Reasons__c
        );
        if(String.isNotEmpty(billingContact)) {
            final Contact contact = ContactQueryService.getInstance().findContactWithAddressById(billingContact);
            if(contact != null) {
            	billingAddress = oppBillingSrv.getUpdatedBillingAddress(contact, billingAddress, opportunity);
            }
        }
        DatabaseService.Result result = oppBillingSrv.updateOpportunityBillingContact(billingAddress, opportunity, this.wQuote.accountId);
        if(!result.isSuccess()) {
        	ApexPageMessageUtils.addError('Please review the error on Opportunity before Sending to Zuora: ' + result.getErrorMessage());
        }
        return result.isSuccess();
    }
}
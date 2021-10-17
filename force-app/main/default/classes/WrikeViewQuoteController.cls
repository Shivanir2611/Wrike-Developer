public with sharing class WrikeViewQuoteController {

    public WrikeQuote wQuote {get; set;}
    public InvoicePreview invoicePreview {get; set;}
    public Boolean isQuoteValid {get; set;}
    public Id existingPrimaryQuoteId {get; set;}

    private final QuoteService quoteSrv = QuoteService.getInstance();
    private final WrikeQuotePdfService wrikeQuotePdfSrv = WrikeQuotePdfService.getInstance();
    private final AttachmentService attachmentSrv = AttachmentService.getInstance();
    private final ApprovalService approvalSrv = ApprovalService.getInstance();
    private final UserService userSrv = UserService.getInstance();
    private final OpportunityContactRoleQueryService opportunityContactRoleQuerySrv = OpportunityContactRoleQueryService.getInstance();
    private final QuoteValidationService quoteValidationSrv = QuoteValidationService.getInstance();
    private final QuoteDateService subscriptionQuoteDateSrv = SubscriptionQuoteDateService.getInstance();
    private final UserRecordAccessService userRecordAccessSrv = UserRecordAccessService.getInstance();
    private static final Logger log = Logger.create(WrikeViewQuoteController.class);
    private final OpportunityProductService oppProductSrv = OpportunityProductService.getInstance();

    private ValidationResult validationResults = new ValidationResult();
    private String wQuoteId;
    private Attachment pdf;
    private User currentUser;

    public WrikeViewQuoteController(final ApexPages.StandardController standardController) {
        this.validationResults.clear();
        this.wQuoteId = standardController.getId();
        try {
            QuoteService.WrikeQuoteWithValidation wQuoteWithValidation = quoteSrv.findAndValidate(wQuoteId, true);
            this.wQuote = wQuoteWithValidation.wQuote;
            this.isQuoteValid = wQuoteWithValidation.isValid();
            this.existingPrimaryQuoteId = quoteSrv.findExistingPrimaryQuoteId(wQuoteId, wQuote.opportunityId);
            if (!this.wQuote.getIsSent()) {
                this.validationResults.addError(wQuoteWithValidation.message);
            }
            final String quoteCurrency = this.wQuote.getCurrencyCode();
            final String opportunityCurrency = this.wQuote.opportunity.currencyCode;
            if(quoteCurrency != opportunityCurrency) {
                this.validationResults.addError(StringUtils.format(
                        'The Quote currency ({0}) does not match the Opportunity currency ({1}). Please create a new Quote.',
                        quoteCurrency, opportunityCurrency));
            }
            if (this.wQuote.getIsEmptyOrOnlyExistingOrRemovedProducts()) {
                if (this.wQuote.getIsAmendment()) {
                    this.validationResults.addInfo('There are only existing/removed products in the quote.');
                } else if (this.wQuote.getIsSubscription()) {
                    this.validationResults.addInfo('There are no products in the quote.');
                } else if (this.wQuote.getIsRenewal()) {
                    this.validationResults.addInfo('There are only removed products in the quote.');
                }
            }
            this.pdf = this.wQuote.pdfId != null ? attachmentSrv.findById(this.wQuote.pdfId) : null;
            if (this.wQuote.getIsProposal() && this.pdf == null) {
                this.validationResults.addInfo('Quote in Proposal state but PDF does not exist. It is invalid.');
            }
            this.currentUser = userSrv.findUserById(UserInfo.getUserId());
            if (!this.wQuote.getIsSent() && !this.wQuote.getIsDraft() && !this.wQuote.getIsCancelled()) {
                final WrikeQuoteZuoraService.SubscriptionPreview subscriptionPreview = quoteSrv.getSavedSubscriptionPreview(wQuoteId);
                if(subscriptionPreview != null) {
                    this.invoicePreview = subscriptionPreview.getInvoicePreview();
                }
            }
            if (this.wQuote.getIsProposal() && this.pdf != null && !getIsAdmin() && !getIsBilling()) {
                if (this.wQuote.hasCustomDeployment) {
                    this.validationResults.addInfo('Since this quote includes a custom deployment: please attach ' +
                            'signed SOW to Opp, make a note of Wrike Task link(s), then mark this Opportunity ' +
                            'as Closed Won - Pending for Billing to process.');
                } else if (this.wQuote.autoRenewalRemoval) {
                    this.validationResults.addInfo('The quote cannot be sent to Zuora because it\'s set to not ' +
                            'automatically renew. Please switch the opportunity to Close-Won Pending and the billing ' +
                            'team will be able to process it for you.');
                } else if (this.wQuote.taxExempt) {
                    this.validationResults.addInfo('This deal has tax exemption, please add the certificate to ' +
                            'Opportunity Attachments and use the Closed Won - Pending stage for manual processing.');
                }
            }
            if (!this.wQuote.getIsAgencyVertical()
                    && this.wQuote.agencyReliefOfferDiscount
                    && this.wQuote.primary
                    && this.pdf == null) {
                this.validationResults.addInfo('Agency Relief Offer Discount cannot be checked if "Agencies" ' +
                        'is not included in the value for Vertical Segment field on the Opportunity.');
            }
        } catch(LogicException logicExp) {
            this.validationResults.addFatal(logicExp.getMessage());
        }
    }

    public QuoteBundle getQuoteBundle() {
        return this.invoicePreview == null ? null : new QuoteBundle.Builder(
                this.wQuote,
                this.invoicePreview.items
        ).build();
    }

    public ValidationResult getValidationResults() {
        return this.validationResults;
    }

    public Map<String, String> getAmendmentTypeToDescription() {
        return SettingsProvider.getAmendmentTypeToDescription();
    }

    public String getWrikeAccountUrl() {
        return SettingsProvider.getWrikeSupportappURL() + 'supportapp/?account=' + this.wQuote.wrikeAccountId;
    }

    public Attachment getPdf() {
        return this.pdf;
    }

    public PageReference generatePreview() {
        final QuoteService.StatusLock statusLock = quoteSrv.getStatusLock(this.wQuoteId);
        final WrikeQuote quote = quoteSrv.findWithItemsById(this.wQuoteId);
        final WrikeQuoteZuoraService.SubscriptionPreview preview = generateAndValidatePreview(quote, statusLock);
        if(preview != null) {
            this.invoicePreview = preview.getInvoicePreview();
            if (quoteSrv.setDraftPreview(statusLock, this.invoicePreview)) {
                this.wQuote.total = invoicePreview.totalChargeAmount;
                this.wQuote.deltaMrr = invoicePreview.deltaMrr;
            }
        }
        return null;
    }

    private WrikeQuoteZuoraService.SubscriptionPreview generateAndValidatePreview(final WrikeQuote quote, final QuoteService.StatusLock statusLock) {
        this.validationResults.clear();
        final Boolean restMode = Settings__c.getOrgDefaults().ZuoraRestSubscriptions__c == true;
        final WrikeQuoteZuoraService.SubscriptionPreview preview = restMode
                ? ZuoraQuoteSubscriptionService.getInstance().createSubscriptionPreview(statusLock)
                : WrikeQuoteZuoraService.getInstance().createSubscriptionPreview(statusLock);
        if(!preview.isSuccess()) {
            if(String.isNotBlank(preview.getErrorMessage())) {
                this.validationResults.addInfo(preview.getErrorMessage());
            } else {
                this.validationResults.addInfo('Unexpected error during quote preview generation.');
            }
        } else if (preview.getInvoicePreview().totalChargeAmount < 0) {
            this.validationResults.addInfo('Total charge amount is negative. Such quotes are not allowed.');
        } else if (this.wQuote.getIsAmendment() && preview.getInvoicePreview().deltaMrr > 0 && Date.today() > quote.effectiveDate) {
            this.validationResults.addInfo('The effective date in the past is allowed for downgrade quotes only. Please change the effective date.');
        } else {
            return preview;
        }
        return null;
    }

    public PageReference previewAndActivate() {
        final QuoteService.StatusLock statusLock = quoteSrv.getStatusLock(this.wQuoteId);
        final WrikeQuote quote = quoteSrv.findWithItemsById(this.wQuoteId);
        final WrikeQuoteZuoraService.SubscriptionPreview preview = generateAndValidatePreview(quote, statusLock);
        if(preview != null) {
            if(preview.isSuccess()) {
                final Boolean savedToWrikeOrOutbound = quote.getOutbound() || WrikeUtil.sendQuoteToWrike(new QuoteUtil.QuoteWrapper(quote));
                if(savedToWrikeOrOutbound) {
                    final DatabaseService.Result result = quoteSrv.saveSubscriptionPreview(statusLock, preview);
                    if(result.isSuccess()) {
                        this.wQuote.status = WrikeQuote.Status.TRIAL;
                        quoteSrv.markPrimary(this.wQuoteId);
                        oppProductSrv.deleteOpportunityLineItems(quote);
                        oppProductSrv.createOpportunityLineItems(quote);
                        return submitForApproval();
                    } else {
                        log.errorToLog('Failed to save quote preview: '  + this.wQuoteId, result.getErrorMessage());
                        log.saveLog();
                        this.validationResults.addInfo('Failed to activate the quote.');
                    }
                } else {
                    this.validationResults.addInfo('Failed to send the quote to Wrike for a feature trial activation.');
                }
            } else {
                this.validationResults.addInfo('Failed to calculate quote preview.');
            }
        }
        return null;
    }

  public PageReference generatePdf() {
    return generatePdf(false);
  }

  public PageReference generatePdfNoListPrice() {
    return generatePdf(true);
  }

  private PageReference generatePdf(final Boolean noListPrice) {
    this.validationResults.clear();
    try {
      final Id pdfId = wrikeQuotePdfSrv.generateQuotePdf(this.wQuote.Id, noListPrice);
      if (pdfId == null) {
        this.validationResults.addError('Unexpected error during PDF generation.');
      }
      return refresh();
    } catch (LogicException logicExp) {
      this.validationResults.addInfo(logicExp.getMessage());
    }
    return null;
  }

    public PageReference deletePdf() {
        wrikeQuotePdfSrv.deleteQuotePdf(this.wQuote.Id);
        return refresh();
    }

    private PageReference refresh() {
        final PageReference refreshPage = Page.ViewQuote;
        refreshPage.getParameters().put(RequestParam.ID_PARAM, this.wQuoteId);
        refreshPage.setRedirect(true);
        return refreshPage;
    }

    public PageReference editProducts() {
        PageReference quoteEditPage = getQuotePage();
        quoteEditPage.getParameters().put(RequestParam.QUOTE_ID, this.wQuoteId);
        quoteEditPage.getParameters().put(RequestParam.STEP, WrikeQuoteBaseController.PRODUCTS_TABLE_STEP);
        quoteEditPage.getParameters().put(RequestParam.RETURN_URL, ApexPages.currentPage().getUrl());
        return quoteEditPage;
    }

    public PageReference editQuoteDetails() {
        PageReference quoteEditPage = getQuotePage();
        quoteEditPage.getParameters().put(RequestParam.QUOTE_ID, this.wQuoteId);
        quoteEditPage.getParameters().put(RequestParam.STEP, WrikeQuoteBaseController.QUOTE_DETAILS_STEP);
        quoteEditPage.getParameters().put(RequestParam.RETURN_URL, ApexPages.currentPage().getUrl());
        return quoteEditPage;
    }

    public PageReference sendQuote() {
        if(wQuote.getOutbound() && wQuote.zuoraAccountId == null) {
            final PageReference accountRegistrationPage = Page.RegisterNewWrikeAccount;
            accountRegistrationPage.getParameters().put(RequestParam.ID_PARAM, this.wQuoteId);
            return accountRegistrationPage;
        }
        final PageReference sendQuotePage = Page.SendQuote;
        sendQuotePage.getParameters().put(RequestParam.ID_PARAM, this.wQuoteId);
        return sendQuotePage;
    }

    public PageReference submitForApproval() {
        this.validationResults.clear();
        approvalSrv.submitForApproval(this.wQuote.Id, null);
        return refresh();
    }

    public PageReference cancelApproval() {
        approvalSrv.cancelRequest(this.wQuote.id);
        return refresh();
    }

    public PageReference moveToDraft() {
        final QuoteService.StatusLock statusLock = quoteSrv.getStatusLock(this.wQuote.id);
        this.quoteSrv.removeInvoicePreview(statusLock);
        return refresh();
    }

    public PageReference sendWithDocuSign() {
        final PageReference redirect = Page.dsfs__DocuSign_CreateEnvelope;
        redirect.setRedirect(true);
        redirect.getParameters().put('DSEID', '0');
        redirect.getParameters().put('SourceID', this.wQuote.id);
        redirect.getParameters().put('LA', '1');
        if (this.wQuote.contact != null && this.wQuote.contact.email != null && !this.wQuote.contact.email.contains('+'))  {
            redirect.getParameters().put('CRL', createCustomRecipientList(
                this.wQuote.contact.email, this.wQuote.contact.firstname, this.wQuote.contact.lastname));
        } else {
            List<OpportunityContactRole> opportunityContactRoles = opportunityContactRoleQuerySrv
                .findByOpportunityId(this.wQuote.opportunityId);
            final List<String> customRecipientList = new List<String>();
            for (OpportunityContactRole contactRole : opportunityContactRoles) {
                if (contactRole.Contact.Email != null && !contactRole.Contact.Email.contains('+')) {
                    customRecipientList.add(createCustomRecipientList(
                        contactRole.Contact.Email, contactRole.Contact.FirstName, contactRole.Contact.LastName));
                }
            }
            if (customRecipientList.size() > 0) {
                redirect.getParameters().put('CRL', String.join(customRecipientList, ','));
            }
        }
        final String customSubject = SettingsProvider.getDocusignSubject();
        if(String.isNotBlank(customSubject)) {
            redirect.getParameters().put('CES', escapeControlCharacters(customSubject));
        }
        final String customMessage = SettingsProvider.getDocusignMessage();
        if(String.isNotBlank(customMessage)) {
            redirect.getParameters().put('CEM', escapeControlCharacters(customMessage));
        }
        return redirect;
    }

    private String escapeControlCharacters(final String text) {
        return text.replaceAll('\\n', '\\\\n').replaceAll('[\\s]+', ' ');
    }

    public PageReference deleteQuote() {
        final Boolean isSuccess = quoteSrv.deleteQuote(this.wQuote);
        if (!isSuccess) {
            this.validationResults.addError('Error occurred during quote deletion.');
            return null;
        }
        final PageReference viewOpportunityPage = new PageReference('/' + this.wQuote.opportunityId);
        viewOpportunityPage.setRedirect(true);
        return viewOpportunityPage;
    }

    public Boolean getHasDeleteAccess() {
        return userRecordAccessSrv.hasDeleteAccess(UserInfo.getUserId(), this.wQuote.id);
    }

    public Boolean getHasEditAccess() {
        return userRecordAccessSrv.hasEditAccess(UserInfo.getUserId(), this.wQuote.id);
    }

    public PageReference cancelQuote() {
        final Boolean isSuccess = quoteSrv.cancelQuote(this.wQuote.id);
        if (!isSuccess) {
            this.validationResults.addError('Error occurred during quote cancellation.');
            return null;
        }
        oppProductSrv.deleteOpportunityLineItems(this.wQuote);
        return refresh();
    }

    public PageReference restoreQuote() {
        previewAndActivate();
        final Boolean isSuccess = quoteSrv.restoreQuote(this.wQuote);
        if (!isSuccess) {
            this.validationResults.addError('Error occurred during quote restoring.');
            return null;
        }
        return refresh();
    }

    public PageReference duplicate() {
        this.validationResults.clear();
        if (!this.wQuote.getIsSubscription()) {
            this.validationResults.addError('You can create duplicate only for subscription quote.');
            return null;
        }

        WrikeQuote newQuote = this.wQuote.cloneQuote(true);
        newQuote.id = null;
        newQuote.name = newQuote.getOriginalName();
        newQuote.effectiveDate = Date.today();
        newQuote.validUntil = subscriptionQuoteDateSrv.getMaxValidUntil(newQuote);
        final Date minInvoiceDate = subscriptionQuoteDateSrv.getMinInvoiceDate(newQuote.effectiveDate);
        final Date maxInvoiceDate = subscriptionQuoteDateSrv.getMaxInvoiceDate(newQuote.effectiveDate);
        if (newQuote.invoiceDate < minInvoiceDate || newQuote.invoiceDate > maxInvoiceDate) {
            newQuote.invoiceDate = newQuote.effectiveDate;
        }
        newQuote.originalQuoteId = this.wQuote.id;
        newQuote.savedHashCode = null;
        if (wQuote.getIsApproved() || wQuote.getIsProposal()) {
            newQuote.isOriginalQuoteApproved = true;
        }

        this.validationResults.addError(quoteValidationSrv.validateQuoteProductsBeforeSave(newQuote));
        if (this.validationResults.getIsNotValid()) {
            return null;
        }

        try {
            final QuoteService.ZuoraAccountResult zuoraAccountResult = this.quoteSrv.sendNewQuoteToWrike(newQuote);
            newQuote.zuoraAccountId = zuoraAccountResult.getZuoraAccountId();
            newQuote.dataCenter = zuoraAccountResult.getDataCenter();
            this.quoteSrv.upsertQuoteWithProducts(newQuote);
            return new PageReference('/' + newQuote.id);
        } catch(LogicException logicExp) {
            this.validationResults.addError(logicExp.getMessage());
            return null;
        }
    }

    public Boolean getIsDuplicateVisible() {
        return this.wQuote != null && this.wQuote.getIsSubscription()
            && this.wQuote.getIsProposal() && this.wQuote.effectiveDate < Date.today();
    }

    public Boolean getIsAdmin() {
        return SettingsProvider.isAdmin();
    }

    public Boolean getIsBilling() {
        return SettingsProvider.isBillingProfile();
    }

    private String createCustomRecipientList(final String email, final String firstName, final String lastName) {
        List<String> recipientParts = new List<String>();
        recipientParts.add(StringUtils.format('Email~{0}', email));
        if (String.isNotBlank(firstName)) {
            recipientParts.add(StringUtils.format('FirstName~{0}', firstname));
        }
        if (String.isNotBlank(lastname)) {
            recipientParts.add(StringUtils.format('LastName~{0}', lastname));
        }
        return String.join(recipientParts, ';');
    }

    private PageReference getQuotePage() {
        if (this.wQuote.getIsSubscription()) {
            return Page.SubscriptionQuote;
        } else if (this.wQuote.getIsAmendment()) {
            return Page.AmendmentQuote;
        } else if (this.wQuote.getIsRenewal()) {
            return Page.RenewalQuote;
        }
        return null;
    }
}
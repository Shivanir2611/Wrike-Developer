public with sharing class CPQQuoteController {

    private final static CPQQuoteService quoteSrv = CPQQuoteService.getInstance();
    private final static CPQQuoteQueryService quoteQuerySrv = CPQQuoteQueryService.getInstance();
    private final static ApprovalService approvalSrv = ApprovalService.getInstance();
    private final static CPQOrderService orderSrv = CPQOrderService.getInstance();
    private final static CPQOrderQueryService orderQuerySrv = CPQOrderQueryService.getInstance();
    private final static CPQBillingScheduleService billingScheduleSrv = CPQBillingScheduleService.getInstance();
    private final static BillToShipToQueryService billToShipToQuerySrv = BillToShipToQueryService.getInstance();
    private final static DocuSignRestApiService docuSignRestApiSrv = DocuSignRestApiService.getInstance();
    private final static OpportunityQueryService opportunityQuerySrv = OpportunityQueryService.getInstance();
    private final static ContractService contractSrv = ContractService.getInstance();

    @AuraEnabled
    public static CPQQuote findQuoteById(final Id quoteId) {
        return quoteSrv.findQuoteById(quoteId);
    }

    @AuraEnabled
    public static void activateQuote(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (!quote.getQuoteBlocked()
                && quote.getStartApprovalMessage() == null
                && quote.getIsDraft()) {
            quoteSrv.startApproval(quote, quote.approvalRequired);
        }
    }

    @AuraEnabled
    public static Boolean getPartnerUpdateAllowed(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        return (!quote.getQuoteBlocked()
                || quote.getOpportunityPartnersInconsistent())
                && quote.getAddPartnerAllowed();
    }

    @AuraEnabled
    public static CPQQuote makeQuotePrimary(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked()
                || quote.getIsDocuSignSent()
                || quote.getIsDocuSignSigned()
                || quote.getIsOrdered()) {
            return quote;
        }
        quoteSrv.makePrimary(quote);
        return quoteSrv.findQuoteById(quoteId);
    }

    @AuraEnabled
    public static String getQuoteLineEditorUrl(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked()) {
            return null;
        }
        final PageReference redirect = Page.SBQQ__sb;
        redirect.getParameters().put('id', quoteId);
        return redirect.getUrl();
    }

    @AuraEnabled
    public static String getCloneUrl(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked()
                || quote.getIsDocuSignSigned()
                || quote.getIsOrdered()) {
            return null;
        }
        final PageReference redirect = Page.SBQQ__CloneLineItems;
        redirect.getParameters().put('id', quoteId);
        return redirect.getUrl();
    }

    @AuraEnabled
    public static Boolean getDocumentIsNotGeneratedYet(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        return !quote.getQuoteBlocked()
                && (quote.getIsDraft()
                        || quote.getIsPendingApproval()
                        || quote.getIsApproved());
    }

    @AuraEnabled
    public static String getApprovalPreviewUrl(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (!quote.getQuoteBlocked()
                && quote.getStartApprovalMessage() == null
                && quote.getIsDraft()) {
            quoteSrv.updateQuoteBeforeApprovalPreview(quote);
            final PageReference redirect = Page.sbaa__PreviewApprovals;
            redirect.getParameters().put('Id', quoteId);
            redirect.getParameters().put('hideSubmit', '1');
            return redirect.getUrl();
        }
        return null;
    }

    @AuraEnabled
    public static void changeQuoteStatusToDraft(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (!quote.getQuoteBlocked()
                && (quote.getIsPendingApproval()
                        || quote.getIsApproved()
                        || quote.getIsRejected())) {
            if (quote.getIsPendingApproval()) {
                quoteSrv.recallApproval(quoteId);
            }
            quoteSrv.resetQuoteToDraft(quote);
        }
    }

    @AuraEnabled
    public static void changeQuoteStatusToCancelled(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (!quote.getQuoteBlocked() && quote.getIsDocuSignSigned()) {
            quoteSrv.cancelQuote(quote);
        }
    }

    @AuraEnabled
    public static String getPreviewUrl(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked()
                || quote.getPreviewMessage() != null
                || !quote.getIsDraft()
                        && !quote.getIsPendingApproval()
                        && !quote.getIsApproved()) {
            return null;
        }
        if (quote.getIsDraft()) {
            quoteSrv.calculateBillingScheduleAndUpdateQuote(quoteId);
        }
        quoteSrv.updateDiscountAndWatermarkFlags(quoteId);
        final PageReference redirect = Page.documentPreview;
        redirect.getParameters().put('quoteId', quoteId);
        return redirect.getUrl();
    }

    @AuraEnabled
    public static Boolean validateAddress(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        final AvalaraValidationService.Result result =
                AvalaraValidationService.validate(quote.billToCountryCode, quote.billToStateCode, quote.billToZip);
        return result.isValid();
    }

    @AuraEnabled
    public static CPQQuote initiateDocumentGeneration(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked()
                || quote.getGenerateDocumentMessage() != null
                || !quote.getIsApproved()) {
            return quote;
        }
        quoteSrv.initiateDocumentGeneration(quote);
        return quoteSrv.findQuoteById(quoteId);
    }

    @AuraEnabled
    public static String getDocuSignUrl(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (!quote.getQuoteBlocked() && quote.getIsDocumentGenerated()) {
            final PageReference redirect = Page.dsfs__DocuSign_CreateEnvelope;
            redirect.getParameters().put('DSEID', '0');
            redirect.getParameters().put('LA', '1');
            redirect.getParameters().put('SourceID', quoteId);
            final List<String> recipients = new List<String>();
            final QS_Bill_To_Ship_To__c billTo = billToShipToQuerySrv.findContactById(quote.billToId);
            final String wrikeRecipientEmail = CPQSettings__c.getOrgDefaults().DocuSignWrikeRecipientEmail__c;
            recipients.add(new DocuSignUtil.Recipient(1, billTo.QS_Attention_To__c, '', billTo.QS_Email__c, 'A').toString());
            if (!quote.preSignDocument) {
                recipients.add(new DocuSignUtil.Recipient(2, 'Wrike', 'Signer', wrikeRecipientEmail, 'B').toString());
            }
            recipients.add(new DocuSignUtil.Recipient(quote.preSignDocument ? 2 : 3, UserInfo.getFirstName(), UserInfo.getLastName(), UserInfo.getUserEmail(), 'C').toString());
            redirect.getParameters().put('CRL', String.join(recipients, ','));
            redirect.getParameters().put('CCRM', 'A~Signer 1;B~Signer 2;C~Carbon Copy');
            redirect.getParameters().put('CCTM', 'A~Signer;B~Signer;C~Carbon Copy');
            final Integer daysLeft = Math.max(DateUtils.getPacificLocalDate().daysBetween(quote.expirationDate), 1);
            redirect.getParameters().put('RES', '1,2,3,1,' + daysLeft + ',' + (daysLeft < 2 ? '0' : '2'));
            return redirect.getUrl();
        }
        return null;
    }

    @AuraEnabled
    public static CPQQuote cancelDocuSignEnvelope(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked() || !quote.getIsDocuSignSent()) {
            return quote;
        }
        final String envelopeId = quote.docuSignEnvelopeExternalId;
        final String envelopeStatus = docuSignRestApiSrv.getEnvelopeStatus(envelopeId);
        if ('created'.equals(envelopeStatus) || 'sent'.equals(envelopeStatus) || 'delivered'.equals(envelopeStatus)) {
            final Boolean success = docuSignRestApiSrv.voidEnvelope(envelopeId);
            if (success) {
                quoteSrv.setDocumentGeneratedStatus(quoteId);
            }
        } else if ('voided'.equals(envelopeStatus)) {
            quoteSrv.setDocumentGeneratedStatus(quoteId);
        } else if ('declined'.equals(envelopeStatus)) {
            quoteSrv.setDocuSignDeclinedStatus(quoteId);
        } else if ('completed'.equals(envelopeStatus)) {
            quoteSrv.setDocuSignSignedStatus(quoteId);
        }
        return quoteSrv.findQuoteById(quoteId);
    }

    @AuraEnabled
    public static CPQQuote setDocumentGeneratedStatus(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked() || !quote.getIsDocuSignDeclined()) {
            return quote;
        }
        quoteSrv.setDocumentGeneratedStatus(quoteId);
        return quoteSrv.findQuoteById(quoteId);
    }

    @AuraEnabled
    public static CPQQuote deleteQuoteDocument(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked() || !quote.getIsDocumentGenerated()) {
            return quote;
        }
        quoteSrv.deleteDocument(quoteId);
        return quoteSrv.findQuoteById(quoteId);
    }

    @AuraEnabled
    public static Boolean beforeDeleteQuote(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getIsDocuSignSigned() || quote.getIsOrdered()) {
            return false;
        }
        if (quote.getIsRenewal()) {
            quoteSrv.updateContractActivatedRenewalQuote(quote);
        }
        return true;
    }

    @AuraEnabled
    public static CPQQuote generateOrderAndContract(final Id quoteId) {
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        if (quote.getQuoteBlocked()
                || !quote.getIsDocumentGenerated()
                        && !quote.getIsDocuSignSigned()) {
            return quote;
        }
        quoteSrv.createOrder(quoteId);
        final Order order = orderQuerySrv.findOrderByQuoteId(quoteId);
        orderSrv.calculateBillingSchedule(order);
        orderSrv.createContract(order.Id);
        if (quote.getIsAmendment()) {
            final Id amendedContractId = opportunityQuerySrv.findAmendedContractId(quote.opportunityId);
            contractSrv.updateContractFromQuote(amendedContractId, quoteId);
        }
        return quoteSrv.findQuoteById(quoteId);
    }

    @AuraEnabled
    public static Id getExistingPrimaryQuoteId(final Id quoteId) {
        final Id opportunityId = quoteQuerySrv.findOpportunityIdByQuoteId(quoteId);
        return quoteQuerySrv.findExistingPrimaryQuoteId(opportunityId);
    }
}
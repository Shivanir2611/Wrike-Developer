public class WrikeSubscriptionQuoteController extends WrikeQuoteBaseController {

    private Integer initialRenewalTerm;

    public WrikeSubscriptionQuoteController() {
        if (this.wQuote != null) {
            this.initialRenewalTerm = this.wQuote.renewalTerm;
        }
    }

    protected override void initServices() {
        this.quoteDateSrv = SubscriptionQuoteDateService.getInstance();
    }

    protected override void initQuote(final String opportunityId, String zuoraAccountId) {
        if (String.isNotBlank(opportunityId)) {
            final OpportunityDto opportunity = OpportunityValidationService.getInstance().findByIdAndValidate(opportunityId);
            this.wQuote = setValues(new WrikeQuote(), opportunity);
            this.wQuote.quoteType = opportunity.wrikeAccountId != null
                                    ? WrikeQuote.QuoteType.SUBSCRIPTION
                                    : WrikeQuote.QuoteType.SUBSCRIPTION_OUTBOUND;
            this.wQuote.status = WrikeQuote.Status.DRAFT;
            this.wQuote.effectiveDate = Date.today();
            this.wQuote.validUntil = this.quoteDateSrv.getValidUntil(this.wQuote);
            this.wQuote.invoiceDate = this.wQuote.effectiveDate;
            this.wQuote.newTerm = 12;
            this.wQuote.renewalTerm = 12;
            this.wQuote.setCurrency(opportunity.currencyCode);
            this.wQuote.paymentTerm = WrikeQuote.NET_30;
            this.wQuote.numberOfTeams = -1;
        }
    }

    public WrikeSubscriptionQuoteController getInstance() {
        return this;
    }

    protected override List<String> getStepsOrder() {
        return new List<String>{ getQuoteDetailsStepName(), getProductsTableStepName() };
    }

    protected override Boolean nextStepHandler() {
        if (this.step == getQuoteDetailsStepName()) {
            Boolean isRenewalTermNotFilled = this.wQuote.renewalTerm == null;
            if (isRenewalTermNotFilled) {
                validationResults.addError('Please fill out all required fields.');
                return false;
            }
            if (!validateQuoteDetails()) {
                return false;
            }
            for (WrikeQuoteItem quoteItem : this.wQuote.items) {
                quoteItem.product.term = this.wQuote.newTerm;
            }
        }
        return true;
    }

    protected override void previousStepHandler() {}

    public override Boolean getIsNeedResetProductState() {
        Boolean isNeedResetProductStateByNewTerm = super.getIsNeedResetProductState();
        return (isNeedResetProductStateByNewTerm
            || (this.initialRenewalTerm != null && this.wQuote.renewalTerm != null
                && this.wQuote.renewalTerm != this.initialRenewalTerm))
            && this.wQuote.items.size() > 0;
    }
}
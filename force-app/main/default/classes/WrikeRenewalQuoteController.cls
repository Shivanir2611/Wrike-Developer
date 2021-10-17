public class WrikeRenewalQuoteController extends WrikeQuoteBaseController{

    private WrikeQuote initQuoteState;

    private static final Logger log = Logger.create(WrikeRenewalQuoteController.class);

    public WrikeRenewalQuoteController() {
        if (!SettingsProvider.isRenewalQuotesAvailable()) {
            this.validationResults.addFatal('Renewal Quotes not available for you!');
            return;
        }
        if (this.wQuote != null) {
            this.initQuoteState = this.wQuote.cloneQuote();
        }
    }

    protected override void initServices() {
        this.quoteDateSrv = AmendmentQuoteDateService.getInstance();
    }

    protected override void initQuote(String opportunityId, String zuoraAccountId) {
        if (String.isNotBlank(opportunityId) && String.isNotBlank(zuoraAccountId)) {
            final OpportunityDto opportunityDtoForQuote = OpportunityValidationService.getInstance()
                    .findByIdAndValidate(opportunityId);
            this.wQuote = this.quoteSrv.findInZuora(zuoraAccountId);
            this.wQuote = setValues(this.wQuote, opportunityDtoForQuote);
            this.wQuote.quoteType = WrikeQuote.QuoteType.RENEWAL;
            this.wQuote.status = WrikeQuote.Status.DRAFT;
            this.wQuote.newTerm = this.wQuote.currentTerm;
            this.wQuote.setCurrency(opportunityDtoForQuote.currencyCode);
            initialNewTerm = this.wQuote.currentTerm;
            initialNumberOfTeams = this.wQuote.numberOfTeams;
            this.wQuote.paymentTerm = WrikeQuote.NET_30;
        }
    }

    public WrikeRenewalQuoteController getInstance() {
        return this;
    }

    protected override Boolean nextStepHandler() {
        if (this.step == getQuoteDetailsStepName()) {
            if (!validateQuoteDetails()) {
                return false;
            }

            final Boolean isNeedResetProductState = getIsNeedResetProductState();
            for (Integer itemIndex = 0; itemIndex < this.wQuote.items.size(); itemIndex++) {
                WrikeQuoteItem quoteItem = this.wQuote.items.get(itemIndex);
                if (isNeedResetProductState && quoteItem.getIsExisting()) {
                    quoteItem.state = WrikeQuoteItem.State.REMOVED;
                }
            }
        }
        return true;
    }

    protected override void previousStepHandler() {}

    protected override List<String> getStepsOrder() {
        return new List<String>{getQuoteDetailsStepName(), getProductsTableStepName()};
    }
}
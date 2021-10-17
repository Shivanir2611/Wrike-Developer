public class WrikeAmendmentQuoteController extends WrikeQuoteBaseController {

    private WrikeQuote initQuoteState;
    private WrikeQuote.AmendmentType initAmendmentType;

    private static final Logger log = Logger.create(WrikeAmendmentQuoteController.class);

    public WrikeAmendmentQuoteController() {
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
            this.wQuote.quoteType = WrikeQuote.QuoteType.AMENDMENT;
            this.wQuote.status = WrikeQuote.Status.DRAFT;
            this.wQuote.setCurrency(opportunityDtoForQuote.currencyCode);
            this.initAmendmentType = null;
            this.wQuote.paymentTerm = WrikeQuote.NET_30;
        }
    }

    public WrikeAmendmentQuoteController getInstance() {
        return this;
    }

    public String getAmendmentTypeSelectStepName() {
        return 'AMENDMENT_TYPE_SELECT';
    }

    public Map<String, Map<String, Boolean>> getAmendmentTypeToControlVisibility() {
        return new Map<String, Map<String, Boolean>> {
            WrikeQuote.AMEND_ON_RENEWAL => new Map<String, Boolean>{
                'DATE' => false,
                'TERM' => true
            },
            WrikeQuote.START_NEW_BILLING_CYCLE => new Map<String, Boolean>{
                'DATE' => true,
                'TERM' => true
            },
            WrikeQuote.AMEND_BEFORE_RENEWAL => new Map<String, Boolean>{
                'DATE' => true,
                'TERM' => false
            },
            WrikeQuote.AMEND_BEFORE_RENEWAL_AND_RENEW => new Map<String, Boolean>{
                'DATE' => true,
                'TERM' => false
            },
            WrikeQuote.CANCEL_ON_RENEWAL => new Map<String, Boolean>{
                'DATE' => false,
                'TERM' => false
            }
        };
    }

    public  Map<String, String> getAmendmentTypeToDescription() {
        return SettingsProvider.getAmendmentTypeToDescription();
    }

    public List<SelectOption> getAvalibleAmendmentTypes() {
        List<SelectOption> amendmentTypes = new List<SelectOption>();
        for (String typeName : getAmendmentTypeToDescription().keySet()) {
            SelectOption typeSelectOption = new SelectOption(typeName, getAmendmentTypeToDescription().get(typeName));
            typeSelectOption.setEscapeItem(false);
            amendmentTypes.add(typeSelectOption);
        }
        return amendmentTypes;
    }

    protected override Boolean nextStepHandler() {
        if (this.step == getAmendmentTypeSelectStepName()) {
            if (this.wQuote.amendmentType == null) {
                this.validationResults.addError('You should select amendment type before continue.');
                return false;
            }
            if (this.initAmendmentType != null && this.initAmendmentType != this.wQuote.amendmentType) {
                WrikeQuote.AmendmentType newAmendmentType = this.wQuote.amendmentType;
                this.wQuote = this.initQuoteState.cloneQuote();
                this.wQuote.amendmentType = newAmendmentType;
            }
            this.wQuote.effectiveDate = this.quoteDateSrv.getEffectiveDate(wQuote);
            this.wQuote.invoiceDate = this.wQuote.effectiveDate;
            this.wQuote.validUntil = this.quoteDateSrv.getValidUntil(this.wQuote);
            this.wQuote.newTerm = this.wQuote.getDefaultNewTermValue();
            initialNewTerm = this.wQuote.getDefaultNewTermValue();
            initialNumberOfTeams = this.wQuote.numberOfTeams;
        } else if (this.step == getQuoteDetailsStepName()) {
            Boolean isAmendmentTypeNotSelected = this.wQuote.amendmentType == null;
            if (isAmendmentTypeNotSelected) {
                validationResults.addError('Please fill out all required fields.');
                return false;
            }
            if (!validateQuoteDetails()) {
                return false;
            }

            final Boolean isNeedResetProductState = getIsNeedResetProductState();
            for (Integer itemIndex = 0; itemIndex < this.wQuote.items.size(); itemIndex++) {
                WrikeQuoteItem quoteItem = this.wQuote.items.get(itemIndex);
                if (quoteItem.getIsExisting() && (this.wQuote.isNewBillingCycle() || isNeedResetProductState)) {
                    quoteItem.state = WrikeQuoteItem.State.REMOVED;
                }
            }
        }
        return true;
    }

    protected override void previousStepHandler() {
        if (this.step == getQuoteDetailsStepName()) {
            this.initAmendmentType = this.wQuote.amendmentType;
        }
    }

    protected override List<String> getStepsOrder() {
        return new List<String>{getAmendmentTypeSelectStepName(), getQuoteDetailsStepName(), getProductsTableStepName()};
    }
}
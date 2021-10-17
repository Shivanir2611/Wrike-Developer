public class ZuoraQuoteAmendmentRequest extends ZuoraQuoteAbstractRequest {
    private RequestOptions AmendOptions;
    private PreviewOptions PreviewOptions;
    private List<Amendment> Amendments;

    private ZuoraQuoteAmendmentRequest() {
    }

    public RequestOptions getAmendmentOptions() {
        return AmendOptions;
    }

    public List<Amendment> getAmendments() {
        return Amendments;
    }

    public PreviewOptions getPreviewOptions() {
        return PreviewOptions;
    }

    public String getRequestJson() {
        return JSON.serialize(new Map<String, List<ZuoraQuoteAmendmentRequest>> {
            'requests' => new List<ZuoraQuoteAmendmentRequest> { this }
        }, true).replace('"QuoteId":', '"QuoteId__c":')
                .replace('"OpportunityId":', '"OpportunityId__c":');
    }

    public class Builder {
        private final WrikeQuote quote;
        private final Boolean cancellation;
        private Boolean preview = true;

        public Builder(final WrikeQuote quote) {
            System.assert(quote != null, 'Quote is required.');
            System.assert(quote.effectiveDate != null, 'Effective date is required.');
            System.assert(quote.subscriptionEndDate != null, 'Subscription end date is required.');
            System.assert(String.isNotBlank(quote.zuoraSubscriptionId), 'Subscription is required.');
            this.quote = quote;
            this.cancellation = quote.isNewBillingCycle();
        }

        public Builder setPreview(final Boolean preview) {
            this.preview = preview;
            return this;
        }

        public ZuoraQuoteAmendmentRequest build() {
            final List<Amendment> amendments = new List<Amendment>();
            if(this.quote.needsRenewal()) {
                amendments.add(createAmendment(AmendmentType.Renewal, null));
            }
            for(WrikeQuoteItem quoteItem : this.quote.items) {
                if(quoteItem.getIsRemoved()) {
                    amendments.add(createAmendment(AmendmentType.RemoveProduct, quoteItem));
                } else
                if(quoteItem.getIsAdded() && cancellation == false) {
                    amendments.add(createAmendment(AmendmentType.NewProduct, quoteItem));
                }
            }
            if(cancellation) {
                amendments.add(createAmendment(AmendmentType.Cancellation, null));
            }
            final ZuoraQuoteAmendmentRequest request = new ZuoraQuoteAmendmentRequest();
            request.Amendments = amendments;
            request.AmendOptions = new RequestOptions();
            if(preview) {
                request.PreviewOptions = new PreviewOptions();
            }
            return request;
        }

        private Amendment createAmendment(final AmendmentType type, final WrikeQuoteItem quoteItem) {
            final Amendment amendment = new Amendment();
            amendment.Name = quoteItem != null ? type.name() + ' - ' + quoteItem.product.name : type.name();
            amendment.Type = type.name();
            amendment.Status = 'Completed';
            amendment.SubscriptionId = quote.zuoraSubscriptionId;
            amendment.OpportunityId = quote.opportunityId;
            amendment.QuoteId = quote.id;
            if(quoteItem != null) {
                amendment.RatePlanData = new RatePlanData(quoteItem, preview);
            }
            if(type == AmendmentType.Renewal) {
                amendment.ContractEffectiveDate = quote.subscriptionEndDate;
            } else {
                if(type == AmendmentType.NewProduct) {
                    amendment.TermStartDate = quote.effectiveDate;
                }
                amendment.EffectiveDate = quote.effectiveDate;
                amendment.ContractEffectiveDate = quote.effectiveDate;
                amendment.CustomerAcceptanceDate = quote.effectiveDate;
                amendment.ServiceActivationDate = quote.effectiveDate;
            }
            return amendment;
        }
    }

    public class Amendment {
        public String Name {get; set;}
        public String Type {get; set;}
        public String Status {get; set;}
        public String SubscriptionId {get; set;}
        public String OpportunityId {get; set;}
        public String QuoteId {get; set;}
        public Date EffectiveDate {get; set;}
        public Date CustomerAcceptanceDate {get; set;}
        public Date ContractEffectiveDate {get; set;}
        public Date TermStartDate {get; set;}
        public Date ServiceActivationDate {get; set;}
        public RatePlanData RatePlanData {get; set;}
    }

    private enum AmendmentType {
            NewProduct, RemoveProduct, Renewal, Cancellation
    }
}
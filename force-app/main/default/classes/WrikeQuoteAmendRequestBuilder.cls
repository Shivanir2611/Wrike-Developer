public class WrikeQuoteAmendRequestBuilder extends WrikeQuoteAbstractRequestBuilder {
    protected Boolean cancellation = false;
    
    public WrikeQuoteAmendRequestBuilder(final WrikeQuote quote) {
        System.assert(quote != null, 'Quote is required.');
        System.assert(quote.effectiveDate != null, 'Effective date is required.');
        System.assert(quote.subscriptionEndDate != null, 'Subscription end date is required.');
        System.assert(String.isNotBlank(quote.zuoraSubscriptionId), 'Subscription is required.');
        this.quote = quote;
    }
    
    public WrikeQuoteAmendRequestBuilder setPreview(final Boolean preview) {
        this.preview = preview;
        return this;
    }
    
    public WrikeQuoteAmendRequestBuilder setCancellation(final Boolean cancellation) {
        this.cancellation = cancellation;
        return this;
    }
    
    public Zuora.zApi.AmendRequest build() {
        final Zuora.zApi.AmendRequest amendRequest = new Zuora.zApi.AmendRequest();
        amendRequest.amendments = new List<Zuora.zObject>();
        if(this.quote.needsRenewal()) {
            amendRequest.amendments.add(createAmendment(this.quote, AmendmentType.Renewal, 'Renewal'));
        }
        for(WrikeQuoteItem quoteItem : this.quote.items) {
            final AmendmentType type = getAmendmentType(quoteItem.state);
            if(type != null) {
                final Zuora.zObject amendment = createAmendment(this.quote, type, type.name() + ' - ' + quoteItem.product.name);
                if(type == AmendmentType.NewProduct) {
                    amendment.setValue('RatePlanData', getAddedProductRatePlanData(quoteItem));
                    amendRequest.amendments.add(amendment);
                } else if(type == AmendmentType.RemoveProduct) {
                    amendment.setValue('RatePlanData', getRemovedProductRatePlanData(quoteItem));
                    amendRequest.amendments.add(amendment);
                }
            }
        }
        if(cancellation) {
            amendRequest.amendments.add(createAmendment(this.quote, AmendmentType.Cancellation, 'Cancellation'));
        }
        final Zuora.zApi.AmendOptions amendmentOptions = new Zuora.zApi.AmendOptions();
        amendmentOptions.ProcessPayments = false;
        amendmentOptions.GenerateInvoice = preview;
        if(preview) {
            amendRequest.previewOptions = createPreviewOptions();
            final Zuora.zApi.InvoiceProcessingOptions invoiceOptions = new Zuora.zApi.InvoiceProcessingOptions();
            invoiceOptions.InvoiceTargetDate = '3000-01-01';
            amendmentOptions.invoiceProcessingOptions = invoiceOptions;
        }
        amendRequest.amendOptions = amendmentOptions;
        return amendRequest;
    }
    
    public AmendmentType getAmendmentType(final WrikeQuoteItem.State state) {
        if(state == WrikeQuoteItem.State.ADDED && this.cancellation == false) {
            return AmendmentType.NewProduct;
        }
        if(state == WrikeQuoteItem.State.REMOVED) {
            return AmendmentType.RemoveProduct;
        }
        return null;
    }
    
    private Zuora.zObject createAmendment(final WrikeQuote quote, final AmendmentType type, final String name) {
        final Zuora.zObject amendment = new Zuora.zObject('Amendment');
        amendment.setValue('Name', name);
        amendment.setValue('Type', type.name());
        amendment.setValue('Status', 'Completed');
        amendment.setValue('SubscriptionId', quote.zuoraSubscriptionId);
        amendment.setValue('OpportunityId__c', quote.opportunityId);
        amendment.setValue('QuoteId__c', quote.id);
        setEffectiveDates(amendment, type);
        return amendment;
    }
    
    private void setEffectiveDates(final Zuora.zObject amendment, final AmendmentType type) {
        if(type == AmendmentType.Renewal) {
            amendment.setValue('ContractEffectiveDate', Zuora.zUtil.getZuoraDate(quote.subscriptionEndDate));
        } else {
            final String effectiveDate = Zuora.zUtil.getZuoraDate(this.quote.effectiveDate);
            if(type == AmendmentType.NewProduct) {
                amendment.setValue('TermStartDate', effectiveDate);
            }
            amendment.setValue('ServiceActivationDate', effectiveDate);
            amendment.setValue('CustomerAcceptanceDate', effectiveDate);
            amendment.setValue('EffectiveDate', effectiveDate);
            amendment.setValue('ContractEffectiveDate', effectiveDate);
        }
    }
    
    private enum AmendmentType {
        NewProduct, RemoveProduct, Renewal, Cancellation
    }
}
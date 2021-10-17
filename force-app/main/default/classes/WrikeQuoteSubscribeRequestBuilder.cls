public class WrikeQuoteSubscribeRequestBuilder extends WrikeQuoteAbstractRequestBuilder {
    private String purchaseOrderNumber;
    
    public WrikeQuoteSubscribeRequestBuilder(final WrikeQuote quote) {
        System.assert(quote != null, 'Quote is required.');
        System.assert(quote.effectiveDate != null, 'Effective date is required.');
        this.quote = quote;
    }
    
    public WrikeQuoteSubscribeRequestBuilder setPreview(final Boolean preview) {
        this.preview = preview;
        return this;
    }

    public WrikeQuoteSubscribeRequestBuilder setPurchaseOrderNumber(final String purchaseOrderNumber) {
        this.purchaseOrderNumber = purchaseOrderNumber;
        return this;
    }
    
    public Zuora.zApi.SubscribeRequest build() {
        final Zuora.zApi.SubscribeRequest subscribeRequest = new Zuora.zApi.SubscribeRequest();
        if(quote.getIsSubscription() && preview) {
            // mock data as the related Zuora account may have 'Draft' status at this point
            subscribeRequest.BillToContact = createPreviewContact();
            subscribeRequest.zAccount = createPreviewAccount();
        } else {
            final Zuora.zObject account = new Zuora.zObject('Account');
            account.setValue('Id', quote.zuoraAccountId);
            subscribeRequest.zAccount = account;
        }
        final Zuora.zObject subscription = new Zuora.zObject('Subscription');
        final Zuora.zApi.SubscriptionData subscriptionData = new Zuora.zApi.SubscriptionData();
        subscriptionData.Subscription = subscription;
        final String effectiveDate = Zuora.zUtil.getZuoraDate(this.quote.effectiveDate);
        subscription.setValue('TermStartDate', effectiveDate);
        subscription.setValue('ServiceActivationDate', effectiveDate);
        subscription.setValue('ContractEffectiveDate', effectiveDate);
        subscription.setValue('InitialTerm', this.quote.newTerm);
        subscription.setValue('RenewalTerm', this.quote.renewalTerm != null ? this.quote.renewalTerm : this.quote.newTerm);
        subscription.setValue('AutoRenew', true);
        subscription.setValue('Quote_Id__c', quote.id);
        subscription.setValue('Opportunity_Id__c', quote.opportunityId);
        if(String.isNotBlank(this.purchaseOrderNumber)) {
            subscription.setValue('PurchaseOrderNumber__c', this.purchaseOrderNumber);
        }
        
        final List<Zuora.zObject> ratePlanData = new List<Zuora.zObject>();
        for(WrikeQuoteItem quoteItem : quote.items) {
            if(quoteItem.getIsAdded()) {
                ratePlanData.add(getAddedProductRatePlanData(quoteItem));
            }
        }
        subscriptionData.RatePlanData = ratePlanData;
        subscribeRequest.SubscriptionData = subscriptionData;
        final Zuora.zApi.SubscribeOptions subscribeOptions = new Zuora.zApi.SubscribeOptions();
        subscribeRequest.SubscribeOptions = subscribeOptions;
        subscribeOptions.ProcessPayments = false;
        subscribeOptions.GenerateInvoice = preview;
        if(preview) {
            subscribeRequest.previewOptions = createPreviewOptions();
            final Zuora.zApi.SubscribeInvoiceProcessingOptions invoiceOptions = new Zuora.zApi.SubscribeInvoiceProcessingOptions();
            invoiceOptions.InvoiceTargetDate = '3000-01-01';
            invoiceOptions.InvoiceProcessingScope = 'Subscription';
            subscribeOptions.SubscribeInvoiceProcessingOptions = invoiceOptions;
        }
        return subscribeRequest;
    }
    
    public Zuora.zObject createPreviewContact() {
        final Zuora.zObject contact = new Zuora.zObject('Contact');
        contact.setValue('FirstName', 'Preview');
        contact.setValue('LastName', 'Contact');
        contact.setValue('Country', 'United States');
        contact.setValue('State', 'California');
        contact.setValue('City', 'San Jose');
        contact.setValue('PostalCode', '95113');
        contact.setValue('WorkEmail', 'quote.preview@team.wrike.com');
        return contact;
    }
    
    public Zuora.zObject createPreviewAccount() {
        final Zuora.zObject account = new Zuora.zObject('Account');
        account.setValue('Name', 'Preview Account');
        account.setValue('AccountNumber', EncodingUtil.convertToHex(crypto.generateAesKey(128)));
        account.setValue('AutoPay', false);
        account.setValue('Batch', 'Batch1');
        account.setValue('PaymentTerm', 'Due Upon Receipt');
        account.setValue('BillCycleDay', 1);
        account.setValue('Currency', 'USD');
        return account;
    }
}
public class ZuoraQuoteSubscribeRequest extends ZuoraQuoteAbstractRequest {
    private SubscriptionData SubscriptionData;
    private RequestOptions SubscribeOptions;
    private PreviewOptions PreviewOptions;
    private Map<String, String> BillToContact;
    private Map<String, String> Account;
    private Map<String, String> PaymentMethod;

    private ZuoraQuoteSubscribeRequest() {
    }

    public Map<String, String> getAccount() {
        return Account;
    }

    public SubscriptionData getSubscriptionData() {
        return SubscriptionData;
    }

    public RequestOptions getSubscribeOptions() {
        return SubscribeOptions;
    }

    public PreviewOptions getPreviewOptions() {
        return PreviewOptions;
    }

    public String getRequestJson() {
        return JSON.serialize(new Map<String, List<ZuoraQuoteSubscribeRequest>> {
            'subscribes' => new List<ZuoraQuoteSubscribeRequest> { this }
        }, true).replace('"PurchaseOrderNumber":', '"PurchaseOrderNumber__c":')
                .replace('"QuoteId":', '"Quote_Id__c":')
                .replace('"OpportunityId":', '"Opportunity_Id__c":');
    }

    public class Builder {
        private final WrikeQuote quote;
        private Boolean preview = true;
        private String purchaseOrderNumber;

        public Builder(final WrikeQuote quote) {
            System.assert(quote != null, 'Quote is required.');
            System.assert(quote.effectiveDate != null, 'Effective date is required.');
            this.quote = quote;
        }

        public Builder setPreview(final Boolean preview) {
            this.preview = preview;
            return this;
        }

        public Builder setPurchaseOrderNumber(final String purchaseOrderNumber) {
            this.purchaseOrderNumber = purchaseOrderNumber;
            return this;
        }

        public ZuoraQuoteSubscribeRequest build() {
            final Subscription subscription = new Subscription();
            subscription.TermStartDate = quote.effectiveDate;
            subscription.ServiceActivationDate = quote.effectiveDate;
            subscription.ContractEffectiveDate = quote.effectiveDate;
            subscription.InitialTerm = quote.newTerm;
            subscription.RenewalTerm = quote.renewalTerm != null ? quote.renewalTerm : quote.newTerm;
            subscription.TermType = 'TERMED';
            subscription.AutoRenew = true;
            subscription.QuoteId = quote.id;
            subscription.OpportunityId = quote.opportunityId;
            if(String.isNotBlank(purchaseOrderNumber)) {
                subscription.PurchaseOrderNumber = this.purchaseOrderNumber;
            }
            final List<RatePlanData> ratePlanData = new List<RatePlanData>();
            for(WrikeQuoteItem quoteItem : quote.items) {
                if(quoteItem.getIsAdded()) {
                    ratePlanData.add(new RatePlanData(quoteItem, preview));
                }
            }
            final SubscriptionData subscriptionData = new SubscriptionData();
            subscriptionData.Subscription = subscription;
            subscriptionData.RatePlanData = ratePlanData;
            final Map<String, String> account = new Map<String, String>();
            if(quote.getIsSubscription() && preview) {
                account.put('Name', 'Preview Account');
                account.put('AccountNumber', EncodingUtil.convertToHex(crypto.generateAesKey(128)));
                account.put('AutoPay', 'false');
                account.put('Batch', 'Batch1');
                account.put('PaymentTerm', 'Due Upon Receipt');
                account.put('BillCycleDay', '1');
                account.put('Currency', 'USD');
            } else {
                account.put('Id', quote.zuoraAccountId);
            }
            final ZuoraQuoteSubscribeRequest request = new ZuoraQuoteSubscribeRequest();
            request.Account = account;
            request.SubscriptionData = subscriptionData;
            request.SubscribeOptions = new RequestOptions();
            if(preview) {
                request.PreviewOptions = new PreviewOptions();
                request.SubscribeOptions.setSubscribeInvoiceProcessingOptions(new InvoiceProcessingOptions());
                if(quote.getIsSubscription()) {
                    request.BillToContact = new Map<String, String> {
                        'FirstName' => 'Preview',
                        'LastName' => 'Contact',
                        'Country' => 'United States',
                        'State' => 'California',
                        'City' => 'San Jose',
                        'PostalCode' => '95113',
                        'WorkEmail' => 'quote.preview@team.wrike.com'
                    };
                }
            }
            return request;
        }
    }

    public class SubscriptionData {
        public Subscription Subscription {get; set;}
        public List<RatePlanData> RatePlanData {get; set;}
    }

    public class Subscription {
        public Date TermStartDate {get; set;}
        public Date ServiceActivationDate {get; set;}
        public Date ContractEffectiveDate {get; set;}
        public String TermType {get; set;}
        public Integer InitialTerm {get; set;}
        public Integer RenewalTerm {get; set;}
        public Boolean AutoRenew {get; set;}
        public String PurchaseOrderNumber {get; set;}
        public String QuoteId {get; set;}
        public String OpportunityId {get; set;}
    }
}
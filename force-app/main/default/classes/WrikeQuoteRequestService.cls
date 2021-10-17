public class WrikeQuoteRequestService {

    public static WrikeQuoteRequestService getInstance() {
        return (WrikeQuoteRequestService)ServiceLocator.getInstance(WrikeQuoteRequestService.class);
    }
    
    public SubscriptionRequest createSubscriptionRequest(final WrikeQuote quote,
                                                         final SendQuoteRequest sendQuoteRequest,
                                                         final Boolean preview) {
        System.assert(quote != null, 'Quote object is required.');
        System.assert(quote.newTerm != null, 'New term is required.');
        final SubscriptionRequest request = new SubscriptionRequest();
        if(quote.getIsAmendment() || quote.getIsRenewal()) {
            request.amendRequest = new WrikeQuoteAmendRequestBuilder(quote)
                .setPreview(preview)
                .setCancellation(quote.isNewBillingCycle())
                .build();
        }
        if(quote.getIsSubscription() || quote.isNewBillingCycle()) {
            request.subscribeRequest = new WrikeQuoteSubscribeRequestBuilder(quote)
                .setPreview(preview)
                .setPurchaseOrderNumber(sendQuoteRequest != null ? sendQuoteRequest.getPurchaseOrderNumber() : null)
                .build();
        } 
        return request;
    }
    
    public class SubscriptionRequest {
        private Zuora.zApi.AmendRequest amendRequest;
        private Zuora.zApi.SubscribeRequest subscribeRequest;
        
        private SubscriptionRequest() {
        }
        
        public Zuora.zApi.AmendRequest getAmendRequest() {
            return this.amendRequest;
        }
        
        public Zuora.zApi.SubscribeRequest getSubscribeRequest() {
            return this.subscribeRequest;
        }
    }
}
public class SendQuoteRequest {
    private Id quoteId;
    private BillingInfo billingInfo;
    private String creditCardId;
    private String vatNumber;
    private Boolean vatValid;
    private String purchaseOrderNumber;

    private SendQuoteRequest() {
    }
    
    public BillingInfo getBillingInfo() {
        return this.billingInfo;
    }
    
    public String getCreditCardId() {
        return this.creditCardId;
    }
    
    public String getVatNumber() {
        final String countryCode = this.billingInfo != null ?  this.billingInfo.country : null;
        if(String.isNotBlank(countryCode) && String.isNotBlank(this.vatNumber) && !this.vatNumber.startsWith(countryCode)) {
            return countryCode + this.vatNumber;
        }
        return this.vatNumber;
    }
    
    public Boolean isVatValid() {
        return this.vatValid == true;
    }
    
    public String getPurchaseOrderNumber() {
        return this.purchaseOrderNumber;
    }
    
    public Id getQuoteId() {
        return this.quoteId;
    }
    
    public class Builder {
        private final SendQuoteRequest request = new SendQuoteRequest();
        
        public Builder(final Id quoteId) {
            System.assert(quoteId != null, 'Quote Id is required.');
            request.quoteId = quoteId;
        }
        
        public Builder setVatValid(final Boolean vatValid) {
            request.vatValid = vatValid;
            return this;
        }
        
        public Builder setVatNumber(final String vatNumber) {
            request.vatNumber = (vatNumber != null ? vatNumber.trim() : null);
            return this;
        }
        
        public Builder setBillingInfo(final BillingInfo billingInfo) {
            request.billingInfo = billingInfo;
            return this;
        }
        
        public Builder setCreditCardId(final String creditCardId) {
            request.creditCardId = creditCardId;
            return this;
        }
        
        public Builder setPurchaseOrderNumber(final String purchaseOrderNumber) {
            request.purchaseOrderNumber = purchaseOrderNumber;
            return this;
        }
        
        public SendQuoteRequest build() {
            System.assert(request.billingInfo != null, 'Billing info is required.');
            return request;
        }
    }
}
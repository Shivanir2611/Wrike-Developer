global virtual class InvoiceItem implements Comparable {
    public String productId {get; set;}
    public String productName {get; set;}
    public String productRatePlanName {get; set;}
    public String productServiceType {get; set;}
    public Decimal quantity {get; set;}
    public Date serviceStartDate {get; set;}
    public Date serviceEndDate {get; set;}
    public Boolean prorationCredit {get; set;}
    public Boolean proration {get; set;}
    public Decimal chargeAmount {get; set;}
    protected WrikeQuoteItem quoteProductItem;
    
    public InvoiceItem(final WrikeQuoteItem item,
                       final Decimal quantity,
                       final Date serviceStartDate,
                       final Date serviceEndDate,
                       final Decimal chargeAmount,
                       final WrikeQuote quote) {
        System.assert(item != null, 'Product item is required.');
        System.assert(item.product != null, 'Product is required.');
        System.assert(String.isNotBlank(item.product.zuoraProductId), 'Product id is required.');
        System.assert(String.isNotBlank(item.product.name), 'Product name is required.');
        System.assert(serviceStartDate != null, 'Service start date is required.');
        System.assert(serviceEndDate != null, 'Service end date is required.');
        System.assert(chargeAmount != null, 'Charge amount is required.');
        System.assert(quote != null, 'Quote is required.');
        this.quoteProductItem = item;
        this.productId = item.product.zuoraProductId;
        this.productName = item.product.name;
        this.productRatePlanName = item.product.zuoraProductRatePlanChargeName;
        this.productServiceType = item.product.serviceType;
        this.quantity = quantity;
        this.serviceStartDate = serviceStartDate;
        this.serviceEndDate = serviceEndDate;
        this.chargeAmount = chargeAmount;
        this.prorationCredit = item.getIsRemoved();
        this.proration = !item.getIsRemoved()
                && item.product.getIsRecurrent()
                && !quote.isNewBillingCycle()
                && serviceStartDate < quote.subscriptionEndDate;
    }
    
    global Integer compareTo(final Object other) { 
        if(other == null) {
            return 1;
        }
        if(this == other) {
            return 0;
        }
        final InvoiceItem invoiceItem = (InvoiceItem)other;
        return 100*invoiceItem.serviceStartDate.daysBetween(this.serviceStartDate) + 
               10*(this.chargeAmount < 0 && invoiceItem.chargeAmount > 0 ? -1 : 1) + 
               (this.productName.compareTo(invoiceItem.productName) > 0 ? 1 : -1);
    }

    public String getChargeType() {
        if(prorationCredit) {
            return 'Proration Credit';
        } else if(proration) {
            return 'Proration';
        }
        return '';
    }
    
    public WrikeQuoteItem getQuoteProductItem() {
        return this.quoteProductItem;
    }
}
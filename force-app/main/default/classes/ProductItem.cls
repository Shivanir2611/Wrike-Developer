public class ProductItem extends InvoiceItem {
    private static Map<String, String> billingPeriods = new Map<String, String> {
        'Month' => 'Billed Monthly',
        'Quarter' => 'Billed Quarterly',
        'Semi-Annual' => 'Billed Semi-Annually',
        'Annual' => 'Billed Annually',
        'Eighteen Months' => 'Billed once every eighteen months',
        'Two Years' => 'Billed once every two years',
        'Three Years' => 'Billed once every three years',
        'Five years' => 'Billed once every five years'
    };

    public Decimal termListPrice {get; set;}
    public Decimal termEffectivePrice {get; set;}
    public Decimal billingPeriodPrice {get; set;}
    public Boolean recurrent {get; set;}
    public String billingPeriod {get; set;}
    private final String itemUID;
    
    public ProductItem(final InvoiceItem invoiceItem, final WrikeQuote quote) {
        super(invoiceItem.getQuoteProductItem(),
              invoiceItem.quantity,
              invoiceItem.serviceStartDate,
              invoiceItem.serviceEndDate,
              invoiceItem.chargeAmount,
              quote);
        final WrikeQuoteProduct product = invoiceItem.getQuoteProductItem().product;
        this.termEffectivePrice = product.getTermEffectivePrice();
        this.termListPrice = product.getTermListPrice();
        this.billingPeriodPrice = product.effectivePrice;
        this.billingPeriod = product.billingPeriodName;
        this.recurrent = product.getIsRecurrent();
        this.itemUID = product.quantity + '_' + product.zuoraProductRatePlanChargeId;
    }
    
    public String getType() {
        return prorationCredit ? 'Removed' : 'Added';
    }

    public Boolean getDiscount() {
        return termListPrice > termEffectivePrice;
    }
    
    public String getBillingPeriodName() {
        return billingPeriods.get(this.billingPeriod);
    }

    public void mergeProductItem(final ProductItem productItem) {
        this.serviceEndDate = productItem.serviceEndDate;
        this.chargeAmount = this.chargeAmount + productItem.chargeAmount;
    }

    public String getItemUID() {
        return itemUID;
    }

    public Boolean isAdded() {
        return getQuoteProductItem().getIsAdded();
    }

    public Boolean isRemoved() {
        return getQuoteProductItem().getIsRemoved();
    }

    public Boolean isExisting() {
        return getQuoteProductItem().getIsExisting();
    }

    public Boolean isSeatProduct() {
        return getQuoteProductItem().product.isSeatProduct();
    }

    public Boolean isPartnerCommission() {
        return getQuoteProductItem().product.isPartnerCommission();
    }
}
public class QuoteBundleLineItem {
    private final String billingPeriod;
    private final String billingPeriodName;
    private Integer billingPeriodMonths;
    private final Decimal quantity;
    private final Boolean removed;
    private final String chargeType;
    private Decimal chargeAmount = 0;
    private Decimal monthListPrice = 0;
    private Decimal monthEffectivePrice = 0;
    private Decimal oneTimeListPrice = 0;
    private Decimal oneTimeEffectivePrice = 0;
    private Date serviceStartDate;
    private Date serviceEndDate;
    private Boolean bundle;
    private Boolean oneTime;
    private Boolean renewal;
    private final List<QuoteBundleProductItem> items = new List<QuoteBundleProductItem>();

    public QuoteBundleLineItem(final QuoteBundleProductItem bundleProductItem,
                               final Boolean bundle,
                               final Boolean renewal) {
        this.bundle = bundle;
        this.renewal = renewal;
        this.serviceStartDate = bundleProductItem.getServiceStartDate();
        this.serviceEndDate = bundleProductItem.getServiceEndDate();
        this.removed = bundleProductItem.isRemoved();
        this.oneTime = bundleProductItem.getRecurrent() != true;
        this.quantity = bundleProductItem.getQuantity();
        this.billingPeriod = bundleProductItem.getBillingPeriod();
        this.billingPeriodName = bundleProductItem.getBillingPeriodName();
        this.billingPeriodMonths = bundleProductItem.getBillingPeriodMonths();
        this.chargeType = bundleProductItem.getChargeType();
        for(ProductItem productItem : bundleProductItem.getItems()) {
            final WrikeQuoteProduct product = productItem.getQuoteProductItem().product;
            this.chargeAmount = this.chargeAmount + productItem.chargeAmount;
            if(productItem.recurrent) {
                this.monthListPrice = this.monthListPrice +  product.getMonthListPrice();
                this.monthEffectivePrice = this.monthEffectivePrice +  product.getProductMrr();
            } else {
                this.oneTimeListPrice = this.oneTimeListPrice + product.getListPrice();
                this.oneTimeEffectivePrice = this.oneTimeEffectivePrice + product.effectivePrice;
            }
        }
        this.items.add(bundleProductItem);
    }

    public void addProductItem(final QuoteBundleProductItem bundleProductItem) {
        System.assertEquals(quantity, bundleProductItem.getQuantity(), 'Quantity mismatch for bundle products.');
        System.assertEquals(removed, bundleProductItem.isRemoved(), 'Added and removed products mismatch for a bundle.');
        for(ProductItem productItem : bundleProductItem.getItems()) {
            final WrikeQuoteProduct product = productItem.getQuoteProductItem().product;
            this.chargeAmount = this.chargeAmount + productItem.chargeAmount;
            this.monthListPrice = this.monthListPrice + product.getMonthListPrice();
            this.monthEffectivePrice = this.monthEffectivePrice + product.getProductMrr();
        }
        this.items.add(bundleProductItem);
    }

    public Boolean getBundle() {
        return this.bundle == true;
    }

    public Boolean getRenewal() {
        return this.renewal == true;
    }

    public Boolean getOneTime() {
        return this.oneTime == true;
    }

    public String getBillingPeriod() {
        return billingPeriod;
    }

    public String getBillingPeriodName() {
        return billingPeriodName;
    }

    public Integer getBillingPeriodMonths() {
        return billingPeriodMonths;
    }

    public Decimal getQuantity() {
        return quantity;
    }

    public Boolean getRemoved() {
        return removed;
    }

    public String getChargeType() {
        return chargeType;
    }

    public Decimal getChargeAmount() {
        return chargeAmount;
    }

    public Decimal getBillingPeriodEffectivePrice() {
        return monthEffectivePrice * billingPeriodMonths;
    }

    public Decimal getBillingPeriodListPrice() {
        return monthListPrice * billingPeriodMonths;
    }

    public Decimal getOneTimeListPrice() {
        return oneTimeListPrice;
    }

    public Decimal getOneTimeEffectivePrice() {
        return oneTimeEffectivePrice;
    }

    public Date getServiceStartDate() {
        return serviceStartDate;
    }

    public Date getServiceEndDate() {
        return serviceEndDate;
    }

    public List<QuoteBundleProductItem> getItems() {
        return items;
    }
}
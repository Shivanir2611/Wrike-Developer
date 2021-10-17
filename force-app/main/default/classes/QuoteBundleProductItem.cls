public class QuoteBundleProductItem implements Comparable {
    private final String zuoraProductId;
    private final Boolean removed;
    private Date serviceStartDate;
    private Date serviceEndDate;
    private Decimal quantity;
    private String productName;
    private String productRatePlanName;
    private String productServiceType;
    private String billingPeriodName;
    private String billingPeriod;
    private Integer billingPeriodMonths;
    private Boolean recurrent;
    private String chargeType;
    private final List<ProductItem> items = new List<ProductItem>();

    public QuoteBundleProductItem(final ProductItem productItem) {
        final WrikeQuoteProduct product = productItem.getQuoteProductItem().product;
        this.removed = productItem.isRemoved();
        this.zuoraProductId = product.zuoraProductId;
        this.serviceStartDate = productItem.serviceStartDate;
        this.serviceEndDate = productItem.serviceEndDate;
        this.quantity = productItem.quantity;
        this.productName = productItem.productName;
        this.productRatePlanName = productItem.productRatePlanName;
        this.productServiceType = productItem.productServiceType;
        this.billingPeriod = productItem.billingPeriod;
        this.billingPeriodName = productItem.getBillingPeriodName();
        this.billingPeriodMonths = product.getBillingPeriodInMonth();
        this.recurrent = product.getIsRecurrent();
        this.chargeType = productItem.getChargeType();
        this.items.add(productItem);
    }

    public void addProduct(final ProductItem productItem) {
        this.quantity = this.quantity + productItem.quantity;
        this.items.add(productItem);
    }

    public Decimal getQuantity() {
        return quantity;
    }

    public Date getServiceStartDate() {
        return serviceStartDate;
    }

    public Date getServiceEndDate() {
        return serviceEndDate;
    }

    public String getProductName() {
        return productName;
    }

    public String getProductServiceType() {
        return productServiceType;
    }

    public String getProductRatePlanName() {
        return productRatePlanName;
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

    public List<ProductItem> getItems() {
        return items;
    }

    public String getChargeType() {
        return chargeType;
    }

    public Boolean isRemoved() {
        return removed;
    }

    public Boolean getRecurrent() {
        return recurrent;
    }

    public Boolean isSeatProduct() {
        return items[0].isSeatProduct();
    }

    public Boolean isLicenseSeatsMatchingProduct() {
        return items[0].getQuoteProductItem().product.isLicenseSeatsMatchingProduct();
    }

    public Boolean isPartnerCommission() {
        return items[0].getQuoteProductItem().product.isPartnerCommission();
    }

    public Integer compareTo(final Object other) {
        if(other == null) {
            return 1;
        }
        if(this == other) {
            return 0;
        }
        final QuoteBundleProductItem otherItem = (QuoteBundleProductItem)other;
        return StringUtils.getEmptyIfNull(this.productName)
                .compareTo(StringUtils.getEmptyIfNull(otherItem.productName));
    }
}
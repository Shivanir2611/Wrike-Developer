public class CPQLineItemBillingSchedule {

    public Id id {get; set;}
    public String name {get; set;}
    public Integer invoiceNumber {get; set;}
    public Date invoiceDate {get; set;}
    public Date serviceStartDate {get; set;}
    public Date serviceEndDate {get; set;}
    public Integer quantity {get; set;}
    public Decimal effectivePrice {get; set;}
    public Decimal invoiceAllocatedAmount {get; set;}
    public String chargeType {get; set;}
    public String netSuiteInternalId {get; set;}
    public Id productId {get; set;}
    public Id orderId {get; set;}
    public Id quoteItemId {get; set;}
    public Id orderItemId {get; set;}
    public String currencyCode {get; set;}

    public Boolean isSubscription() {
        return 'Subscription'.equalsIgnoreCase(chargeType);
    }
}
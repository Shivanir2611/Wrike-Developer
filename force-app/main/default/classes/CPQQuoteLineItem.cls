public class CPQQuoteLineItem {

    public Id id {get; set;}
    public String name {get; set;}
    public Date effectiveStartDate {get; set;}
    public Date effectiveEndDate {get; set;}
    public String subscriptionType {get; set;}
    public Decimal price {get; set;}
    public Decimal effectivePricePerUserPerMonth {get; set;}
    public Decimal nonRenewableDiscount {get; set;}
    public Integer quantity {get; set;}
    public Product2 product {get; set;}
    public Boolean bundled {get; set;}
    public String currencyCode {get; set;}
    public Id quoteId {get; set;}

    public Boolean isRenewable() {
        return 'Renewable'.equalsIgnoreCase(subscriptionType);
    }

    public Boolean isDeployment() {
        return product != null && product.SBQQ__ChargeType__c != null && 'One-Time'.equalsIgnoreCase(product.SBQQ__ChargeType__c);
    }

    public Boolean isTopLevel() {
        return bundled == false;
    }

    public Boolean isSeat() {
        return product != null && product.PG1__c == 'License' && product.PG2__c == 'Base Plans' && product.PG3__c == 'Base';
    }
}
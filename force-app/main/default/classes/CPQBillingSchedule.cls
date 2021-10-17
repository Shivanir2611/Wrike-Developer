public class CPQBillingSchedule {

    public Id id {get; set;}
    public String name {get; set;}
    @AuraEnabled
    public Integer invoiceNumber {get; set;}
    @AuraEnabled
    public Date invoiceDate {get; set;}
    public Date serviceStartDate {get; set;}
    public Date serviceEndDate {get; set;}
    public Decimal term {get; set;}
    @AuraEnabled
    public Id quoteId {get; set;}
    @AuraEnabled
    public Decimal subscriptionAmount {get { return subscriptionAmount == null ? 0 : subscriptionAmount; } set;}
    @AuraEnabled
    public Decimal oneTimeFeeAmount {get { return oneTimeFeeAmount == null ? 0 : oneTimeFeeAmount; } set;}
    @AuraEnabled
    public String currencyCode {get; set;}
}
public class OpportunityValidationResult {
    @AuraEnabled
    public String message {get; set;}

    @AuraEnabled
    public Boolean isAmendment {get; set;}
    @AuraEnabled
    public Boolean isOutbound {get; set;}
    @AuraEnabled
    public Boolean isSent {get; set;}
    @AuraEnabled
    public Boolean isNewSubscription {get; set;}

    @AuraEnabled
    public Map<String, Object> wrikeAccountInfo {get; set;}

    @AuraEnabled
    public ZuoraObject.ZuoraAmendment cancelledAmendment {get; set;}
    @AuraEnabled
    public ZuoraObject.ZuoraAccount zuoraAccount {get; set;}
    @AuraEnabled
    public ZuoraObject.ZuoraSubscription zuoraSubscription {get; set;}
    @AuraEnabled
    public List<OpportunityValidationUtils.SubscriptionProduct> zuoraSubscriptionProducts {get; set;}

    @AuraEnabled
    public String billingPeriod {get; set;}
    @AuraEnabled
    public String wrikeUrl {get; set;}
    @AuraEnabled
    public Boolean isRenewalQuotesAvailable {get; set;}
}
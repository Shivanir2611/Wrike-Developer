public class BillToShipToForm {
    @AuraEnabled
    public QS_Bill_To_Ship_To__c billTo {get; set;}
    @AuraEnabled
    public QS_Bill_To_Ship_To__c shipTo {get; set;}
    @AuraEnabled
    public QS_Bill_To_Ship_To__c endCustomer {get; set;}
    @AuraEnabled
    public Map<String, String> countryMap {get; set;}
    @AuraEnabled
    public Map<String, String> usStateMap {get; set;}
    @AuraEnabled
    public Map<String, String> canadaStateMap {get; set;}

    public BillToShipToForm() {
        this.countryMap = CountryUtil.getCountryCodeMap();
        this.usStateMap = CountryUtil.getUsIsoStates();
        this.canadaStateMap = CountryUtil.getCanadaIsoStates();
    }
}
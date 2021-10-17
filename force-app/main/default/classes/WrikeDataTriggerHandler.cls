public class WrikeDataTriggerHandler {
    
    public static WrikeDataTriggerHandler getInstance() {
        return (WrikeDataTriggerHandler)ServiceLocator.getInstance(WrikeDataTriggerHandler.class);
    }
    
    public void beforeUpdate(final Map<Id, WrikeData__c> oldMap, final Map<Id, WrikeData__c> newMap) {
        for(WrikeData__c newWrikeData :  newMap.values()){
            final WrikeData__c oldWrikeData = oldMap.get(newWrikeData.Id); 
            if(oldWrikeData.Contract_End_Date__c != newWrikeData.Contract_End_Date__c){
                newWrikeData.Last_Contract_End_Date__c = oldWrikeData.Contract_End_Date__c;		    
            }
            if(newWrikeData.PremiumSupportAddonMrr__c != null && oldWrikeData.PremiumSupportAddonMrr__c == null && oldWrikeData.PremiumSupportStartDate__c == null) {
                newWrikeData.PremiumSupportStartDate__c = Date.today();
            }
            if(newWrikeData.CompanyName__c != oldWrikeData.CompanyName__c
                    || newWrikeData.CountryCode__c != oldWrikeData.CountryCode__c) {
                newWrikeData.LastOwnerUpdateDate__c = DateTime.now();
            }
            if(newWrikeData.MRR__c != oldWrikeData.MRR__c){
                newWrikeData.Previous_MRR__c = oldWrikeData.MRR__c;
                newWrikeData.Previous_MRR_Change_Date__c = DateUtils.getPacificLocalDate();
            }
        }   
    }
}
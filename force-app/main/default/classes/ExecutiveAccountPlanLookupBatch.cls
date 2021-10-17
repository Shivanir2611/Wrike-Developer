public class ExecutiveAccountPlanLookupBatch implements Database.Batchable<SObject>, Schedulable {
    
    private Integer batchSize;
    
    public ExecutiveAccountPlanLookupBatch() {
        this.batchSize = 10;
    }
    
    public ExecutiveAccountPlanLookupBatch(final Integer batchSize) {
        this.batchSize = batchSize;
    }
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this, batchSize);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Strategic_Account_Group__c, Account_Plan_Identifier__c
            FROM Executive_Account_Plan__c
            WHERE Strategic_Account_Group__c != null
            OR Account_Plan_Identifier__c != null
            ORDER BY CreatedDate ASC
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<Executive_Account_Plan__c> executiveAccountPlans){   
        Map<String, Id> strategicAccountGroupMap = new Map<String, Id>();
        Map<String, Id> accountPlanIdentifierMap = new Map<String, Id>();
        
        for(Executive_Account_Plan__c eapRecord : executiveAccountPlans){
            if(!String.isBlank(eapRecord.Strategic_Account_Group__c)){
                strategicAccountGroupMap.put(eapRecord.Strategic_Account_Group__c, eapRecord.Id);    
            }
            if(!String.isBlank(eapRecord.Account_Plan_Identifier__c)){
                accountPlanIdentifierMap.put(eapRecord.Account_Plan_Identifier__c, eapRecord.Id);
            }  
        }
        relatedOpportunities(accountPlanIdentifierMap);
        relatedSubscriptions(strategicAccountGroupMap);
        relatedDeployments(strategicAccountGroupMap);
    }
    
    private void relatedOpportunities(Map<String, Id> accountPlanIdentifierMap){
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opportunity : [
            SELECT Id, Account_Plan_Identifier__c, Executive_Account_Plan__c 
            FROM Opportunity
            WHERE Account_Plan_Identifier__c IN : accountPlanIdentifierMap.keySet()
            AND Account_Plan_Identifier__c != null
            AND Type != 'Renewal'
        ]){
            Id opportunityEAPId = accountPlanIdentifierMap.get(opportunity.Account_Plan_Identifier__c);
            if(opportunity.Executive_Account_Plan__c != opportunityEAPId){
                opportunity.Executive_Account_Plan__c = opportunityEAPId;   
                oppList.add(opportunity);
            }
        }
        if(!oppList.isEmpty()){
            update oppList;    
        }
    }
    
    private void relatedSubscriptions(Map<String, Id> strategicAccountGroupMap){
        List<Subscription__c> subscriptionList = new List<Subscription__c>();
        for(Subscription__c subscription : [
            SELECT Id, Strategic_Account_Group__c, Executive_Account_Plan__c 
            FROM Subscription__c
            WHERE Strategic_Account_Group__c IN : strategicAccountGroupMap.keySet()
            AND Strategic_Account_Group__c != null
        ]){ 
            Id subscriptionEAPId = strategicAccountGroupMap.get(subscription.Strategic_Account_Group__c);
            if(subscription.Executive_Account_Plan__c != subscriptionEAPId){
                subscription.Executive_Account_Plan__c = subscriptionEAPId;   
                subscriptionList.add(subscription);
            }
        }
        if(!subscriptionList.isEmpty()){
            update subscriptionList;    
        }
    }
    
    private void relatedDeployments(Map<String, Id> strategicAccountGroupMap){
        List<Deployment__c> deploymentList = new List<Deployment__c>();
        for(Deployment__c deployment : [
            SELECT Id, Strategic_Account_Group__c, Executive_Account_Plan__c 
            FROM Deployment__c
            WHERE Strategic_Account_Group__c IN : strategicAccountGroupMap.keySet()
            AND Strategic_Account_Group__c != null
        ]){
            Id deploymentEAPId = strategicAccountGroupMap.get(deployment.Strategic_Account_Group__c);
            if(deployment.Executive_Account_Plan__c != deploymentEAPId){
                deployment.Executive_Account_Plan__c = deploymentEAPId;   
                deploymentList.add(deployment);
            }
        }
        if(!deploymentList.isEmpty()){
            update deploymentList;    
        }
    }
    
    public void finish(final Database.BatchableContext context){
    }
}
public class WrikeDeploymentUpdateJob implements Database.Batchable<SObject>, Schedulable {
    
    public void execute(final SchedulableContext sc){
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context){
        return Database.getQueryLocator([
            SELECT Id, Wrike_Account_ID__c, Subscription__c, Wrike_Data__c 
            FROM Deployment__c
            WHERE Wrike_Account_ID__c != NULL 
            AND (Subscription__c = NULL
                 OR Wrike_Data__c = NULL)
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<Deployment__c> deployments){
        final List<Integer> wrikeAccountIds = new List<Integer>();
        final Map<Integer, Id> subscriptionMap = new Map<Integer,Id>();
        final Map<Integer, Id> wrikeDataMap = new Map<Integer,Id>();
        final Map<Id, Deployment__c> deploymentsToUpdate = new Map<Id, Deployment__c>();
        for(Deployment__c deployment : deployments){
            wrikeAccountIds.add(Integer.valueOf(deployment.Wrike_Account_ID__c));
        }
        for(Subscription__c subscription : [
            SELECT Id, Wrike_Account_Id__c
            FROM Subscription__c
            WHERE Wrike_Account_Id__c IN : wrikeAccountIds
        ]){
            subscriptionMap.put(Integer.valueOf(subscription.Wrike_Account_Id__c), subscription.Id);
        }
        for(WrikeData__c wrikeData : [
            SELECT Id, Wrike_Account_Id__c
            FROM WrikeData__c
            WHERE Wrike_Account_Id__c IN : wrikeAccountIds
        ]){
            wrikeDataMap.put(Integer.valueOf(wrikeData.Wrike_Account_Id__c), wrikeData.Id);
        }
        for(Deployment__c deployment : deployments){
            final Integer wrikeAccountId = Integer.valueOf(deployment.Wrike_Account_ID__c);
            if(deployment.Subscription__c == NULL && subscriptionMap.containsKey(wrikeAccountId)){
                getDeploymentForUpdate(deployment, deploymentsToUpdate).Subscription__c = subscriptionMap.get(wrikeAccountId);
            }
            if(deployment.Wrike_Data__c == NULL && wrikeDataMap.containsKey(wrikeAccountId)){
                getDeploymentForUpdate(deployment, deploymentsToUpdate).Wrike_Data__c = wrikeDataMap.get(wrikeAccountId);
            }
        }
        if(!deploymentsToUpdate.isEmpty()){
            update deploymentsToUpdate.values();
        }
    }
    
    private Deployment__c getDeploymentForUpdate(final Deployment__c deployment, final Map<Id, Deployment__c> deploymentsToUpdate){
        if(!deploymentsToUpdate.containsKey(deployment.Id)){
            deploymentsToUpdate.put(deployment.Id, deployment);
        }
        return deployment;
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}
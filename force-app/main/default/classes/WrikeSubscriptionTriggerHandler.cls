/*
* Created by sofia.kanukova on 02/09/2019.
*/
public class WrikeSubscriptionTriggerHandler {
    
    public static WrikeSubscriptionTriggerHandler getInstance() {
        return (WrikeSubscriptionTriggerHandler)ServiceLocator.getInstance(WrikeSubscriptionTriggerHandler.class);
    }
    
    public void afterInsert(final List<Subscription__c> subscriptions) {
        final AccountService accountSrv = AccountService.getInstance();
        final Map<Integer, Id> wrikeAccountIdToSubscriptionId = new Map<Integer, Id>();
        final Set<Id> accountsToUpdate = new Set<Id>();
        
        for (Subscription__c subscription : subscriptions) {
            if (subscription.Wrike_Account_Id__c != null) {
                wrikeAccountIdToSubscriptionId.put(Integer.valueOf(subscription.Wrike_Account_Id__c), subscription.Id);
            }
            accountsToUpdate.add(subscription.Account__c);
        }
        accountSrv.updateAccountSubscriptionData(accountsToUpdate);
        updateDeployments(wrikeAccountIdToSubscriptionId);
    }
    
    public void afterUpdate(final Map<Id, Subscription__c> newMap, final Map<Id, Subscription__c> oldMap) {
        final AccountService accountSrv = AccountService.getInstance();
        final Set<Id> accountsToUpdate = new Set<Id>();
        final Map<Id, Id> reassignedSubs = new Map<Id, Id>();
        
        for (Subscription__c subscription : newMap.values()) {
            Subscription__c oldSubscription = oldMap.get(subscription.Id);
            if (subscription.Account__c != oldSubscription.Account__c || subscription.Status__c != oldSubscription.Status__c) {
                accountsToUpdate.add(subscription.Account__c);
            }
            if (oldSubscription.OwnerId != subscription.OwnerId && ApexUtils.isUser(subscription.OwnerId)) {
                reassignedSubs.put(subscription.Id, subscription.OwnerId);
            }
        }
        accountSrv.updateAccountSubscriptionData(accountsToUpdate);

        if (!reassignedSubs.isEmpty()) {
            updateTasks(reassignedSubs);
        }
        accountPrimaryCSMUpdate(oldMap, newMap.values());
    }
    
    private void updateTasks(Map<Id, Id> reassignedSubs) {
        List<Task> tasksToUpdate = new List<Task>();
        List<Task> openTasks = [
            SELECT Id, OwnerId, WhatId
            FROM Task
            WHERE Status = 'Open'
            AND WhatId IN :reassignedSubs.keySet()
            AND ActivityDate >= LAST_N_DAYS:30
        ];
        for (Task task : openTasks) {
            final Id newOwnerId = reassignedSubs.get(task.WhatId);
            if (task.OwnerId != newOwnerId) {
                tasksToUpdate.add(new Task(Id = task.Id, OwnerId = newOwnerId));
            }
        }
        
        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }
    
    private void updateDeployments(Map<Integer, Id> wrikeAccountIdToSubscriptionId) {
        final List<Deployment__c> deployments = [
            SELECT Id, Opportunity__r.Wrike_Account_Id__c
            FROM Deployment__c
            WHERE Opportunity__r.Wrike_Account_Id__c IN :wrikeAccountIdToSubscriptionId.keySet()
            AND Subscription__c = null
        ];
        if (!deployments.isEmpty()) {
            for (Deployment__c deployment : deployments) {
                deployment.Subscription__c = wrikeAccountIdToSubscriptionId.get(Integer.valueOf(deployment.Opportunity__r.Wrike_Account_Id__c));
            }
            update deployments;
        }
    }
    
    private void accountPrimaryCSMUpdate(final Map<Id, Subscription__c> oldMap, final List<Subscription__c> subscriptionList){
        final List<Id> accountIdsList = new List<Id>();
        for(Subscription__c sub : subscriptionList){
            Subscription__c oldRecord = oldMap.get(sub.Id);
            if(sub.Account__c != null && (oldRecord.Account__c != sub.Account__c || oldRecord.OwnerId != sub.OwnerId)){
                accountIdsList.add(sub.Account__c);
                if(!accountIdsList.contains(oldRecord.Account__c)){
                    accountIdsList.add(oldRecord.Account__c);  
                }
            } 
        }
        if(!accountIdsList.isEmpty()){
            List<Account> accountList = new List<Account>();
            for(AggregateResult newSubscription : [
                SELECT Account__c accountId, MAX(OwnerId) primaryCSMId
                FROM Subscription__c
                WHERE Status__c = 'Active'
                    AND Owner.ProfileId = '00e2A000001EO4gQAG'
                    AND Account__c IN : accountIdsList
                    AND Account__r.Primary_CSM__c = null 
                GROUP BY Account__c
                HAVING COUNT_DISTINCT(OwnerId) = 1
            ]){
                accountList.add(new Account(Id = (Id)newSubscription.get('accountId'), Primary_CSM__c = (Id)newSubscription.get('primaryCSMId')));
            }
            if(!accountList.isEmpty()){
                update accountList;
            }
        }
    }
}
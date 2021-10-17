public class WrikeDeploymentShareLogic {
    @AuraEnabled public static void runOwnerRules(Id recordId, String mode) {
        if(mode != 'Batch'){
            List<Deployment__c> deployment=[
                SELECT Id, Account__c, Subscription__c, OwnerId 
                FROM Deployment__c 
                WHERE Owner.ProfileId='00e1Y000001JSsOQAW' AND Id =: recordId
            ];
            checkShareRecordAccess(deployment); 
        } else{
            Id batchJobId = Database.executeBatch(new WrikeDeploymentBatchJob(), 200); 
        }
    } 
    
    public static void checkShareRecordAccess(final List<Deployment__c> deployments){
        final List<AccountShare> accountShareList = new List<AccountShare>();
        final List<Subscription__Share> subscriptionShareList = new List<Subscription__Share>(); 
        final List<Id> accountIds = new List<Id>();
        final List<Id> subscriptionIds = new List<Id>();
        final Map<Id, List<Id>> accountShareMap = new Map<Id, List<Id>>();
        final Map<Id, List<Id>> subShareMap = new Map<Id, List<Id>>();
        for(Deployment__c deployment : deployments){
            if(deployment.Account__c != null){
                accountIds.add(deployment.Account__c);
            }
            if(deployment.Subscription__c != null){
                subscriptionIds.add(deployment.Subscription__c);	    
            }   
        }
        for(AccountShare acctShare : [
            SELECT AccountId, UserorGroupId 
            FROM AccountShare 
            WHERE AccountId IN: accountIds
        ]){
            if(!accountShareMap.containsKey(acctShare.AccountId)){
                accountShareMap.put(acctShare.AccountId, new List<Id>());
            }
            accountShareMap.get(acctShare.AccountId).add(acctShare.UserorGroupId);
        }	
        for(Subscription__Share subShare: [
            SELECT ParentId, UserorGroupId 
            FROM Subscription__Share 
            WHERE ParentId IN: subscriptionIds
        ]){
            if(!subShareMap.containsKey(subShare.ParentId)){
                subShareMap.put(subShare.ParentId, new List<Id>());
            }
            subShareMap.get(subShare.ParentId).add(subShare.UserorGroupId);
        }
        for(Deployment__c deployment : deployments){
            if(deployment.Account__c != null && !accountShareMap.get(deployment.Account__c).contains(deployment.ownerId)){
                accountShareList.add(accountShareCreation(deployment.OwnerId, deployment.Account__c)); 
            }
            if(deployment.Subscription__c != null && !subShareMap.get(deployment.Subscription__c).contains(deployment.ownerId)){
                subscriptionShareList.add(subscriptionShareCreation(deployment.OwnerId, deployment.Subscription__c)); 
            }   
        }
        if(!accountShareList.isEmpty()){
            insert accountShareList;
        }
        if(!subscriptionShareList.isEmpty()){
            insert subscriptionShareList;
        } 
    }
    
    private static AccountShare accountShareCreation(String ownerId, String accountId){
        AccountShare acctsShare = new AccountShare();
        acctsShare.AccountId = accountId;
        acctsShare.UserOrGroupId = ownerId; 
        acctsShare.AccountAccessLevel = 'Read';
        acctsShare.OpportunityAccessLevel = 'None';
        acctsShare.CaseAccessLevel = 'None';
        acctsShare.RowCause = 'Manual';
        return acctsShare; 
    }
    
    private static Subscription__Share subscriptionShareCreation(String ownerId, String subId){
        Subscription__Share subShare = new Subscription__Share();
        subShare.ParentId = subId;
        subShare.UserOrGroupId = ownerId;
        subShare.AccessLevel = 'Read'; 
        subShare.RowCause = 'Manual';
        return subShare; 
    }
}
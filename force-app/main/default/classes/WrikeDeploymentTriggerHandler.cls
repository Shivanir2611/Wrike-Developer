public class WrikeDeploymentTriggerHandler {
    public static WrikeDeploymentTriggerHandler getInstance() {
        return (WrikeDeploymentTriggerHandler)ServiceLocator.getInstance(WrikeDeploymentTriggerHandler.class);
    }    
    
    private Map<Id,Id> getOwnerMap(final List<Deployment__c> deploymentRecords){
        final List<Id> ownerList = new List<Id>();
        final Map<Id,Id> ownerProfileMap = new Map<Id,Id>();
        for(Deployment__c deployment : deploymentRecords){
          ownerList.add(deployment.ownerId);  
        }
        for(User usr: [SELECT Id, ProfileId FROM User WHERE Id IN: ownerList]){
            ownerProfileMap.put(usr.Id, usr.ProfileId);
        }
        return ownerProfileMap ;
    }
    public void afterInsert(final List<Deployment__c> newInsertedDeployments){
        final List<AccountShare> accountShareList = new List<AccountShare>();
        final List<Subscription__Share> subscriptionShareList = new List<Subscription__Share>();
        final Map<Id,Id> ownerProfileMap = getOwnerMap(newInsertedDeployments);
        final ShareWrapper shareWrapperObj = new ShareWrapper(newInsertedDeployments);
        for(Deployment__c deployment : newInsertedDeployments){
            if(deployment.Account__c != null && isPartnerUserCheck(deployment, ownerProfileMap)){
                if(!shareWrapperObj.uniqueAccountShare.contains((String)deployment.Account__c + (String)deployment.OwnerId)){ 
                    accountShareList.add(accountShareCreation(deployment.OwnerId, deployment.Account__c));
                }
            }
            if(deployment.Subscription__c != null && isPartnerUserCheck(deployment, ownerProfileMap)){
                if(!shareWrapperObj.uniqueSubscriptionShare.contains((String)deployment.Subscription__c + (String)deployment.OwnerId)){ 
                    subscriptionShareList.add(subscriptionShareCreation(deployment.OwnerId, deployment.Subscription__c));
                }
            }
        }
        if(!accountShareList.isEmpty()){
            insert accountShareList;   
        }
        if(!subscriptionShareList.isEmpty()){
            insert subscriptionShareList;   
        }   
    }    
    
    public void afterUpdate(final Map<Id,Deployment__c> oldMap, final Map<Id,Deployment__c> newMap){
        final List<AccountShare> accountShareList = new List<AccountShare>();
        final List<Subscription__Share> subscriptionShareList = new List<Subscription__Share>();
        final List<Id> oldOwners = new List<Id>();
        final Set<Id> accountIds = new Set<Id>();
        final Set<Id> subscriptionIds = new Set<Id>();
        final ShareWrapper shareWrapperObj = new ShareWrapper(newMap.values());
        final Map<Id,Id> ownerProfileMap = getOwnerMap(newMap.values());
        for(Deployment__c deployment : newMap.values()){
            final Deployment__c oldRecord = oldMap.get(deployment.Id);
            if(isSharingCheckRequired(deployment, oldRecord)){
                if(ApexUtils.isUser(oldRecord.OwnerId)){
                    oldOwners.add(oldRecord.OwnerId);
                }
                accountIds.add(deployment.Account__c);
                accountIds.add(oldRecord.Account__c);
                subscriptionIds.add(deployment.Subscription__c);
                subscriptionIds.add(oldRecord.Subscription__c);
            }
            if(deployment.Account__c != null && isSharingCheckRequired(deployment, oldRecord) && isPartnerUserCheck(deployment, ownerProfileMap)){
                if(!shareWrapperObj.uniqueAccountShare.contains((String)deployment.Account__c + (String)deployment.OwnerId)){
                    accountShareList.add(accountShareCreation(deployment.OwnerId, deployment.Account__c));
                }
            }
            if(deployment.Subscription__c != null && isSharingCheckRequired(deployment, oldRecord) && isPartnerUserCheck(deployment, ownerProfileMap)){
                if(!shareWrapperObj.uniqueSubscriptionShare.contains((String)deployment.Subscription__c + (String)deployment.OwnerId)){  
                    subscriptionShareList.add(subscriptionShareCreation(deployment.OwnerId, deployment.Subscription__c));
                }
            } 
        }
        if(!accountShareList.isEmpty()){
            insert accountShareList;
        }
        if(!subscriptionShareList.isEmpty()){
            insert subscriptionShareList;
        } 
        if(!oldOwners.isEmpty()){
            deleteRecordsSharing(oldOwners);
        }
    }
    
    private Boolean isPartnerUserCheck(final Deployment__c deployment, final Map<Id,Id> ownerProfileMap){
        return ApexUtils.isUser(deployment.OwnerId) && String.valueOf(deployment.OwnerId).startsWith('005') && ownerProfileMap.get(deployment.OwnerId) == '00e1Y000001JSsOQAW'; 
    }
    
    private Boolean isSharingCheckRequired(final Deployment__c deployment, final Deployment__c oldRecord){
        return deployment.OwnerId != oldRecord.OwnerId || deployment.Account__c != oldRecord.Account__c || deployment.Subscription__c != oldRecord.Subscription__c;
    } 
    
    private AccountShare accountShareCreation(String ownerId, String AccountId){
        AccountShare acctsShare = new AccountShare();
        acctsShare.AccountId = AccountId;
        acctsShare.UserOrGroupId = ownerId; 
        acctsShare.AccountAccessLevel = 'Read';
        acctsShare.OpportunityAccessLevel = 'None';
        acctsShare.CaseAccessLevel = 'None';
        acctsShare.RowCause = 'Manual';
        return acctsShare; 
    }
    
    private Subscription__Share subscriptionShareCreation(String ownerId, String subId){
        Subscription__Share subShare = new Subscription__Share();
        subShare.ParentId = subId;
        subShare.UserOrGroupId = ownerId;
        subShare.AccessLevel = 'Read'; 
        subShare.RowCause = 'Manual';
        return subShare; 
    }
    
    private class ShareWrapper{
        final Set<String> uniqueAccountShare {get; set;}
        final Set<String> uniqueSubscriptionShare {get; set;}
        public ShareWrapper(List<Deployment__c> newInsertedDeployments){
            final List<Id> accountIds = new List<Id>();
            final List<Id> subscriptionIds = new List<Id>();
            uniqueAccountShare = new Set<String>();
            uniqueSubscriptionShare = new Set<String>();
            for(Deployment__c deployment : newInsertedDeployments){
                if(deployment.Account__c != null){
                    accountIds.add(deployment.Account__c);
                }
                if(deployment.Subscription__c != null){
                    subscriptionIds.add(deployment.Subscription__c);
                }
            }
            for(Subscription__Share subShare: [
                SELECT ParentId, UserorGroupId 
                FROM Subscription__Share 
                WHERE ParentId in: subscriptionIds
            ]){
                uniqueSubscriptionShare.add((String)subShare.ParentId + (String)subShare.UserorGroupId); 
            }
            for(AccountShare accShare: [
                SELECT AccountId, UserorGroupId 
                FROM AccountShare 
                WHERE AccountId in: accountIds
            ]){
                uniqueAccountShare.add((String)accShare.AccountId + (String)accShare.UserorGroupId);
            } 
        }
    }
    
    private void deleteRecordsSharing(final List<Id> userIds) {
        final List<Deployment__c> deployments = [
            SELECT OwnerId, Account__c, Subscription__c
            FROM Deployment__c
            WHERE OwnerId IN :userIds
        ];
        final Map<Id, Set<Id>> ownerAccountMap = new Map<Id, Set<Id>>();
        final Map<Id, Set<Id>> ownerSubscriptionMap = new Map<Id, Set<Id>>();
        for(Deployment__c deployment : deployments) {
            if(ownerAccountMap.containsKey(deployment.OwnerId) && deployment.Account__c != null){
                Set<Id> AccountIds = ownerAccountMap.get(deployment.OwnerId);
                AccountIds.add(deployment.Account__c);
                ownerAccountMap.put(deployment.OwnerId,AccountIds);
            } else if(deployment.Account__c != null){
                Set<Id> AccountIds = new Set<Id>();
                AccountIds.add(deployment.Account__c);
                ownerAccountMap.put(deployment.OwnerId,AccountIds);
            }
            if(ownerSubscriptionMap.containsKey(deployment.OwnerId) && deployment.Subscription__c != null){
                Set<Id> subIds = ownerSubscriptionMap.get(deployment.OwnerId);
                subIds.add(deployment.Subscription__c);
                ownerSubscriptionMap.put(deployment.OwnerId,subIds);
                
            } else if(deployment.Subscription__c != null){
                Set<Id> subIds = new Set<Id>();
                subIds.add(deployment.Subscription__c);
                ownerSubscriptionMap.put(deployment.OwnerId,subIds);
            }
        }
        final List<AccountShare> accountShareList = [
            SELECT Id, UserOrGroupId, AccountId
            FROM AccountShare 
            WHERE UserOrGroupId IN :userIds and RowCause = 'Manual'
        ];
        final List<AccountShare> accountSharesToDelete = new List<AccountShare>();
        final List<Subscription__Share> subShareList = [
            SELECT Id, UserOrGroupId, parentId 
            FROM Subscription__Share 
            WHERE UserOrGroupId IN :userIds and RowCause = 'Manual'
        ];
        final List<Subscription__Share> subSharesToDelete = new List<Subscription__Share>();
        
        for(AccountShare accShare : accountShareList) {
            if(!ownerAccountMap.containsKey(accShare.UserOrGroupId) || !ownerAccountMap.get(accShare.UserOrGroupId).contains(accShare.AccountId)) {
                accountSharesToDelete.add(accShare);
            }
        }
        for(Subscription__Share subShare : subShareList) {
            if(!ownerSubscriptionMap.containsKey(subShare.UserOrGroupId) || !ownerSubscriptionMap.get(subShare.UserOrGroupId).contains(subShare.parentId)) {
                subSharesToDelete.add(subShare);
            }
        }
        if(!accountSharesToDelete.isEmpty()){
            delete accountSharesToDelete;
        }
        if(!subSharesToDelete.isEmpty()){
            delete subSharesToDelete;
        }
    }
}
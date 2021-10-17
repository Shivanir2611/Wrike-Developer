public class AccountRollUpBatchJob implements Database.Batchable<SObject>, Schedulable {
    
    private Integer batchSize;
    
    public AccountRollUpBatchJob() {
        this.batchSize = 100;
    }
    
    public AccountRollUpBatchJob(final Integer batchSize) {
        this.batchSize = batchSize;
    }
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this, batchSize);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Number_of_Child_Accounts__c, Max_Subscription_Churn_Date__c, Most_Recent_Subscription_Owner__c, 
                   ParentId, Number_of_Churned_Subscriptions__c, Number_of_Active_Subscriptions__c, 
                   Primary_Wrike_Subscription__c, All_Subscription_Terms__c, All_Trial_Types__c, Total_Collaborators_Purchased__c, 
                   Internal_Collaborators__c, External_Collaborators__c, Executive_Account_Plan__c
            FROM Account
            WHERE RecordType.DeveloperName = :RecordTypeQueryService.ACCOUNT_CUSTOMER
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<Account> accounts){    
        Map<Id, Account> accountUpdateMap = new Map<Id, Account>();
 
        getRelatedSubscriptions(accounts, accountUpdateMap);
        getRelatedPrimarySubscriptions(accounts, accountUpdateMap);
        getRelatedChildAccounts(accounts, accountUpdateMap);
        getRelatedExecutiveAccountPlans(accounts, accountUpdateMap);
        
        update accountUpdateMap.values();    
    }
    
    private void getRelatedSubscriptions(List<Account> accounts, Map<Id, Account> accountUpdateMap){
        Map<Id, String> subscriptionOwnerMap = new Map<Id, String>();
        Map<Id, Integer> churnedSubCountMap = new Map<Id, Integer>();
        Map<Id, Integer> activeSubCountMap = new Map<Id, Integer>();
        Map<Id, Set<String>> subscriptionTermsMap = new Map<Id, Set<String>>();
        Map<Id, Set<String>> allTrialTypesMap = new Map<Id, Set<String>>();
        Map<Id, Date> maxChurnedDateMap = new Map<Id, Date>();
        Map<Id, Integer> totalCollaboratorsPurchasedMap = new Map<Id, Integer>();
        Map<Id, Integer> internalCollaboratorsMap = new Map<Id, Integer>();
        Map<Id, Integer> externalCollaboratorsMap = new Map<Id, Integer>();
        
        for(Subscription__c subscription : [
            SELECT Id, Account__c, Churned_Date__c, Wrike_Data__r.Trial_Type__c, Annual__c, 
            	   Owner.Name, Status__c, Subscription_Collaborators_Purchased__c,
            	   Subscription_Internal_Collaborators__c, Subscription_External_Collaborators__c
            FROM Subscription__c 
            WHERE Account__c IN: new Map<Id, Account>(accounts).keySet()  
            ORDER BY CreatedDate DESC
        ]){
            if(!subscriptionTermsMap.containsKey(subscription.Account__c)){
                subscriptionTermsMap.put(subscription.Account__c,new Set<String>());     
            }
            subscriptionTermsMap.get(subscription.Account__c).add(subscription.Annual__c);

            if(subscription.Churned_Date__c != null){
                if(!maxChurnedDateMap.containsKey(subscription.Account__c)){
                    maxChurnedDateMap.put(subscription.Account__c, subscription.Churned_Date__c);      
                } else{
                    Date maxChurnDate = maxChurnedDateMap.get(subscription.Account__c);
                    if(subscription.Churned_Date__c > maxChurnDate){
                        maxChurnedDateMap.put(subscription.Account__c, subscription.Churned_Date__c);
                    }
                }
            }
            if(subscription.Status__c == 'Active'){
                if(!allTrialTypesMap.containsKey(subscription.Account__c)){
                    allTrialTypesMap.put(subscription.Account__c,new Set<String>());     
                }
                allTrialTypesMap.get(subscription.Account__c).add(subscription.Wrike_Data__r.Trial_Type__c);
                
                if(!subscriptionOwnerMap.containsKey(subscription.Account__c)){
                    subscriptionOwnerMap.put(subscription.Account__c,subscription.Owner.Name);
                }

                if(!totalCollaboratorsPurchasedMap.containsKey(subscription.Account__c)){
                    totalCollaboratorsPurchasedMap.put(subscription.Account__c, 0);
                }
                totalCollaboratorsPurchasedMap.put(subscription.Account__c, totalCollaboratorsPurchasedMap.get(subscription.Account__c) + Integer.valueOf(subscription.Subscription_Collaborators_Purchased__c));    
                
                if(!internalCollaboratorsMap.containsKey(subscription.Account__c)){
                    internalCollaboratorsMap.put(subscription.Account__c, 0);
                }
                internalCollaboratorsMap.put(subscription.Account__c, internalCollaboratorsMap.get(subscription.Account__c) + Integer.valueOf(subscription.Subscription_Internal_Collaborators__c));
                
                if(!externalCollaboratorsMap.containsKey(subscription.Account__c)){
                    externalCollaboratorsMap.put(subscription.Account__c, 0);
                }
                externalCollaboratorsMap.put(subscription.Account__c, externalCollaboratorsMap.get(subscription.Account__c) + Integer.valueOf(subscription.Subscription_External_Collaborators__c));

                if(!activeSubCountMap.containsKey(subscription.Account__c)){
                    activeSubCountMap.put(subscription.Account__c, 0);
                }
                activeSubCountMap.put(subscription.Account__c, activeSubCountMap.get(subscription.Account__c) + 1);    
            }
            if(subscription.Status__c == 'Deleted' || subscription.Status__c == 'Free'){
                if(!churnedSubCountMap.containsKey(subscription.Account__c)){
                    churnedSubCountMap.put(subscription.Account__c, 0);
                }
                churnedSubCountMap.put(subscription.Account__c, churnedSubCountMap.get(subscription.Account__c) + 1);
            }   
        }
        for(Account account : accounts){
            final Date maxChurnedDate = maxChurnedDateMap.containsKey(account.Id) 
                                        ? maxChurnedDateMap.get(account.Id)
                                        : null;
            if(maxChurnedDate != account.Max_Subscription_Churn_Date__c) {
                addAccountToUpdate(account.Id, accountUpdateMap).Max_Subscription_Churn_Date__c = maxChurnedDate;  
            }
            final String subOwner = subscriptionOwnerMap.containsKey(account.Id) 
                                    ? subscriptionOwnerMap.get(account.Id)
                                    : null;
            if(subOwner != account.Most_Recent_Subscription_Owner__c) {
                addAccountToUpdate(account.Id, accountUpdateMap).Most_Recent_Subscription_Owner__c = subOwner;  
            }
            final String churnedCount = churnedSubCountMap.containsKey(account.Id) 
                                        ? String.valueOf(churnedSubCountMap.get(account.Id))
                                        : null;
            if(churnedCount != account.Number_of_Churned_Subscriptions__c) {
                addAccountToUpdate(account.Id, accountUpdateMap).Number_of_Churned_Subscriptions__c = churnedCount;  
            }
            final String activeCount = activeSubCountMap.containsKey(account.Id) 
                                       ? String.valueOf(activeSubCountMap.get(account.Id))
                                       : null;
            if(activeCount != account.Number_of_Active_Subscriptions__c) {
                addAccountToUpdate(account.Id, accountUpdateMap).Number_of_Active_Subscriptions__c = activeCount;  
            }
            final Integer totalCollabCount = totalCollaboratorsPurchasedMap.containsKey(account.Id) 
                                             ? totalCollaboratorsPurchasedMap.get(account.Id)
                                             : null;
            if(totalCollabCount != account.Total_Collaborators_Purchased__c) {
                addAccountToUpdate(account.Id, accountUpdateMap).Total_Collaborators_Purchased__c = totalCollabCount;  
            }
            final Integer internalCollabCount = internalCollaboratorsMap.containsKey(account.Id) 
                                                ? internalCollaboratorsMap.get(account.Id)
                                                : null;
            if(internalCollabCount != account.Internal_Collaborators__c) {
                addAccountToUpdate(account.Id, accountUpdateMap).Internal_Collaborators__c = internalCollabCount;  
            }
            final Integer externalCollabCount = externalCollaboratorsMap.containsKey(account.Id) 
                                                ? externalCollaboratorsMap.get(account.Id)
                                                : null;
            if(externalCollabCount != account.External_Collaborators__c) {
                addAccountToUpdate(account.Id, accountUpdateMap).External_Collaborators__c = externalCollabCount;  
            }
            if(subscriptionTermsMap.containsKey(account.Id)){
                final String subTerms = subscriptionTermsMap.get(account.Id) != null ? String.join(new List<String>(subscriptionTermsMap.get(account.Id)),' ') : '';
                addAccountToUpdate(account.Id, accountUpdateMap).All_Subscription_Terms__c = subTerms;
            }
            if(allTrialTypesMap.containsKey(account.Id)){
                final String trialTypes = allTrialTypesMap.get(account.Id) != null ? String.join(new List<String>(allTrialTypesMap.get(account.Id)),' ') : '';
                addAccountToUpdate(account.Id, accountUpdateMap).All_Trial_Types__c = trialTypes;
            }
        }
    }
    
    private void getRelatedPrimarySubscriptions(List<Account> accounts, Map<Id, Account> accountUpdateMap){
        Map<Id, Id> primarySubscriptionMap = new Map<Id, Id>();
        for(Subscription__c subscription : [
            SELECT Id , Account__c 
            FROM Subscription__c 
            WHERE Status__c = 'Active'
            AND Account__c IN: new Map<Id, Account>(accounts).keySet()
            ORDER BY Subscription_MRR__c DESC NULLS LAST, Contract_Start_Date__c DESC NULLS LAST
        ]){
            if(!primarySubscriptionMap.containsKey(subscription.Account__c)){
                primarySubscriptionMap.put(subscription.Account__c,subscription.Id);
            }
        }
        for(Account account : accounts){
            final Id subId = primarySubscriptionMap.containsKey(account.Id) 
                             ? primarySubscriptionMap.get(account.Id)
                             : null;
            if(subId != account.Primary_Wrike_Subscription__c) {
                addAccountToUpdate(account.Id, accountUpdateMap).Primary_Wrike_Subscription__c = subId;  
            }
        }
    }
    
    private void getRelatedChildAccounts(List<Account> accounts, Map<Id, Account> accountUpdateMap){
        Map<Id,AggregateResult> countOfChildAccountsMap = new Map<Id,AggregateResult>([
            SELECT ParentId Id, Count(Id) childAccounts 
            FROM Account
            WHERE Id IN: new Map<Id, Account>(accounts).keySet()
            AND ParentId != null
            GROUP BY ParentId
        ]);      
        for(Account account : accounts){
            final Integer countChildAccounts = countOfChildAccountsMap.containsKey(account.Id) 
                                               ? (Integer)countOfChildAccountsMap.get(account.Id).get('childAccounts')
                                               : 0;
            if(countChildAccounts != account.Number_of_Child_Accounts__c){
                addAccountToUpdate(account.Id, accountUpdateMap).Number_of_Child_Accounts__c = countChildAccounts;  
            }
        }
    }
    
    private void getRelatedExecutiveAccountPlans(List<Account> accounts, Map<Id, Account> accountUpdateMap){
        Map<Id, Id> primaryEAPMap = new Map<Id, Id>();
        for(Executive_Account_Plan__c eapRecord : [
            SELECT Id, Account__c
            FROM Executive_Account_Plan__c
            WHERE Account__c IN : new Map<Id, Account>(accounts).keySet()
            ORDER BY CreatedDate DESC
        ]){
            if(!primaryEAPMap.containsKey(eapRecord.Account__c)){
                primaryEAPMap.put(eapRecord.Account__c,eapRecord.Id);
            }    
        }
        for(Account account : accounts){
            final Id eapId = primaryEAPMap.containsKey(account.Id) 
                             ? primaryEAPMap.get(account.Id)
                             : null;
            if(eapId != account.Executive_Account_Plan__c){
                addAccountToUpdate(account.Id, accountUpdateMap).Executive_Account_Plan__c = eapId;  
            }
        }     
    }
    
    private Account addAccountToUpdate(final Id accountId, final Map<Id, Account> accountUpdateMap) {
        if(!accountUpdateMap.containsKey(accountId)) {
            accountUpdateMap.put(accountId, new Account(Id = accountId));
        }
        return accountUpdateMap.get(accountId);
    }
    
    public void finish(final Database.BatchableContext context){
    }
}
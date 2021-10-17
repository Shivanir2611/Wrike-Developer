public class ExecutiveAccountPlanBatchJob implements Database.Batchable<SObject>, Schedulable {
    
    private Integer batchSize;
    
    public ExecutiveAccountPlanBatchJob() {
        this.batchSize = 10;
    }
    
    public ExecutiveAccountPlanBatchJob(final Integer batchSize) {
        this.batchSize = batchSize;
    }
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this, batchSize);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Number_of_Decision_Makers__c, Account_Plan_Champion_Name__c, Sum_of_Closed_Opportunity_MRR__c,
            	   Total_Closed_Sales_Opportunities__c, Total_Sales_Opportunties__c,  Account_Plan_Champion_Department__c, 
                   Number_of_Champions__c, Number_of_Churned_Accounts__c, Sum_of_Open_Opportunity_MRR__c,
            	   Number_of_Prospect_Accounts__c, Number_of_Customer_Accounts__c
            FROM Executive_Account_Plan__c
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<Executive_Account_Plan__c> executiveAccountPlans) {
        final Map<Id, Executive_Account_Plan__c> executiveAccountPlanUpdateMap = new Map<Id, Executive_Account_Plan__c>();
        
        relatedAccountPlans(executiveAccountPlans, executiveAccountPlanUpdateMap);
        relatedAccounts(executiveAccountPlans, executiveAccountPlanUpdateMap);
        relatedOpportunities(executiveAccountPlans, executiveAccountPlanUpdateMap);
        
        update executiveAccountPlanUpdateMap.values();
    }
    
    private void relatedAccountPlans(List<Executive_Account_Plan__c> executiveAccountPlans, Map<Id, Executive_Account_Plan__c> executiveAccountPlanUpdateMap) {
        final Map<Id, Integer> countOfDecisionMakersMap = new Map<Id, Integer>();
        final Map<Id, Integer> countOfChampionsMap = new Map<Id, Integer>();
        final Map<Id, String> oldestChampionNameMap = new Map<Id, String>();
        final Map<Id, String> oldestChampionDeptMap = new Map<Id, String>();
        
        for(Account_Plan_Relationship__c accountPlanRelationship : [
            SELECT Id, Executive_Account_Plan__c, Buying_Role__c, Support__c, Contact_Department__c, Contact__r.Name
            FROM Account_Plan_Relationship__c
            WHERE Executive_Account_Plan__c IN: new Map<Id, Executive_Account_Plan__c>(executiveAccountPlans).keySet()
            ORDER BY CreatedDate ASC
        ]){
            if(accountPlanRelationship.Buying_Role__c == 'Decision Maker'){
                addCountEAPMap(countOfDecisionMakersMap, accountPlanRelationship.Executive_Account_Plan__c);
            }
            if(accountPlanRelationship.Support__c == 'Champion'){
                addCountEAPMap(countOfChampionsMap, accountPlanRelationship.Executive_Account_Plan__c);
            }
            if(accountPlanRelationship.Support__c == 'Confirmed Champion'){
                if(accountPlanRelationship.Contact__c != null){
                    if(!oldestChampionNameMap.containsKey(accountPlanRelationship.Executive_Account_Plan__c)){
                        oldestChampionNameMap.put(accountPlanRelationship.Executive_Account_Plan__c, accountPlanRelationship.Contact__r.Name);
                    }
                }
                if(accountPlanRelationship.Contact_Department__c != null){
                    if(!oldestChampionDeptMap.containsKey(accountPlanRelationship.Executive_Account_Plan__c)){
                        oldestChampionDeptMap.put(accountPlanRelationship.Executive_Account_Plan__c, accountPlanRelationship.Contact_Department__c);
                    }    
                }
            }
        }
        for(Executive_Account_Plan__c executiveAccountPlan : executiveAccountPlans){
            if(countOfDecisionMakersMap.containsKey(executiveAccountPlan.Id) && executiveAccountPlan.Number_of_Decision_Makers__c != countOfDecisionMakersMap.get(executiveAccountPlan.Id)){
                addEAPToUpdate(executiveAccountPlan.Id, executiveAccountPlanUpdateMap).Number_of_Decision_Makers__c = countOfDecisionMakersMap.get(executiveAccountPlan.Id);
            }
            if(countOfChampionsMap.containsKey(executiveAccountPlan.Id) && executiveAccountPlan.Number_of_Champions__c != countOfChampionsMap.get(executiveAccountPlan.Id)){
                addEAPToUpdate(executiveAccountPlan.Id, executiveAccountPlanUpdateMap).Number_of_Champions__c = countOfChampionsMap.get(executiveAccountPlan.Id);
            }
            if(oldestChampionNameMap.containsKey(executiveAccountPlan.Id) && executiveAccountPlan.Account_Plan_Champion_Name__c != oldestChampionNameMap.get(executiveAccountPlan.Id)){
                addEAPToUpdate(executiveAccountPlan.Id, executiveAccountPlanUpdateMap).Account_Plan_Champion_Name__c = oldestChampionNameMap.get(executiveAccountPlan.Id);
            }
            if(oldestChampionDeptMap.containsKey(executiveAccountPlan.Id) && executiveAccountPlan.Account_Plan_Champion_Department__c != oldestChampionDeptMap.get(executiveAccountPlan.Id)){
                addEAPToUpdate(executiveAccountPlan.Id, executiveAccountPlanUpdateMap).Account_Plan_Champion_Department__c = oldestChampionDeptMap.get(executiveAccountPlan.Id);
            }
        }
    }
    
    private void relatedAccounts(List<Executive_Account_Plan__c> executiveAccountPlans, Map<Id, Executive_Account_Plan__c> executiveAccountPlanUpdateMap) {
        Map<Id,AggregateResult> countOfChurnedAccountsMap = new Map<Id,AggregateResult>([
            SELECT Executive_Account_Plan__c Id, Count(Id) churnedAccounts 
            FROM Account
            WHERE Executive_Account_Plan__c IN: new Map<Id, Executive_Account_Plan__c>(executiveAccountPlans).keySet()
            AND Type = 'Churned'
            GROUP BY Executive_Account_Plan__c
        ]);
        for(Executive_Account_Plan__c eap : executiveAccountPlans){
            final Integer countChurnedAccounts = countOfChurnedAccountsMap.containsKey(eap.Id) 
                                                 ? (Integer)countOfChurnedAccountsMap.get(eap.Id).get('churnedAccounts')
                                                 : 0;
            if(countChurnedAccounts != eap.Number_of_Churned_Accounts__c){
                addEAPToUpdate(eap.Id, executiveAccountPlanUpdateMap).Number_of_Churned_Accounts__c = countChurnedAccounts;  
            }
        }
        
        Map<Id,AggregateResult> countOfProspectAccountsMap = new Map<Id,AggregateResult>([
            SELECT Executive_Account_Plan__c Id, Count(Id) prospectAccounts 
            FROM Account
            WHERE Executive_Account_Plan__c IN: new Map<Id, Executive_Account_Plan__c>(executiveAccountPlans).keySet()
            AND Type = 'Prospect'
            GROUP BY Executive_Account_Plan__c
        ]);
        for(Executive_Account_Plan__c eap : executiveAccountPlans){
            final Integer countProspectAccounts = countOfProspectAccountsMap.containsKey(eap.Id) 
                                                  ? (Integer)countOfProspectAccountsMap.get(eap.Id).get('prospectAccounts')
                                                  : 0;
            if(countProspectAccounts != eap.Number_of_Prospect_Accounts__c){
                addEAPToUpdate(eap.Id, executiveAccountPlanUpdateMap).Number_of_Prospect_Accounts__c = countProspectAccounts;  
            }
        }
        
        Map<Id,AggregateResult> countOfCustomerAccountsMap = new Map<Id,AggregateResult>([
            SELECT Executive_Account_Plan__c Id, Count(Id) customerAccounts 
            FROM Account
            WHERE Executive_Account_Plan__c IN: new Map<Id, Executive_Account_Plan__c>(executiveAccountPlans).keySet()
            AND Type = 'Customer'
            GROUP BY Executive_Account_Plan__c
        ]);
        for(Executive_Account_Plan__c eap : executiveAccountPlans){
            final Integer countCustomerAccounts = countOfCustomerAccountsMap.containsKey(eap.Id) 
                                                  ? (Integer)countOfCustomerAccountsMap.get(eap.Id).get('customerAccounts')
                                                  : 0;
            if(countCustomerAccounts != eap.Number_of_Customer_Accounts__c){
                addEAPToUpdate(eap.Id, executiveAccountPlanUpdateMap).Number_of_Customer_Accounts__c = countCustomerAccounts;  
            }
        }
    }   
    
    private void relatedOpportunities(List<Executive_Account_Plan__c> executiveAccountPlans, Map<Id, Executive_Account_Plan__c> executiveAccountPlanUpdateMap) {
        final Map<Id, Decimal> sumOfClosedWonOppsMap = new Map<Id, Decimal>();
        final Map<Id, Integer> totalClosedWonOppsMap = new Map<Id, Integer>();
        final Map<Id, Integer> totalOppsMap = new Map<Id, Integer>();
        final Map<Id, Decimal> sumOfOpenOppsMap = new Map<Id, Decimal>();
        
        for(Opportunity opportunity : [
            SELECT Id, Opportunity_Delta_MRR__c , Executive_Account_Plan__c, StageName, IsClosed
            FROM Opportunity
            WHERE RecordType.Name != 'Renewal'
            AND Executive_Account_Plan__c IN: new Map<Id, Executive_Account_Plan__c>(executiveAccountPlans).keySet()
        ]){
            if(opportunity.StageName == 'Closed Won'){
                addCountEAPMap(totalClosedWonOppsMap, opportunity.Executive_Account_Plan__c);
                addSumEAPMap(sumOfClosedWonOppsMap, opportunity.Executive_Account_Plan__c, opportunity.Opportunity_Delta_MRR__c);
            }
            addCountEAPMap(totalOppsMap, opportunity.Executive_Account_Plan__c);
            
            if(opportunity.IsClosed == false){
                addSumEAPMap(sumOfOpenOppsMap, opportunity.Executive_Account_Plan__c, opportunity.Opportunity_Delta_MRR__c);
            }
        }
        for(Executive_Account_Plan__c executiveAccountPlan : executiveAccountPlans){
            if(sumOfClosedWonOppsMap.containsKey(executiveAccountPlan.Id) && executiveAccountPlan.Sum_of_Closed_Opportunity_MRR__c != sumOfClosedWonOppsMap.get(executiveAccountPlan.Id)){
                addEAPToUpdate(executiveAccountPlan.Id, executiveAccountPlanUpdateMap).Sum_of_Closed_Opportunity_MRR__c = sumOfClosedWonOppsMap.get(executiveAccountPlan.Id);
            }
            if(totalClosedWonOppsMap.containsKey(executiveAccountPlan.Id) && executiveAccountPlan.Total_Closed_Sales_Opportunities__c != totalClosedWonOppsMap.get(executiveAccountPlan.Id)){
                addEAPToUpdate(executiveAccountPlan.Id, executiveAccountPlanUpdateMap).Total_Closed_Sales_Opportunities__c = totalClosedWonOppsMap.get(executiveAccountPlan.Id);
            }
            if(totalOppsMap.containsKey(executiveAccountPlan.Id) && executiveAccountPlan.Total_Sales_Opportunties__c != totalOppsMap.get(executiveAccountPlan.Id)){
                addEAPToUpdate(executiveAccountPlan.Id, executiveAccountPlanUpdateMap).Total_Sales_Opportunties__c = totalOppsMap.get(executiveAccountPlan.Id);
            }
            if(sumOfOpenOppsMap.containsKey(executiveAccountPlan.Id) && executiveAccountPlan.Sum_of_Open_Opportunity_MRR__c != sumOfOpenOppsMap.get(executiveAccountPlan.Id)){
                addEAPToUpdate(executiveAccountPlan.Id, executiveAccountPlanUpdateMap).Sum_of_Open_Opportunity_MRR__c = sumOfOpenOppsMap.get(executiveAccountPlan.Id);
            }
        }
    }
    
    private Executive_Account_Plan__c addEAPToUpdate(final Id eapId, final Map<Id, Executive_Account_Plan__c> executiveAccountPlanUpdateMap) {
        if(!executiveAccountPlanUpdateMap.containsKey(eapId)) {
            executiveAccountPlanUpdateMap.put(eapId, new Executive_Account_Plan__c(Id = eapId));
        }
        return executiveAccountPlanUpdateMap.get(eapId);
    }
    
    private Map<Id, Integer> addCountEAPMap(final Map<Id, Integer> accountPlanRelationshipMap, final Id eapId) {
        if(!accountPlanRelationshipMap.containsKey(eapId)){
            accountPlanRelationshipMap.put(eapId,0);
        }
        accountPlanRelationshipMap.put(eapId, accountPlanRelationshipMap.get(eapId) + 1);
        
        return accountPlanRelationshipMap;
    }
    
    private Map<Id, Decimal> addSumEAPMap(final Map<Id, Decimal> sumOfOppsMap, final Id eapId, final Decimal deltaMRR) {
        if(!sumOfOppsMap.containsKey(eapId)){
            sumOfOppsMap.put(eapId, 0.00);
        }
        sumOfOppsMap.put(eapId, sumOfOppsMap.get(eapId) + deltaMRR);
        
        return sumOfOppsMap;
    }
    
    public void finish(final Database.BatchableContext context) {
    }   
}
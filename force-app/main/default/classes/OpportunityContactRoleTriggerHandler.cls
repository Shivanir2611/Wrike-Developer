public class OpportunityContactRoleTriggerHandler {
    
    public static OpportunityContactRoleTriggerHandler getInstance() {
        return (OpportunityContactRoleTriggerHandler)ServiceLocator.getInstance(OpportunityContactRoleTriggerHandler.class);
    }
    
    public void afterInsert(final List<OpportunityContactRole> opportunityContactRoleList) {
        final Map<Id, List<Id>> opportunityContactRoleMap = new Map<Id, List<Id>>();
        final Set<Id> contactIds = new Set<Id>();
        for(OpportunityContactRole oppContactRole : opportunityContactRoleList){
            contactIds.add(oppContactRole.ContactId);
            if(!opportunityContactRoleMap.containsKey(oppContactRole.OpportunityId)){
                opportunityContactRoleMap.put(oppContactRole.OpportunityId, new List<Id>());
            }
            opportunityContactRoleMap.get(oppContactRole.OpportunityId).add(oppContactRole.ContactId);
        }
        final Map<Id, List<Task>> contactToTaskMap = new Map<Id, List<Task>>();
        for(Task task : [
            SELECT Id, WhoId, CreatedDate
            FROM Task 
            WHERE WhoId IN : contactIds 
            AND WhatId = NULL
            AND Type = 'Email'
        ]){
            if(!contactToTaskMap.containsKey(task.WhoId)){
                contactToTaskMap.put(task.WhoId, new List<Task>());
            }
            contactToTaskMap.get(task.WhoId).add(task);
        }
        final Map<Id, Task> processedTaskMap = new Map<Id, Task>();
        for(Opportunity newOpportunity : [
            SELECT Id, CreatedDate
            FROM Opportunity
            WHERE Id IN : opportunityContactRoleMap.keySet() 
            AND isClosed = false
            AND Opportunity.RecordType.DeveloperName IN : RecordTypeQueryService.OpportunityRecordTypes
            ORDER BY CreatedDate DESC
        ]){
            if(!opportunityContactRoleMap.get(newOpportunity.Id).isEmpty()){
            	for(Id contactId : opportunityContactRoleMap.get(newOpportunity.Id)){
                    if(!contactToTaskMap.isEmpty()){
                        for(Task task :  contactToTaskMap.get(contactId)){
                            if(!processedTaskMap.containsKey(task.Id) && newOpportunity.CreatedDate <= task.CreatedDate){
                                task.WhatId =  newOpportunity.Id;
                                processedTaskMap.put(task.Id, task);   
                            }
                        } 
                    }
                }
            }
        }
        if(!processedTaskMap.isEmpty()){
            update processedTaskMap.values();
        }
    }
}
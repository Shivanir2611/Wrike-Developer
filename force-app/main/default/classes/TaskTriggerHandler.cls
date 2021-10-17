public class TaskTriggerHandler {
    
    public static TaskTriggerHandler getInstance() {
        return (TaskTriggerHandler)ServiceLocator.getInstance(TaskTriggerHandler.class);
    }
    
    public void beforeInsert(final List<Task> taskList){
        final List<Task> updateTaskList = new List<Task>();
        for(Task task : taskList){
            if(isContactEmailTaskCheck(task)){
                updateTaskList.add(task);    
            }
        }
        if(!updateTaskList.isEmpty()){
            opportunityTaskUpdate(updateTaskList);    
        }
    }
    
    public void beforeUpdate(final Map<Id, Task> oldMap, final Map<Id, Task> newMap){
        final List<Task> updateTaskList = new List<Task>();
        for(Task newTask : newMap.values()){
            final Task oldTask = oldMap.get(newTask.Id);
            if(isContactEmailTaskCheck(newTask) && oldTask.WhoId != newTask.WhoId){
                updateTaskList.add(newTask);    
            }
        }
        if(!updateTaskList.isEmpty()){
            opportunityTaskUpdate(updateTaskList);
        }
    }
    
    public void afterInsert(final Map<Id, Task> newMap) {
        final Map<Id, Id> tasksIdToLeadId = new Map<Id, Id>();
        final Map<Id, Id> tasksIdToContactId = new Map<Id, Id>();
        final List<Activity__c> activities = new List<Activity__c>();
        for(Task task : newMap.values()) {
            if (task.WhoId != null && String.valueOf(task.WhoId).startsWith('00Q')) {
                tasksIdToLeadId.put(task.Id, task.WhoId);
            } else if (task.WhoId != null && String.valueOf(task.WhoId).startsWith('003')) {
                tasksIdToContactId.put(task.Id, task.WhoId);
            }    
        }
        ActivityService activitySrv = ActivityService.getInstance();
        if (!tasksIdToLeadId.isEmpty()) {
            final List<Lead> leads = LeadQueryService.getInstance().listByIdsWithActivityData(tasksIdToLeadId.values());
            final Map<String, String> leadIdToActivityData = SobjectUtils.createMapBetweenTwoField(leads, 'Id', 'Activity_Data__c');
            for (Id taskId : tasksIdToLeadId.keySet()) {
                final Task task = newMap.get(taskId);
                final String activityDataId = leadIdToActivityData.get(task.WhoId);
                Activity__c activity = activitySrv.createActivity(task, activityDataId);
                if (activity != null) {
                    activities.add(activity);
                }
            }
        }
        if (!tasksIdToContactId.isEmpty()) {
            final List<Contact> contacts = ContactQueryService.getInstance().listByIdsWithActivityData(tasksIdToContactId.values());
            final Map<String, String> contactIdToActivityData = SobjectUtils.createMapBetweenTwoField(contacts, 'Id', 'Activity_Data__c');
            for (Id taskId : tasksIdToContactId.keySet()) {
                final Task task = newMap.get(taskId);
                final String activityDataId = contactIdToActivityData.get(task.WhoId);
                Activity__c activity = activitySrv.createActivity(task, activityDataId);
                if (activity != null) {
                    activities.add(activity);
                }
            }
        }
        if (!activities.isEmpty()) {
            insert activities;
        }
    }
    
    public void afterUpdate(final Map<Id, Task> oldMap, final Map<Id, Task> newMap) {
        final Map<Id, Event__c> completedEvents = new Map<Id, Event__c>();
        for(Task task : newMap.values()) {
            if (task.Event__c != null && task.Status == 'Completed' && oldMap.get(task.Id).Status == 'Open') {
                completedEvents.put(task.Event__c, new Event__c(
                    Id = task.Event__c,
                    Status__c = 'Completed'
                ));
            }
        }
        if (!completedEvents.isEmpty()) {
            update completedEvents.values();
        }
    }
    
    public void opportunityTaskUpdate(final List<Task> taskList){
        final Set<Id> contactIds = new Set<Id>();
        for(Task task :  taskList){
            if(isContactEmailTaskCheck(task)){
                contactIds.add(task.WhoId);
            }
        }
        final Map<Id,OpportunityContactRole> contactOppMap = new Map<Id,OpportunityContactRole>();
        for(OpportunityContactRole oppContactRole: [
            SELECT Id, ContactId, OpportunityId, Opportunity.CreatedDate
            FROM OpportunityContactRole
            WHERE ContactId IN : contactIds 
            AND Opportunity.isClosed = false 
            AND Opportunity.RecordType.DeveloperName IN : RecordTypeQueryService.OpportunityRecordTypes 
            ORDER BY Opportunity.CreatedDate DESC
        ]){
            if(!contactOppMap.containsKey(oppContactRole.ContactId)){
                contactOppMap.put(oppContactRole.ContactId,oppContactRole);
            }
        }
        for(Task task : taskList){
            if(isContactEmailTaskCheck(task)){
                final OpportunityContactRole oppContactRoleRecord = contactOppMap.get(task.WhoId);
                if(oppContactRoleRecord != null){
                    if(oppContactRoleRecord.Opportunity.CreatedDate <= task.CreatedDate || task.CreatedDate == null){
                        task.WhatId = oppContactRoleRecord.OpportunityId;
                    }
                }
            }
        }
    }

    private Boolean isContactEmailTaskCheck(final Task task){
        return (task.WhoId != null && task.WhoId.getSobjectType() == Schema.Contact.SObjectType && task.WhatId == null && task.Type == 'Email');
    }
}
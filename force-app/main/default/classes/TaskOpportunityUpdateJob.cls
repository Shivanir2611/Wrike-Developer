public class TaskOpportunityUpdateJob implements Database.Batchable<SObject> {
 
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, WhoId, WhatId, CreatedDate, Type
            FROM Task
            WHERE WhoId != NULL
            AND WhatId = NULL
            AND Type = 'Email'
            AND Who.Type = 'Contact'
        ]);
    }
   	
    public void execute(final Database.BatchableContext context, final List<Task> taskList) {
        TaskTriggerHandler.getInstance().opportunityTaskUpdate(taskList);
        update taskList;
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}
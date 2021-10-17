public class TaskCleanUpJob implements Database.Batchable<SObject>, Schedulable {
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Task
            WHERE IsDeleted = false
            AND CreatedDate < LAST_N_YEARS: 2
        ]);
    }
   	
    public void execute(final Database.BatchableContext context, final List<Task> taskList) {
        if(!taskList.isEmpty()){
            delete taskList;
    	}
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}
public class UserDataCleanUpJob implements Database.Batchable<SObject>, Schedulable {
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM UserData__c
            WHERE IsDeleted = false
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<UserData__c> userDataList) {
        delete userDataList;
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}
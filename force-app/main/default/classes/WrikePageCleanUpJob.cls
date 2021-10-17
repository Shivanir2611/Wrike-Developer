public class WrikePageCleanUpJob implements Database.Batchable<SObject>, Schedulable {
    
    public void execute(final SchedulableContext sc){
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context){
        return Database.getQueryLocator([
            SELECT Id
            FROM Wrike_Page__c
            WHERE IsDeleted = false
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<Wrike_Page__c> wrikePageList){
        if(!wrikePageList.isEmpty()){
            delete wrikePageList;
        }
    }
    
    public void finish(final Database.BatchableContext context){
    }
}
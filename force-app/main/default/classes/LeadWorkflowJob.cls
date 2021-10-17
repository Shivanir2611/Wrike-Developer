public class LeadWorkflowJob implements Database.Batchable<SObject>, Schedulable {

    public void execute(final SchedulableContext context) {
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Lead
            WHERE IsConverted = false 
              AND OwnerId != :WrikeConstants.RLQ_ID
            ORDER BY CreatedDate DESC
        ]);
    }
   
    public void execute(final Database.BatchableContext context, final List<Lead> leads) {
        final DateTime now = DateTime.now();
        for(Lead lead : leads) {
            lead.Last_Evaluated_Date__c = now;
        }
        update leads;
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}
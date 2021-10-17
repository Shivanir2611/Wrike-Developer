public class LeadRecycleJob implements Database.Batchable<SObject>, Schedulable {
    
    private Integer batchSize;
    
    public LeadRecycleJob() {
        this.batchSize = 100;
    }
    
    public LeadRecycleJob(final Integer batchSize) {
        this.batchSize = batchSize;
    }
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this, batchSize);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Lead
            WHERE IsLeadReassignment__c = true
            AND IsConverted = false
            AND LastModifiedDate = LAST_N_DAYS:7
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Lead> leads) {
        for(Lead lead : leads) {
            lead.OwnerId = WrikeConstants.RLQ_ID;
        }
        update leads;
    }
    
    public void finish(Database.BatchableContext context) {
    }
}
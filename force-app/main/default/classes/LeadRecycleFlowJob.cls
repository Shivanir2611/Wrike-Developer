public class LeadRecycleFlowJob implements Database.Batchable<SObject>, Schedulable {
    
    private Integer batchSize;
    
    public LeadRecycleFlowJob() {
        this.batchSize = 20;
    }
    
    public LeadRecycleFlowJob(final Integer batchSize) {
        this.batchSize = batchSize;
    }
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this, batchSize);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Lead
            WHERE IsConverted = false
            AND Owner.Type = 'User'
            AND IsLeadRecycleRun__c = true
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Lead> leadList) {
        Flow.Interview.Recycle_Requalify_Flow leadRecycleFlow = new Flow.Interview.Recycle_Requalify_Flow(new Map<String, Object> { 'Leads' =>  leadList});
        leadRecycleFlow.start();
    }
    
    public void finish(Database.BatchableContext context) {
    }
}
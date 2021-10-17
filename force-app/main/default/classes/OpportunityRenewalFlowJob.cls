public class OpportunityRenewalFlowJob implements Database.Batchable<SObject>, Schedulable {
    
    private Integer batchSize;
    
    public OpportunityRenewalFlowJob() {
        this.batchSize = 5;
    }
    
    public OpportunityRenewalFlowJob(final Integer batchSize) {
        this.batchSize = batchSize;
    }
    
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this, batchSize);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Opportunity
            WHERE IsOpportunityRenewalRun__c = true
            AND Type = 'Renewal'
            AND OwnerId = : WrikeConstants.SF_ADMIN_ID
        ]);
    }
    
    public void execute(Database.BatchableContext context, List<Opportunity> opportunities) {
        Flow.Interview.Partner_Manager_Assignment partnerAssignmentFlow = new Flow.Interview.Partner_Manager_Assignment(new Map<String, Object> { 'Opportunities' =>  opportunities});
        partnerAssignmentFlow.start();
    }
    
    public void finish(Database.BatchableContext context) {
    }
}
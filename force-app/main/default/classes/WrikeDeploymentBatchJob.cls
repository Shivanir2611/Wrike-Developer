public class WrikeDeploymentBatchJob implements Database.Batchable<SObject>, Schedulable {
    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Account__c, Subscription__c, OwnerId 
            FROM Deployment__c 
            WHERE Owner.ProfileId='00e1Y000001JSsOQAW'
            AND Owner.IsActive = true
        ]);
    }
    
    public void execute(final Database.BatchableContext context, final List<Deployment__c> deployments) {
    	WrikeDeploymentShareLogic.checkShareRecordAccess(deployments);
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}
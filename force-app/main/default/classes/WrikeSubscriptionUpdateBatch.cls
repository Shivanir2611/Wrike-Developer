public class WrikeSubscriptionUpdateBatch implements Database.Batchable<SObject>, Schedulable {

    private final DeploymentQueryService deploymentQuerySrv = DeploymentQueryService.getInstance();
    private final DatabaseService databaseSrv = DatabaseService.getInstance();

    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Wrike_Account_Id__c, LastDeployment__c
            FROM Subscription__c
            WHERE Status__c = 'Active'
            ORDER BY CreatedDate ASC
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Subscription__c> subscriptions) {
        final List<Decimal> subscriptionWrikeAccountIds = new List<Decimal>();
        for (Subscription__c subscription : subscriptions) {
            subscriptionWrikeAccountIds.add(subscription.Wrike_Account_Id__c);
        }
        final List<Deployment__c> deployments = deploymentQuerySrv.listByWrikeAccountIds(subscriptionWrikeAccountIds);

        final Map<Integer, Deployment__c> wrikeAccountIdToLastDeployment = new Map<Integer, Deployment__c>();
        for (Deployment__c deployment : deployments) {
            wrikeAccountIdToLastDeployment.put(Integer.valueOf(deployment.Wrike_Account_ID__c), deployment);
        }
        final List<Subscription__c> subsToUpdate = new List<Subscription__c>();
        final Map<Id, Id> deploymentToSubIdMap = new Map<Id, Id>();
        for (Subscription__c subscription : subscriptions) {
            final Deployment__c lastDeployment = wrikeAccountIdToLastDeployment.get(Integer.valueOf(subscription.Wrike_Account_Id__c));
            if (lastDeployment != null && subscription.LastDeployment__c != lastDeployment.Id) {
                subscription.LastDeployment__c = lastDeployment.Id;
                subsToUpdate.add(subscription);
                deploymentToSubIdMap.put(lastDeployment.Id, subscription.Id);
            }
        }
        databaseSrv.updateSObject(subsToUpdate);
        if(!deploymentToSubIdMap.isEmpty()) {
            final List<Deployment__c> lastDeployments = deploymentQuerySrv.listByIds(new List<Id> (deploymentToSubIdMap.keySet()));
            final List<Deployment__c> deploymentsToUpdate = new List<Deployment__c>();
            for(Deployment__c deployment : lastDeployments) {
                final Id subscriptionId = deploymentToSubIdMap.get(deployment.Id);
                if(deployment.Subscription__c != subscriptionId) {
                    deployment.Subscription__c = subscriptionId;
                    deploymentsToUpdate.add(deployment);
                }
            }
            databaseSrv.updateSObject(deploymentsToUpdate);
        }
    }

    public void finish(final Database.BatchableContext context) {

    }
}
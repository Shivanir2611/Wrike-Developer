public class SubscriptionWorkflowJob implements Database.Batchable<SObject>, Schedulable {

    private Integer scope;

    public SubscriptionWorkflowJob() {
        this.scope = 200;
    }

    public SubscriptionWorkflowJob(final Integer scope) {
        this.scope = scope;
    }

    public void execute(final SchedulableContext context) {
        Database.executeBatch(this, scope);
    }

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Subscription__c
            ORDER BY CreatedDate DESC
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Subscription__c> subscriptions) {
        final DateTime now = DateTime.now();
        for (Subscription__c subscription : subscriptions) {
            subscription.Last_Evaluated_Date__c = now;
        }
        update subscriptions;
    }

    public void finish(final Database.BatchableContext context) {
    }
}
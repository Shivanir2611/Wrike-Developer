public class AccountWorkflowJob implements Database.Batchable<SObject>, Schedulable {

    private Integer scope;

    public AccountWorkflowJob() {
        this.scope = 1000;
    }

    public AccountWorkflowJob(final Integer scope) {
        this.scope = scope;
    }

    public void execute(final SchedulableContext context) {
        Database.executeBatch(this, scope);
    }

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Account
            ORDER BY CreatedDate DESC
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Account> accounts) {
        final DateTime now = DateTime.now();
        for (Account account : accounts) {
            account.Last_Evaluated_Date__c = now;
        }
        update accounts;
    }

    public void finish(final Database.BatchableContext context) {}
}
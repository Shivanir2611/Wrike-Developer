/*
 * Created by andrey.kuleshov on 13/05/2019.
 */
public class DeleteOldActivityJob implements Database.Batchable<SObject>, Schedulable {

	public void execute(final SchedulableContext context) {
		Database.executeBatch(this);
	}

	public void execute(final Database.BatchableContext context, final List<Activity__c> activities) {
		delete activities;
	}

	public Database.QueryLocator start(final Database.BatchableContext context) {
		return Database.getQueryLocator([
			SELECT Id
			FROM Activity__c
			WHERE CreatedDate < LAST_N_DAYS:30
			ORDER BY Activity_Data__c
		]);
	}

	public void finish(final Database.BatchableContext context) {
	}
}
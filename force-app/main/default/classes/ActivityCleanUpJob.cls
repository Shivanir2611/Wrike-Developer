public class ActivityCleanUpJob implements Database.Batchable<SObject>, Schedulable {

	public void execute(final SchedulableContext sc) {
		Database.executeBatch(this);
	}

	public Database.QueryLocator start(final Database.BatchableContext context) {
		return Database.getQueryLocator([
			SELECT Id
			FROM Activity_Data__c
			WHERE Id NOT IN (
				SELECT Activity_Data__c
				FROM Lead
				WHERE Activity_Data__c != null
				AND OwnerId != :WrikeConstants.RLQ_ID
				AND IsConverted = false
			)
			AND Id NOT IN (
				SELECT Activity_Data__c
				FROM Contact
				WHERE Activity_Data__c != null
			)
		]);
	}

	public void execute(final Database.BatchableContext context, final List<Activity_Data__c> activityDataList) {
		delete activityDataList;
	}

	public void finish(final Database.BatchableContext context) {
	}
}
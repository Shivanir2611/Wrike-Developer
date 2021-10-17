public class EmailDataCleanUpJob implements Database.Batchable<SObject>, Schedulable {

	public void execute(final SchedulableContext sc) {
		Database.executeBatch(this);
	}

	public Database.QueryLocator start(final Database.BatchableContext context) {
		return Database.getQueryLocator([
				SELECT Id
				FROM EmailData__c
				WHERE Id NOT IN (SELECT EmailData__c FROM Lead WHERE EmailData__c != null)
				AND Id NOT IN (SELECT EmailData__c FROM Contact WHERE EmailData__c != null)
				AND LastModifiedDate < LAST_N_DAYS:30
		]);
	}

	public void execute(final Database.BatchableContext context, final List<EmailData__c> emailDataList) {
		delete emailDataList;
	}

	public void finish(final Database.BatchableContext context) {
	}
}
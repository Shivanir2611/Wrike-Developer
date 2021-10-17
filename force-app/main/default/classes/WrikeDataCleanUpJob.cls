public class WrikeDataCleanUpJob implements Database.Batchable<SObject>, Schedulable {

	private Integer scope;

	public WrikeDataCleanUpJob() {
		this.scope = 200;
	}

	public WrikeDataCleanUpJob(final Integer scope) {
		this.scope = scope;
	}

	public void execute(final SchedulableContext sc) {
		Database.executeBatch(this, scope);
	}

	public Database.QueryLocator start(final Database.BatchableContext context) {
		return Database.getQueryLocator([
			SELECT Id
			FROM WrikeData__c
			WHERE Id NOT IN (
				SELECT Wrike_Data__c
				FROM Lead
				WHERE Wrike_Data__c != null
				  AND OwnerId != :WrikeConstants.RLQ_ID
				  AND IsConverted = false
			)
			  AND Id NOT IN (
				SELECT Wrike_Data__c
				FROM Subscription__c
				WHERE Wrike_Data__c != null
			)
			  AND LastModifiedDate < LAST_N_DAYS:60
		]);
	}

	public void execute(final Database.BatchableContext context, final List<WrikeData__c> wrikeDataList) {
		delete [
			SELECT Id
			FROM WrikeData__c
			WHERE Id IN :wrikeDataList
			  AND Id NOT IN (
				SELECT Wrike_Data__c
				FROM Opportunity
				WHERE Wrike_Data__c != null
				  AND Wrike_Data__c IN :wrikeDataList
			)
		];
	}

	public void finish(final Database.BatchableContext context) {
	}
}
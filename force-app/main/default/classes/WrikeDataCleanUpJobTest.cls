@IsTest
public class WrikeDataCleanUpJobTest {

	@IsTest
	static void testNewWrikeDataNotDeleted() {

		final WrikeData__c wrikeData = TestDataFactory.createWrikeData(123, false);
		insert wrikeData;

		Test.startTest();
		Database.executeBatch(new WrikeDataCleanUpJob());
		Test.stopTest();

		final WrikeData__c remainedWrikeData = [
				SELECT Id
				FROM WrikeData__c
				WHERE Id = :wrikeData.Id
		];

		System.assertNotEquals(null, remainedWrikeData);
	}

	@IsTest
	static void testOpportunityWrikeDataNotDeleted() {

		final WrikeData__c wrikeData = TestDataFactory.createWrikeData(123, false);
		insert wrikeData;

		final Account account = TestDataFactory.createAccount();
		insert account;

		final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
		opportunity.Wrike_Data__c = wrikeData.Id;
		insert opportunity;

		new WrikeDataCleanUpJob().execute(null, new List<WrikeData__c>{wrikeData});

		final WrikeData__c remainedWrikeData = [
				SELECT Id
				FROM WrikeData__c
				WHERE Id = :wrikeData.Id
		];

		System.assertNotEquals(null, remainedWrikeData);
	}

	@IsTest
	static void testOpportunityWrikeDataDeleted() {

		final WrikeData__c wrikeData = TestDataFactory.createWrikeData(123, false);
		insert wrikeData;

		new WrikeDataCleanUpJob().execute(null, new List<WrikeData__c>{wrikeData});

		final List<WrikeData__c> deletedWrikeData = [
				SELECT Id
				FROM WrikeData__c
				WHERE Id = :wrikeData.Id
		];

		System.assert(deletedWrikeData.isEmpty());
	}

}
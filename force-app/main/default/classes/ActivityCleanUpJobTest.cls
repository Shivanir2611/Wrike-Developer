@IsTest
public class ActivityCleanUpJobTest {

	@IsTest
	static void testRecycledLeadsActivitiesDeleted() {

		final Lead lead = TestDataFactory.createLead(WrikeConstants.RLQ_ID);
		insert lead;

		final Id activityDataId = getLeadActivityDataId(lead.Id);
		final Id activityId = createAndInsertActivity(activityDataId);

		Test.startTest();
		Database.executeBatch(new ActivityCleanUpJob());
		Test.stopTest();

		System.assertEquals(null, findActivityDataById(activityDataId));
		System.assertEquals(null, findActivityById(activityId));
	}

	@IsTest
	static void testContactsActivitiesNotDeleted() {

		final Lead lead = TestDataFactory.createLead(WrikeConstants.RLQ_ID);
		insert lead;

		final Id activityDataId = getLeadActivityDataId(lead.Id);
		final Id activityId = createAndInsertActivity(activityDataId);

		final Contact contact = TestDataFactory.createContact();
		contact.Activity_Data__c = activityDataId;
		insert contact;

		Test.startTest();
		Database.executeBatch(new ActivityCleanUpJob());
		Test.stopTest();

		System.assertNotEquals(null, findActivityDataById(activityDataId));
		System.assertNotEquals(null, findActivityById(activityId));
	}

	@IsTest
	static void testOpenLeadsActivitiesNotDeleted() {

		final Lead lead = TestDataFactory.createLead(WrikeConstants.GLQ_ID);
		insert lead;

		final Id activityDataId = getLeadActivityDataId(lead.Id);
		final Id activityId = createAndInsertActivity(activityDataId);

		Test.startTest();
		Database.executeBatch(new ActivityCleanUpJob());
		Test.stopTest();

		System.assertNotEquals(null, findActivityDataById(activityDataId));
		System.assertNotEquals(null, findActivityById(activityId));
	}

	@IsTest
	static void testConvertedLeadsActivitiesDeleted() {

		final Lead lead = TestDataFactory.createLead();
		insert lead;
		convertLead(lead.Id);

		lead.OwnerId = WrikeConstants.GLQ_ID;
		update lead;

		final Id activityDataId = getLeadActivityDataId(lead.Id);
		final Id activityId = createAndInsertActivity(activityDataId);

		Test.startTest();
		Database.executeBatch(new ActivityCleanUpJob());
		Test.stopTest();

		System.assertEquals(null, findActivityDataById(activityDataId));
		System.assertEquals(null, findActivityById(activityId));
	}

	private static Id getLeadActivityDataId(final Id leadId) {
		final Lead lead = [
				SELECT Id, Activity_Data__c
				FROM Lead
				WHERE Id = :leadId
		];

		return lead.Activity_Data__c;
	}

	private static Id createAndInsertActivity(final Id activityDataId) {
		final Activity__c activity = new Activity__c();
		activity.Activity_Data__c = activityDataId;
		insert activity;

		return activity.Id;
	}

	private static Activity_Data__c findActivityDataById(final Id activityDataId) {
		final List<Activity_Data__c> activityDataList = [
				SELECT Id
				FROM Activity_Data__c
				WHERE Id = :activityDataId
		];

		return activityDataList.isEmpty() ? null : activityDataList.get(0);
	}

	private static Activity__c findActivityById(final Id activityId) {
		final List<Activity__c> activityList = [
				SELECT Id
				FROM Activity__c
				WHERE Id = :activityId
		];

		return activityList.isEmpty() ? null : activityList.get(0);
	}

	private static String findConvertedStatus() {
		final LeadStatus convertStatus = [
				SELECT Id, MasterLabel
				FROM LeadStatus
				WHERE IsConverted = true
				LIMIT 1
		];
		return convertStatus.MasterLabel;
	}

	private static void convertLead(Id leadId) {
		final Database.LeadConvert leadConvert = new Database.LeadConvert();
		leadConvert.setConvertedStatus(findConvertedStatus());
		leadConvert.setDoNotCreateOpportunity(false);
		leadConvert.setLeadId(leadId);
		Database.convertLead(leadConvert);
	}
}
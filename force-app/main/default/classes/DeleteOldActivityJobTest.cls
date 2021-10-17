/*
 * Created by andrey.kuleshov on 13/05/2019.
 */
@IsTest
public class DeleteOldActivityJobTest {

	@IsTest
	static void testRecentActivityNotDeleted() {
		final Lead lead = TestDataFactory.createLead();
		insert lead;
		final Lead createdLead = [
			SELECT Activity_Data__c
			FROM Lead
			WHERE Id = :lead.Id
		];
		final Activity__c activity = new Activity__c(
			Activity_Data__c = createdLead.Activity_Data__c,
			Type__c = 'Email',
			Sub_Type__c = 'Outbound',
			Subject__c = 'Test Email'
		);
		insert activity;

		Test.startTest();
		Database.executeBatch(new DeleteOldActivityJob());
		Test.stopTest();
		System.assertEquals(1, TestUtils.findActivityForLead(lead.Id).size());
	}

	@IsTest
	static void testOldActivityDeleted() {
		final Lead lead = TestDataFactory.createLead();
		insert lead;
		final Lead createdLead = [
			SELECT Activity_Data__c
			FROM Lead
			WHERE Id = :lead.Id
		];
		final Activity__c activity = new Activity__c(
			Activity_Data__c = createdLead.Activity_Data__c,
			Type__c = 'Email',
			Sub_Type__c = 'Outbound',
			Subject__c = 'Test Email'
		);
		insert activity;
		Test.setCreatedDate(activity.Id, DateTime.now().addDays(-31));

		Test.startTest();
		Database.executeBatch(new DeleteOldActivityJob());
		Test.stopTest();
		System.assertEquals(true, TestUtils.findActivityForLead(lead.Id).isEmpty());
	}
}
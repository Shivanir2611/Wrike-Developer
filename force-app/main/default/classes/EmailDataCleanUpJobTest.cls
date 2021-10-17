@IsTest
public class EmailDataCleanUpJobTest {

	@IsTest
	static void testRemainEmailData() {

		final EmailData__c emailData = new EmailData__c();
		emailData.Email__c = 'a@a.com';
		insert emailData;

		Test.startTest();
		Database.executeBatch(new EmailDataCleanUpJob());
		Test.stopTest();

		final EmailData__c remainedEmailData = [
				SELECT Id
				FROM EmailData__c
				WHERE Id = :emailData.Id
		];

		System.assertNotEquals(null, remainedEmailData);
	}
}
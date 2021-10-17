/*
 * Created by andrey.kuleshov on 11/06/2019.
 */
@IsTest
public class SubscriptionContactTriggerHandlerTest {

	@IsTest
	static void testWrikeOwnerPopulated() {
		final Account account = TestDataFactory.createAccount();
		insert account;
		final Contact firstContact = TestDataFactory.createContact(account.Id, 'Contact1', 'contact1@address.com');
		final Contact secondContact = TestDataFactory.createContact(account.Id, 'Contact2', 'contact2@address.com');
		insert firstContact;
		insert secondContact;
		final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, null, 'Active', 123, 99.0);
		insert subscription;
		final SubscriptionContact__c firstSubscriptionContact = new SubscriptionContact__c(
			Contact__c = firstContact.Id,
			Subscription__c = subscription.Id,
			WrikeUserRole__c = 'User',
			WrikeUserType__c = 'Owner'
		);
		insert firstSubscriptionContact;
		System.assertEquals(firstContact.Id, findWrikeOwner(subscription.Id));
		insert new SubscriptionContact__c(
			Contact__c = secondContact.Id,
			Subscription__c = subscription.Id,
			WrikeUserRole__c = 'User',
			WrikeUserType__c = 'Owner'
		);
		update new SubscriptionContact__c(
			Id = firstSubscriptionContact.Id,
			WrikeUserType__c = 'Admin'
		);
		System.assertEquals(secondContact.Id, findWrikeOwner(subscription.Id));
	}

	@IsTest
	static void testAdminNotificationForNewContact() {
		final Account account = TestDataFactory.createAccount();
		insert account;
		final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'newadmin@address.com');
		insert contact;
		final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, null, 'Active', 123, 99.0);
		insert subscription;
		insert new SubscriptionContact__c(
			Contact__c = contact.Id,
			Subscription__c = subscription.Id,
			WrikeUserRole__c = 'User',
			WrikeUserType__c = 'Admin'
		);
		System.assertEquals(true, isAdminNotificationCreated(contact.Id));
	}

	@IsTest
	static void testAdminNotificationForUpdatedContact() {
		final Account account = TestDataFactory.createAccount();
		insert account;
		final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'newadmin@address.com');
		insert contact;
		final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, null, 'Active', 123, 99.0);
		insert subscription;
		final SubscriptionContact__c subscriptionContact = new SubscriptionContact__c(
			Contact__c = contact.Id,
			Subscription__c = subscription.Id,
			WrikeUserRole__c = 'User',
			WrikeUserType__c = 'Regular'
		);
		insert subscriptionContact;
		System.assertEquals(false, isAdminNotificationCreated(contact.Id));
		subscriptionContact.WrikeUserType__c = 'Admin';
		update subscriptionContact;
		System.assertEquals(true, isAdminNotificationCreated(contact.Id));
	}

	@IsTest
	static void testNoAdminNotificationForT2TAccount() {
		final User accountOwner = TestUtils.createUser('testaee', 'testaee@team.wrike.com', 'System Administrator');
		accountOwner.Market_Segment__c = 'SAE';
		TestUtils.updateAndAssert(accountOwner);
		final Account account = TestDataFactory.createAccount();
		account.OwnerId = accountOwner.Id;
		insert account;
		final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'newadmin@address.com');
		insert contact;
		final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, null, 'Active', 123, 99.0);
		insert subscription;
		insert new SubscriptionContact__c(
				Contact__c = contact.Id,
				Subscription__c = subscription.Id,
				WrikeUserRole__c = 'User',
				WrikeUserType__c = 'Admin'
		);
		System.assertEquals(false, isAdminNotificationCreated(contact.Id));
	}

	private static Boolean isAdminNotificationCreated(final Id contactId) {
		final List<Task> tasks = [
			SELECT Id
			FROM Task
			WHERE WhoId = :contactId
			  AND Subject = 'Onboard New Admin'
		];
		return !tasks.isEmpty();
	}

	private static Id findWrikeOwner(final Id subscriptionId) {
		final Subscription__c subscription = [
				SELECT Wrike_Owner__c
				FROM Subscription__c
				WHERE Id = :subscriptionId
		];
		return subscription.Wrike_Owner__c;
	}
}
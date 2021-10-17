/**
 * @author Andrey Kuleshov
 */
@IsTest
public class ContactTriggerTest {

    private static final String MARKETO_USER_EMAIL = 'marketo@test.com';

    @TestSetup
    static void setup() {
        final User marketoUser = TestDataFactory.createUser(MARKETO_USER_EMAIL, 'Marketo', 'Test', 'System Administrator', false);
        insert marketoUser;
        insert new Settings__c(
                MarketoUserId__c = marketoUser.Id,
                TrialProcessingEnabled__c = true
        );
    }

    @IsTest
    static void testEmailDataPopulated() {
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(contact);
        final Contact createdContact = TestUtils.findContactById(contact.Id);
        final Id emailDataId = createdContact.EmailData__c;
        System.assertNotEquals(null, emailDataId);
        TestUtils.updateAndAssert(new Contact(
            Id = createdContact.Id,
            Email = 'testcontact2@address2.com'
        ));
        final Contact updatedContact = TestUtils.findContactById(createdContact.Id);
        System.assertNotEquals(emailDataId, updatedContact.EmailData__c);
        System.assertEquals(false, updatedContact.HasOptedOutOfEmail);
    }

    @IsTest
    static void testExistingEmailData() {
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final String email = 'testcontact@address.com';
        final EmailData__c emailData = new EmailData__c(
            Email__c = email
        );
        Database.upsert(emailData, Schema.EmailData__c.Email__c);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', email);
        TestUtils.insertAndAssert(contact);
        final Contact createdContact = TestUtils.findContactById(contact.Id);
        System.assertEquals(emailData.Id, createdContact.EmailData__c);
    }

    @IsTest
    static void testUpdateWithNotTrialRequest() {
        System.runAs(TestUtils.getUserByEmail(MARKETO_USER_EMAIL).get(0)) {
            final Contact contact = TestDataFactory.createContact();
            insert contact;
            contact.Last_request_type__c = 'Not Trial';
            contact.Last_request_subtype__c = 'Request';
            contact.Last_request_wrike_account_ID__c = 123;
            contact.Last_request_date__c = Datetime.now();
            update contact;

            final List<Request__c> requests = findRequests(contact.Id);
            System.assert(!requests.isEmpty());
            System.assert(requests.size() == 1);
            final Request__c request = requests.get(0);
            System.assertEquals('Not Trial - Request - ' + contact.FirstName + ' ' + contact.LastName, request.Name);
            System.assertEquals(contact.Last_request_type__c, request.Type__c);
            System.assertEquals(contact.Last_request_subtype__c, request.Subtype__c);
            System.assertEquals(contact.Last_request_wrike_account_ID__c, request.WrikeAccountId__c);
            System.assertEquals('Completed', request.Status__c);
        }
    }

    @IsTest
    static void testUpdateWithTrialRestartRequest() {
        System.runAs(TestUtils.getUserByEmail(MARKETO_USER_EMAIL).get(0)) {
            final Contact contact = TestDataFactory.createContact();
            contact.Last_Trial_Start_Date__c = Datetime.now().addDays(-10);
            insert contact;
            contact.Last_Trial_Start_Date__c = Datetime.now();
            contact.Last_Trial_Account_Id__c = 123;
            update contact;

            final List<Request__c> restartRequests = findRequests(contact.Id);
            System.assert(!restartRequests.isEmpty());
            System.assert(restartRequests.size() == 1);
            final Request__c restartRequest = restartRequests.get(0);
            System.assertEquals('Trial - Restart - ' + contact.FirstName + ' ' + contact.LastName, restartRequest.Name);
            System.assertEquals('Trial', restartRequest.Type__c);
            System.assertEquals('Restart', restartRequest.Subtype__c);
            System.assertEquals('Pending', restartRequest.Status__c);
            System.assertEquals(123, restartRequest.WrikeAccountId__c);
        }
    }

    @IsTest
    static void testUpdateWithTrialRestartRequestByNotMarketoUser() {
        System.runAs(TestUtils.getWrikeIntegrationUser()) {
            final Contact contact = TestDataFactory.createContact();
            contact.Last_Trial_Start_Date__c = Datetime.now().addDays(-10);
            insert contact;
            contact.Last_Trial_Start_Date__c = Datetime.now();
            update contact;
            System.assert(findRequests(contact.Id).isEmpty());
        }
    }

    @IsTest
    static void testUpdateWithNewTrialRequest() {
        System.runAs(TestUtils.getUserByEmail(MARKETO_USER_EMAIL).get(0)) {
            final Contact contact = TestDataFactory.createContact();
            insert contact;
            contact.Last_Trial_Start_Date__c = Datetime.now();
            contact.Last_Trial_Account_Id__c = 123;
            update contact;

            final List<Request__c> restartRequests = findRequests(contact.Id);
            System.assert(!restartRequests.isEmpty());
            System.assert(restartRequests.size() == 1);
            final Request__c restartRequest = restartRequests.get(0);
            System.assertEquals('Trial - New - ' + contact.FirstName + ' ' + contact.LastName, restartRequest.Name);
            System.assertEquals('Trial', restartRequest.Type__c);
            System.assertEquals('New', restartRequest.Subtype__c);
            System.assertEquals('Pending', restartRequest.Status__c);
            System.assertEquals(123, restartRequest.WrikeAccountId__c);
        }
    }

    @IsTest
    static void testLastTrialStartedLessThan7DaysAgo() {
        System.runAs(TestUtils.getUserByEmail(MARKETO_USER_EMAIL).get(0)) {
            final Contact contact = TestDataFactory.createContact();
            contact.Last_Trial_Start_Date__c = Datetime.now().addDays(-5);
            insert contact;
            contact.Last_Trial_Start_Date__c = Datetime.now();
            contact.Last_Trial_Account_Id__c = 123;
            update contact;

            final List<Request__c> restartRequests = findRequests(contact.Id);
            System.assert(!restartRequests.isEmpty());
            System.assert(restartRequests.size() == 1);
            final Request__c restartRequest = restartRequests.get(0);
            System.assertEquals('Trial - Restart - ' + contact.FirstName + ' ' + contact.LastName, restartRequest.Name);
            System.assertEquals('Trial', restartRequest.Type__c);
            System.assertEquals('Restart', restartRequest.Subtype__c);
            System.assertEquals(123, restartRequest.WrikeAccountId__c);
            System.assertEquals('Completed', restartRequest.Status__c);
        }
    }

    @IsTest
    static void testLastTrialDateOlderThan2Weeks() {
        System.runAs(TestUtils.getUserByEmail(MARKETO_USER_EMAIL).get(0)) {
            final Contact contact = TestDataFactory.createContact();
            insert contact;
            contact.Last_Trial_Start_Date__c = Datetime.now().addDays(-20);
            contact.Last_Trial_Account_Id__c = 123;
            update contact;

            final List<Request__c> restartRequests = findRequests(contact.Id);
            System.assert(!restartRequests.isEmpty());
            System.assert(restartRequests.size() == 1);
            final Request__c restartRequest = restartRequests.get(0);
            System.assertEquals('Trial - New - ' + contact.FirstName + ' ' + contact.LastName, restartRequest.Name);
            System.assertEquals('Trial', restartRequest.Type__c);
            System.assertEquals('New', restartRequest.Subtype__c);
            System.assertEquals(123, restartRequest.WrikeAccountId__c);
            System.assertEquals('Completed', restartRequest.Status__c);
        }
    }

    @IsTest
    static void testUpdateMarketingAssignment() {
        System.runAs(TestUtils.getUserByEmail(MARKETO_USER_EMAIL).get(0)) {
            final Contact contact = TestDataFactory.createContact();
            insert contact;
            contact.MarketingAssignmentId__c = '12345';
            update contact;

            final List<Request__c> requests = findRequests(contact.Id);
            System.assert(!requests.isEmpty());
            System.assert(requests.size() == 1);
            final Request__c request = requests.get(0);
            System.assertEquals('MarketingAssignment - ' + contact.FirstName + ' ' + contact.LastName,
                    request.Name);
            System.assertEquals('MarketingAssignment', request.Type__c);
            System.assertEquals(null, request.WrikeAccountId__c);
            System.assertEquals('Pending', request.Status__c);
        }
    }

    @IsTest
    static void testSelfManagedTrialStart() {
        System.runAs(TestUtils.getUserByEmail(MARKETO_USER_EMAIL).get(0)) {
            final Contact contact = TestDataFactory.createContact();
            insert contact;

            System.assert(findRequests(Contact.Id).isEmpty());

            contact.Last_Trial_Action_Source__c = 'AccountManagement';
            contact.Last_Trial_Product__c = 'resource,';
            update contact;

            final List<Request__c> requests = findRequests(contact.Id);
            System.assert(!requests.isEmpty());
            System.assert(requests.size() == 1);
            final Request__c request = requests.get(0);
            System.assertEquals('SelfManagedTrial - ' + contact.FirstName + ' ' + contact.LastName, request.Name);
            System.assertEquals('SelfManagedTrial', request.Type__c);
            System.assertEquals(contact.Last_Trial_Product__c, request.Comment__c);
            System.assertEquals(null, request.WrikeAccountId__c);
            System.assertEquals('Pending', request.Status__c);
        }
    }

    private static List<Request__c> findRequests(final Id contactId) {
        return [
                SELECT Id, Name, Type__c, Subtype__c, Status__c, WrikeAccountId__c, Comment__c
                FROM Request__c
                WHERE Contact__c = :contactId
        ];
    }
}
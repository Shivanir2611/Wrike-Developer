@IsTest
private class ContactServiceTest {

    private static final String ACCOUNT_NAME = 'Test Account 20170411';

    @TestSetup
    static void setup() {
        final Account testAccount = TestDataFactory.createAccount(ACCOUNT_NAME);
        TestUtils.insertAndAssert(testAccount);
    }

    @IsTest
    static void testUpdateEmailDomainInAccountAfterInsertContacts() {
        Account testAccount = TestUtils.findAccountByName(ACCOUNT_NAME);

        Contact testContact1 = TestDataFactory.createContact(null, ACCOUNT_NAME, 'test@mydomain.com');
        Contact testContact2 = TestDataFactory.createContact(testAccount.Id, ACCOUNT_NAME, 'test@gmail.com');
        Contact testContact3 = TestDataFactory.createContact(testAccount.Id, ACCOUNT_NAME, 'test@myawesomedomain.com');
        TestUtils.insertAndAssert(new List<Contact>{testContact1, testContact2, testContact3});

        testAccount = TestUtils.findAccountByName(ACCOUNT_NAME);
        System.assertEquals('myawesomedomain.com', testAccount.Email_Domain__c);
    }

    @IsTest
    static void testNotUpdateEmailDomainInAccountIfAlreadyExist() {
        Account testAccount = TestDataFactory.createAccount(ACCOUNT_NAME + '+1');
        testAccount.Email_Domain__c = 'myuniquefirstdomain.com';
        TestUtils.insertAndAssert(testAccount);

        Contact testContact1 = TestDataFactory.createContact(null, ACCOUNT_NAME, 'test@mydomain.com');
        Contact testContact2 = TestDataFactory.createContact(testAccount.Id, ACCOUNT_NAME, 'test@gmail.com');
        Contact testContact3 = TestDataFactory.createContact(testAccount.Id, ACCOUNT_NAME, 'test@myawesomedomain.com');
        TestUtils.insertAndAssert(new List<Contact>{testContact1, testContact2, testContact3});

        testAccount = TestUtils.findAccountById(testAccount.Id);
        System.assertEquals('myuniquefirstdomain.com', testAccount.Email_Domain__c);
    }
}
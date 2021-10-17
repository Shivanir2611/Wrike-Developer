@IsTest
public class ContactUpdateJobTest {
    
    @IsTest
    static void testContactOwnerUpdate() {
    	final User user1 = TestUtils.createUser('testusr1', 'account.trigger.test.user1@team.wrike.com', 'Standard User');
        final User user2 = TestUtils.createUser('testusr2', 'account.trigger.test.user2@team.wrike.com', 'Standard User');
        final Account account = new Account(
            Name = 'Test Account',
            OwnerId = user1.Id
        );
        insert account;
        final Contact contact = new Contact(
            LastName = 'Test Contact',
            OwnerId = user1.Id,
            AccountId = account.Id,
            HasOptedOutOfEmail = false
        );
        insert contact;
        
        Test.startTest();
        account.OwnerId = user2.Id;
        update account;
        Database.executeBatch(new ContactUpdateJob());
        Test.stopTest();
        
        final Contact updatedContact = [SELECT Id, OwnerId FROM Contact WHERE AccountId =: account.Id];
        System.assertEquals(updatedContact.OwnerId, user2.Id);
    }
    
    @IsTest
    static void testContactOwnerNotSDRTypeUpdate() {
    	final User user1 = TestUtils.createUser('testusr1', 'account.trigger.test.user1@team.wrike.com', 'Standard User');
        final User user2 = TestUtils.createUser('testusr2', 'account.trigger.test.user2@team.wrike.com', 'Standard User');
        user1.SDR_Type__c = 'T2T';
        update user1;
        final Account account = new Account(
            Name = 'Test Account',
            OwnerId = user2.Id
        );
        insert account;
        final Contact contact = new Contact(
            LastName = 'Test Contact',
            OwnerId = user1.Id,
            AccountId = account.Id,
            HasOptedOutOfEmail = false
        );
        insert contact;
        
        Test.startTest();
        Database.executeBatch(new ContactUpdateJob());
        Test.stopTest();
        
        final Contact updatedContact = [SELECT Id, OwnerId FROM Contact WHERE AccountId =: account.Id];
        System.assertNotEquals(updatedContact.OwnerId, user2.Id);
    }
}
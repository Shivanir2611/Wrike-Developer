@IsTest
public class AccountTriggerTest {
    
    @IsTest
    static void testAccountInsert() {
        final Account account = new Account(
            Name = 'Test Account',
            BillingCountryCode = 'US'
        );
        Test.startTest();
        insert account;
        Test.stopTest();
        final Account createdAccount = [
            SELECT CountryCode__c, Region__c
            FROM Account
            WHERE Id = :account.Id
        ];
        System.assertEquals('US', createdAccount.CountryCode__c);
        System.assertEquals('North America', createdAccount.Region__c);
    }
    
    @IsTest
    static void testAccountCountryUpdate() {
        final Account account = new Account(
            Name = 'Test Account',
            BillingCountryCode = 'US'
        );
        insert account;
        Test.startTest();
        account.BillingCountryCode = 'RU';
        update account;
        Test.stopTest();
        final Account updatedAccount = [
            SELECT CountryCode__c, Region__c
            FROM Account
            WHERE Id = :account.Id
        ];
        System.assertEquals('RU', updatedAccount.CountryCode__c);
        System.assertEquals('Russo', updatedAccount.Region__c);
    }
    
    @IsTest
    static void testTaskReassignment() {
        final User user1 = TestUtils.createUser('testusr1', 'account.trigger.test.user1@team.wrike.com', 'Standard User');
        final User user2 = TestUtils.createUser('testusr2', 'account.trigger.test.user2@team.wrike.com', 'Standard User');
        final Account account = new Account(
            Name = 'Test Account'
        );
        insert account;
        final Task task = new Task(
            OwnerId = user1.Id,
            WhatId = account.Id,
            Status = 'Open',
            Subject = 'Test Task',
            ActivityDate = Date.today()
        );
        insert task;
        
        Test.startTest();
        account.OwnerId = user2.Id;
        update account;
        Test.stopTest();
        
        System.assert([SELECT OwnerId FROM Task WHERE Id = :task.Id][0].OwnerId == user2.Id, 'Task was not reassigned');
    }
    
    @IsTest
    static void testSfAdminTaskReassignment() {
        final User user = TestUtils.createUser('testusr1', 'account.trigger.test.user1@team.wrike.com', 'Standard User');
        final Account account = new Account(
            Name = 'Test Account'
        );
        insert account;
        final Task task = new Task(
            OwnerId = WrikeConstants.SF_ADMIN_ID,
            WhatId = account.Id,
            Status = 'Open',
            Subject = 'Test Task',
            ActivityDate = Date.today()
        );
        insert task;
        
        Test.startTest();
        account.OwnerId = user.Id;
        update account;
        Test.stopTest();
        
        System.assert([SELECT OwnerId FROM Task WHERE Id = :task.Id][0].OwnerId == user.Id, 'Task was not reassigned');
    }
    
    @IsTest
    static void testOpportunityAssigned() {
        final User user1 = TestUtils.createUser('testusr1', 'account.trigger.test.user1@team.wrike.com', 'Standard User');
        final User user2 = TestUtils.createUser('testusr2', 'account.trigger.test.user2@team.wrike.com', 'Standard User');
        final Account account = new Account(
            Name = 'Test Account1',
            OwnerId = user1.Id);
        insert account;
        
        final Settings__c config = Settings__c.getOrgDefaults();
        config.Wrike_Integration_User_Id__c = user1.Id;
        insert config;
        
        final Opportunity opportunity = new Opportunity(
            AccountId = account.Id,
            Name = 'Test Opp',
            StageName = 'Pursuit',
            CloseDate = Date.today(),
            OwnerId = Settings__c.getOrgDefaults().Wrike_Integration_User_Id__c
        );
        insert opportunity;
        
        Test.startTest();
        account.OwnerId = user2.Id;
        update account;
        Test.stopTest();
        
        final Opportunity updatedOpportunity = [
            SELECT OwnerId 
            FROM Opportunity 
            WHERE Id = :opportunity.Id
        ];
        System.assertEquals(user2.Id, updatedOpportunity.OwnerId);
    }
    
    @IsTest
    static void testRenewalOpportunityNotReassigned() {
        final User user1 = TestUtils.createUser('testusr1', 'account.trigger.test.user1@team.wrike.com', 'Standard User');
        final User user2 = TestUtils.createUser('testusr2', 'account.trigger.test.user2@team.wrike.com', 'Standard User');
        final Account account = new Account(
            Name = 'Test Account1',
            OwnerId = user1.Id);
        insert account;
        
        final Settings__c config = Settings__c.getOrgDefaults();
        config.Wrike_Integration_User_Id__c = user1.Id;
        insert config;
        
        final Opportunity opportunity = new Opportunity(
            AccountId = account.Id,
            Type = 'Renewal',
            Name = 'Test Opp',
            StageName = 'Pursuit',
            CloseDate = Date.today(),
            OwnerId = getApiUserId()
        );
        insert opportunity;
        
        Test.startTest();
        account.OwnerId = user2.Id;
        update account;
        Test.stopTest();
        
        final Opportunity updatedOpportunity = [
            SELECT OwnerId 
            FROM Opportunity 
            WHERE Id = :opportunity.Id
        ];
        System.assertEquals(getApiUserId(), updatedOpportunity.OwnerId, 'Renewal opportunity should not be reassigned.');
    }

    @IsTest
    static void testEcommOpportunityNotReassigned() {
        final User user1 = TestUtils.createUser('testusr1', 'account.trigger.test.user1@team.wrike.com', 'Standard User');
        final User user2 = TestUtils.createUser('testusr2', 'account.trigger.test.user2@team.wrike.com', 'Standard User');
        final Account account = new Account(
                Name = 'Test Account1',
                OwnerId = user1.Id);
        insert account;

        final Settings__c config = Settings__c.getOrgDefaults();
        config.Wrike_Integration_User_Id__c = user1.Id;
        insert config;

        final Opportunity opportunity = new Opportunity(
                AccountId = account.Id,
                Name = 'Test Opp',
                StageName = '0-MQL',
                CloseDate = Date.today(),
                OwnerId = getApiUserId(),
                eCommerce__c = true
        );
        insert opportunity;

        account.OwnerId = user2.Id;
        update account;

        final Opportunity updatedOpportunity = [
                SELECT OwnerId
                FROM Opportunity
                WHERE Id = :opportunity.Id
        ];
        System.assertEquals(getApiUserId(), updatedOpportunity.OwnerId, 'Ecomm opportunity should not be reassigned.');
    }
    
    @IsTest
    static void testAssignedOpportunityNotReassigned() {
        final User user1 = TestUtils.createUser('testusr1', 'account.trigger.test.user1@team.wrike.com', 'Standard User');
        final User user2 = TestUtils.createUser('testusr2', 'account.trigger.test.user2@team.wrike.com', 'Standard User');
        final Account account = new Account(
            Name = 'Test Account1',
            OwnerId = user1.Id);
        insert account;
        
        final Opportunity opportunity = new Opportunity(
            AccountId = account.Id,
            Name = 'Test Opp',
            StageName = 'Pursuit',
            CloseDate = Date.today(),
            OwnerId = user1.Id
        );
        insert opportunity;
        
        Test.startTest();
        account.OwnerId = user2.Id;
        update account;
        Test.stopTest();
        
        final Opportunity updatedOpportunity = [
            SELECT OwnerId 
            FROM Opportunity 
            WHERE Id = :opportunity.Id
        ];
        System.assertEquals(user1.Id, updatedOpportunity.OwnerId);
    }
    
    private static String getApiUserId() {
        return Settings__c.getOrgDefaults().Wrike_Integration_User_Id__c;
    }
}
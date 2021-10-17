/*
* Created by sofia.kanukova on 02/09/2019.
*/
@IsTest
public class WrikeSubscriptionTriggerHandlerTest {
    private static final String ACCOUNT_NAME = 'Test Account 20170410';
    
    @TestSetup
    static void setup() {
        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);
    }
    
    @IsTest
    static void testTaskReassignment() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Subscription__c subscription = new Subscription__c (
            OwnerId = UserInfo.getUserId(),
            Account__c = account.Id,
            Status__c = 'Active'
        );
        insert subscription;
        
        final Task task = new Task(
            OwnerId = UserInfo.getUserId(),
            WhatId = subscription.Id,
            Status = 'Open',
            Subject = 'Test Task',
            ActivityDate = Date.today()
        );
        insert task;
        
        Test.startTest();
        
        final User user = TestUtils.findOtherSystemAdminUser();
        subscription.OwnerId = user.Id;
        update subscription;
        
        Test.stopTest();
        
        System.assert([SELECT OwnerId FROM Task WHERE Id = :task.Id][0].OwnerId == user.Id, 'Task was not reassigned');
    }
    
    @IsTest
    static void testDeploymentPopulated() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Opportunity opp = new Opportunity(
            AccountId= account.Id,
            Name = 'Very Looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong Name',
            StageName = 'Discovery',
            CloseDate = Date.today(),
            Department__c = 'IT',
            Billing__c = 'Credit Card',
            Billing_Terms__c = 'Monthly',
            Marketing_using_Wrike__c = 'No',
            Deployment__c = 'Yes',
            Deployment_Package__c = 'Small',
            Employee_Size__c = 1000,
            Wrike_Account_Id__c = 123
        );
        insert opp;
        
        final Deployment__c deployment = new Deployment__c(Name = 'Test Deployment', Opportunity__c = opp.Id, Account__c = account.Id);
        insert deployment;
        
        final Subscription__c subscription = new Subscription__c (
            Account__c = account.Id,
            Status__c = 'Active',
            Wrike_Account_Id__c = 123.0,
            MRR__c = 50
        );
        
        Test.startTest();
        
        insert subscription;
        
        Test.stopTest();
        
        System.assertEquals(subscription.Id, [SELECT Subscription__c FROM Deployment__c WHERE Id = :deployment.Id].Subscription__c);
    }
    
    @IsTest
    static void testMonthlySubscriptionTerms() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData = TestDataFactory.createWrikeData(123, false, 'RU', null, 'City', 'Street', 'PostalCode');
        TestUtils.insertAndAssert(wrikeData);
        
        final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, wrikeData.Id, 'Active', 123, 50);
        
        Test.startTest();
        
        insert subscription;
        
        Test.stopTest();
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        
        System.assertEquals('Monthly', updatedAccount.Wrike_Subscription_Terms__c);
        System.assertEquals('RU', updatedAccount.BillingCountryCode);
        System.assertEquals(null, updatedAccount.BillingStateCode);
        System.assertEquals('City', updatedAccount.BillingCity);
        System.assertEquals('Street', updatedAccount.BillingStreet);
        System.assertEquals('PostalCode', updatedAccount.BillingPostalCode);
    }
    
    @IsTest
    static void testAnnualSubscriptionTerms() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData = TestDataFactory.createWrikeData(1, true, 'US', 'CA', 'San Jose', '10 Almaden Blvd', '95113');
        TestUtils.insertAndAssert(wrikeData);
        
        final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, wrikeData.Id, 'Active', null, null);
        TestUtils.insertAndAssert(subscription);
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        System.assertEquals('Annual', updatedAccount.Wrike_Subscription_Terms__c);
        System.assertEquals('US', updatedAccount.BillingCountryCode);
        System.assertEquals('CA', updatedAccount.BillingStateCode);
        System.assertEquals('San Jose', updatedAccount.BillingCity);
        System.assertEquals('10 Almaden Blvd', updatedAccount.BillingStreet);
        System.assertEquals('95113', updatedAccount.BillingPostalCode);
    }
    
    @IsTest
    static void testMultipleSubscriptionsAnnualTerms() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(123, true, 'US', null, 'City', 'Street', 'PostalCode');
        TestUtils.insertAndAssert(wrikeData1);
        
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(123, false);
        TestUtils.insertAndAssert(wrikeData2);
        
        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Active', 123, 50);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Active', 321, 50);
        
        Test.startTest();
        
        insert new List<Subscription__c> { subscription1, subscription2 };
        
        Test.stopTest();
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        
        System.assertEquals('Annual', updatedAccount.Wrike_Subscription_Terms__c);
        System.assertEquals('US', updatedAccount.BillingCountryCode);
        System.assertEquals(null, updatedAccount.BillingStateCode);
        System.assertEquals('City', updatedAccount.BillingCity);
        System.assertEquals('Street', updatedAccount.BillingStreet);
        System.assertEquals('PostalCode', updatedAccount.BillingPostalCode);
    }
    
    @IsTest
    static void testSubscriptionSummary() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(123, true, 'US', null, 'City', 'Street', '12345', 99);
        TestUtils.insertAndAssert(wrikeData1);
        
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(123, true, 'US', null, 'City', 'Street', '12345', 49);
        TestUtils.insertAndAssert(wrikeData2);
        
        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Active', 123, 50);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Active', 321, 50);
        
        Test.startTest();
        
        insert new List<Subscription__c> { subscription1, subscription2 };
        
        Test.stopTest();
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        
        System.assertEquals('Customer', updatedAccount.Type);
        System.assertEquals(148, updatedAccount.Subscription_MRR_Sum__c);
        System.assertEquals(10, updatedAccount.Subscription_Users_Sum__c);
        System.assertEquals(20, updatedAccount.Subscription_Collaborators_Sum__c);
        System.assertEquals(30, updatedAccount.Subscription_License_Users_Sum__c);
    }
    
    @IsTest
    static void testUpdateBillingInfoFromFirstActiveSubscription() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(123, false, 'RU', '', 'C1', 'S2', 'P2');
        TestUtils.insertAndAssert(wrikeData1);
        
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(123, true, 'US', 'CA', 'City', 'Street', 'PostalCode');
        TestUtils.insertAndAssert(wrikeData2);
        
        final WrikeData__c wrikeData3 = TestDataFactory.createWrikeData(123, false, 'RU', '', 'C3', 'S3', 'P3');
        TestUtils.insertAndAssert(wrikeData3);
        
        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Deleted', 123, 50);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Active', 321, 50);
        final Subscription__c subscription3 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData3.Id, 'Active', 3210, 50);
        
        Test.startTest();
        
        TestUtils.insertAndAssert(subscription1);
        TestUtils.insertAndAssert(subscription2);
        TestUtils.insertAndAssert(subscription3);
        
        Test.stopTest();
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        System.assertEquals('US', updatedAccount.BillingCountryCode);
        System.assertEquals('CA', updatedAccount.BillingStateCode);
        System.assertEquals('City', updatedAccount.BillingCity);
        System.assertEquals('Street', updatedAccount.BillingStreet);
        System.assertEquals('PostalCode', updatedAccount.BillingPostalCode);
    }

    @IsTest
    static void testSingleSubCSM(){
        final User newUser = TestUtils.createUser('tstusr', 'testuser@team.wrike.com', '2.0 Customer Success | User');
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData = TestDataFactory.createWrikeData(123, false, 'RU', '', 'C1', 'S2', 'P2', 150);
        TestUtils.insertAndAssert(wrikeData);
        
        final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, wrikeData.Id, 'Active', 123, 50);
        TestUtils.insertAndAssert(subscription);
        
        Test.startTest();
        subscription.OwnerId = newUser.Id;
        update subscription;
        Test.stopTest();
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        
        System.assertEquals(updatedAccount.Primary_CSM__c, subscription.OwnerId);
    }
    
    @IsTest
    static void testMultipleSubCSM(){
        final User newUser = TestUtils.createUser('tstusr01', 'testuser01@team.wrike.com', '2.0 Customer Success | User');
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(123, false, 'RU', '', 'C1', 'S2', 'P2', 150);
        TestUtils.insertAndAssert(wrikeData1);
        
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(123, true, 'US', 'CA', 'City', 'Street', 'PostalCode', 105);
        TestUtils.insertAndAssert(wrikeData2);
        
        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Active', 123, 50);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Active', 321, 50);
        
        TestUtils.insertAndAssert(subscription1);
        TestUtils.insertAndAssert(subscription2);
        
        Test.startTest();
        subscription1.OwnerId = newUser.Id;
        subscription2.OwnerId = newUser.Id;
        update subscription1;
        update subscription2;
        Test.stopTest();
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        
        System.assertEquals(updatedAccount.Primary_CSM__c, subscription1.OwnerId);
    }
    
    @IsTest
    static void testMultipleDiffSubCSM(){
        final User user1 = TestUtils.createUser('tstusr01', 'testuser01@team.wrike.com', '2.0 Customer Success | User');
        final User user2 = TestUtils.createUser('tstusr02', 'testuser02@team.wrike.com', '2.0 Customer Success | User');
        
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(123, false, 'RU', '', 'C1', 'S2', 'P2', 200);
        TestUtils.insertAndAssert(wrikeData1);
        
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(123, true, 'US', 'CA', 'City', 'Street', 'PostalCode', 100);
        TestUtils.insertAndAssert(wrikeData2);
        
        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Active', 123, 50);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Free', 321, 50);
        
        TestUtils.insertAndAssert(subscription1);
        TestUtils.insertAndAssert(subscription2);
        
        Test.startTest();
        subscription1.OwnerId = user1.Id;
        subscription2.OwnerId = user2.Id;
        update subscription1;
        update subscription2;
        Test.stopTest();
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        
        System.assertEquals(updatedAccount.Primary_CSM__c, subscription1.OwnerId);
    }
    
    @IsTest
    static void testMultipleDiffSub(){
        final User user1 = TestUtils.createUser('tstusr01', 'testuser01@team.wrike.com', '2.0 Customer Success | User');
        final User user2 = TestUtils.createUser('tstusr02', 'testuser02@team.wrike.com', '2.0 Customer Success | User');
        
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(123, false, 'RU', '', 'C1', 'S2', 'P2', 1000);
        TestUtils.insertAndAssert(wrikeData1);
        
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(123, true, 'US', 'CA', 'City', 'Street', 'PostalCode', 2000);
        TestUtils.insertAndAssert(wrikeData2);
        
        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Free', 123, 50);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Deleted', 321, 50);
        
        TestUtils.insertAndAssert(subscription1);
        TestUtils.insertAndAssert(subscription2);
        
        Test.startTest();
        subscription1.OwnerId = user1.Id;
        subscription2.OwnerId = user2.Id;
        update subscription1;
        update subscription2;
        Test.stopTest();
        
        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        
        System.assertEquals(updatedAccount.Primary_CSM__c, null);
    }
}
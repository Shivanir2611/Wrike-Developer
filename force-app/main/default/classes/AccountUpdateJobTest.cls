@IsTest
private class AccountUpdateJobTest {

    private static final String ACCOUNT_NAME = 'AccountUpdateJobTest';

    @TestSetup
    public static void setup() {
        System.runAs(TestUtils.getActiveUser()) {
            Account testAccount = TestDataFactory.createAccount(ACCOUNT_NAME);
            TestUtils.insertAndAssert(testAccount);
        }
    }
    
    @IsTest
    static void testUpgradeScore() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData1 = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            UpgradeScore__c = 0.01,
            MRR__c = 999
        );
        final WrikeData__c wrikeData2 = new WrikeData__c(
            Wrike_Account_Id__c = 2,
            UpgradeScore__c = 0.5,
            MRR__c = 100
        );
        TestUtils.insertAndAssert(wrikeData1);
        TestUtils.insertAndAssert(wrikeData2);

        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Active', null, null);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Active', null, null);
        TestUtils.insertAndAssert(subscription1);
        TestUtils.insertAndAssert(subscription2);

        Test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        Test.stopTest();

        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        System.assertEquals(0.5, updatedAccount.Subscription_Upgrade_Score__c, 'Upgrade score is not correct.');
    }

    @IsTest
    static void testMRRSum() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(1, true, 'RU', '', 'City', 'Street', 'Postal', 50);
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(2, true, 'RU', '', 'City1', 'Street1', 'Postal1', 200);
        wrikeData1.PartnerAdjustmentMRR__c = 100;
        wrikeData2.PartnerAdjustmentMRR__c = 200;
        TestUtils.insertAndAssert(wrikeData1);
        TestUtils.insertAndAssert(wrikeData2);

        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Active', null, null);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Active', null, null);
        TestUtils.insertAndAssert(subscription1);
        TestUtils.insertAndAssert(subscription2);

        Test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        Test.stopTest();

        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        System.assert(updatedAccount.Subscription_MRR_Sum__c == 250, 'MRR sum is not correct');
        System.assert(updatedAccount.Customer_MRR_Sum__c == 550, 'Customer MRR Sum is not correct');
    }

    @IsTest
    static void testUsersSum() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(1, true, 'RU', '', 'City', 'Street', 'Postal', 50);
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(2, true, 'RU', '', 'City1', 'Street1', 'Postal1', 200);
        TestUtils.insertAndAssert(wrikeData1);
        TestUtils.insertAndAssert(wrikeData2);

        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Active', null, null);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Active', null, null);
        TestUtils.insertAndAssert(subscription1);
        TestUtils.insertAndAssert(subscription2);

        Test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        Test.stopTest();

        final Account updatedAccount = TestUtils.findAccountById(account.Id);
        System.assert(updatedAccount.Subscription_Users_Sum__c == 10, 'Users sum is not correct');
        System.assert(updatedAccount.Subscription_Collaborators_Sum__c == 20, 'Collaborators sum is not correct');
        System.assert(updatedAccount.Subscription_License_Users_Sum__c == 30, 'License users sum is not correct');
    }

    @IsTest
    static void testWrikeAccountIdPopulated() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);

        final WrikeData__c wrikeData1 = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            MRR__c = 150
        );
        final WrikeData__c wrikeData2 = new WrikeData__c(
            Wrike_Account_Id__c = 2,
            MRR__c = 200
        );
        final WrikeData__c wrikeData3 = new WrikeData__c(
            Wrike_Account_Id__c = 3,
            MRR__c = 50
        );
        insert wrikeData1;
        insert wrikeData2;
        insert wrikeData3;

        final Subscription__c subscription1 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Account_Id__c = 1,
            Wrike_Data__c = wrikeData1.Id,
            Status__c = 'Active'
        );
        final Subscription__c subscription2 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Account_Id__c = 2,
            Wrike_Data__c = wrikeData2.Id,
            Status__c = 'Active'
        );
        final Subscription__c subscription3 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Account_Id__c = 3,
            Wrike_Data__c = wrikeData3.Id,
            Status__c = 'Active'
        );
        insert subscription1;
        insert subscription2;
        insert subscription3;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Wrike_Account_Id__c FROM Account WHERE Id = :account.Id][0];
        System.assert(updatedAccount.Wrike_Account_Id__c == 2, 'Wrike Account Id is not correct');
    }
    
    @IsTest
    static void testWrikeAccountIdNotChanged() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        account.Wrike_Account_Id__c = 1;
        update account;

        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 2,
            MRR__c = 150
        );
        insert wrikeData;

        final Subscription__c subscription = new Subscription__c (
            Account__c = account.Id,
            Wrike_Account_Id__c = 2,
            Wrike_Data__c = wrikeData.Id,
            Status__c = 'Free'
        );
        insert subscription;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Wrike_Account_Id__c FROM Account WHERE Id = :account.Id][0];
        System.assert(updatedAccount.Wrike_Account_Id__c == 1, 'Wrike Account Id should not be changed.');
    }
    
    @IsTest
    static void testWrikeAccountIdNotRemoved() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        account.Wrike_Account_Id__c = 1;
        update account;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Wrike_Account_Id__c FROM Account WHERE Id = :account.Id][0];
        System.assert(updatedAccount.Wrike_Account_Id__c == 1, 'Wrike Account Id should not be changed.');
    }

    @IsTest
    static void testEnterpriseProductType() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Enterprise__c = true,
            MRR__c = 50
        );
        insert wrikeData;

        final Subscription__c subscription = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        insert subscription;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Product_Type__c FROM Account WHERE Id = :account.Id][0];
        System.assertEquals('Enterprise', updatedAccount.Product_Type__c, 'Product Type is not correct');
    }

    @IsTest
    static void testEnterpriseCreativeProductType() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Enterprise_Creative__c = true,
            MRR__c = 50
        );
        insert wrikeData;

        final Subscription__c subscription = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        insert subscription;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Product_Type__c FROM Account WHERE Id = :account.Id][0];
        System.assertEquals('Enterprise Creative', updatedAccount.Product_Type__c);
    }

    @IsTest
    static void testBusinessProductType() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Business__c = true,
            MRR__c = 50
        );
        insert wrikeData;

        final Subscription__c subscription = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        insert subscription;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Product_Type__c FROM Account WHERE Id = :account.Id][0];
        System.assertEquals('Business', updatedAccount.Product_Type__c);
    }

    @IsTest
    static void testBusinessCreativeProductType() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Business_Creative__c = true,
            MRR__c = 50
        );
        insert wrikeData;

        final Subscription__c subscription = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        insert subscription;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Product_Type__c FROM Account WHERE Id = :account.Id][0];
        System.assertEquals('Business Creative', updatedAccount.Product_Type__c);
    }

    @IsTest
    static void testProfessionalProductType() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Professional__c = true,
            MRR__c = 199
        );
        insert wrikeData;

        final Subscription__c subscription = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        insert subscription;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Product_Type__c FROM Account WHERE Id = :account.Id][0];
        System.assertEquals('Professional', updatedAccount.Product_Type__c);
    }

    @IsTest
    static void testMultipleProductType() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData1 = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Enterprise__c = true,
            MRR__c = 199
        );
        final WrikeData__c wrikeData2 = new WrikeData__c(
            Wrike_Account_Id__c = 2,
            Professional__c = true,
            MRR__c = 99
        );
        insert wrikeData1;
        insert wrikeData2;


        final Subscription__c subscription1 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData1.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        final Subscription__c subscription2 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData2.Id,
            Wrike_Account_Id__c = 2,
            Status__c = 'Active'
        );
        insert subscription1;
        insert subscription2;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Product_Type__c FROM Account WHERE Id = :account.Id][0];
        System.assertEquals('Multiple', updatedAccount.Product_Type__c);
    }

    @IsTest
    static void testAnnualRenewalDate() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);

        final DateTime date1 = DateTime.now().addDays(1);
        final DateTime date2 = DateTime.now().addDays(2);
        final DateTime date3 = DateTime.now().addDays(3);

        final WrikeData__c wrikeData1 = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Annual__c = false,
            Contract_End_Date__c = date1,
            MRR__c = 199
        );
        final WrikeData__c wrikeData2 = new WrikeData__c(
            Wrike_Account_Id__c = 2,
            Annual__c = true,
            Contract_End_Date__c = date2,
            MRR__c = 199
        );
        final WrikeData__c wrikeData3 = new WrikeData__c(
            Wrike_Account_Id__c = 3,
            Annual__c = true,
            Contract_End_Date__c = date3,
            MRR__c = 199
        );
        insert wrikeData1;
        insert wrikeData2;
        insert wrikeData3;

        final Subscription__c subscription1 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData1.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        final Subscription__c subscription2 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData2.Id,
            Wrike_Account_Id__c = 2,
            Status__c = 'Active'
        );
        final Subscription__c subscription3 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData3.Id,
            Wrike_Account_Id__c = 3,
            Status__c = 'Active'
        );
        insert subscription1;
        insert subscription2;
        insert subscription3;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Next_Annual_Renewal_Date__c FROM Account WHERE Id = :account.Id][0];
        System.assertEquals(date2.date(), updatedAccount.Next_Annual_Renewal_Date__c);
    }

    @IsTest
    static void testHealthScoreSum() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData1 = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Activity_Score__c = 200,
            MRR__c = 199
        );
        final WrikeData__c wrikeData2 = new WrikeData__c(
            Wrike_Account_Id__c = 2,
            Activity_Score__c = 50,
            MRR__c = 199
        );
        final WrikeData__c wrikeData3 = new WrikeData__c(
            Wrike_Account_Id__c = 3,
            MRR__c = 199
        );
        insert wrikeData1;
        insert wrikeData2;


        final Subscription__c subscription1 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData1.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        final Subscription__c subscription2 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData2.Id,
            Wrike_Account_Id__c = 2,
            Status__c = 'Active'
        );
        final Subscription__c subscription3 = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData3.Id,
            Wrike_Account_Id__c = 3,
            Status__c = 'Active'
        );
        insert subscription1;
        insert subscription2;
        insert subscription3;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [SELECT Id, Aggregate_Account_Health_Score__c FROM Account WHERE Id = :account.Id][0];
        System.assert(updatedAccount.Aggregate_Account_Health_Score__c == 250, 'Health score sum is not correct');
    }

    @IsTest
    static void testProductUsageAggregation() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData1 = new WrikeData__c(
                Wrike_Account_Id__c = 1,
                MRR__c = 99,
                ApprovalReviewsCreated__c = 1,
                ProofingCommentsAdded__c = 2,
                ReportsAvailable__c = 3,
                RequestFormsAvailable__c = 4,
                RequestsFromRequestFormsPast28Days__c = 5,
                UniqueRequestFormsUsedPast28Days__c = 6,
                Custom_Fields__c = 7,
                CustomFieldsUsagePast28Days__c = 8,
                UniqueCustomFieldsUsedPast28Days__c = 9,
                PAAvailable__c = 10,
                PAUsagePast28Days__c = 11,
                UniquePAUsedPast28Days__c = 12,
                ReportsUsagePast28Days__c = 13,
                UniqueReportsUsedPast28Days__c = 14,
                CalendarsAvailable__c = 15,
                CalendarsUsagePast28Days__c = 16,
                UniqueCalendarsUsedPast28Days__c = 17,
                DashboardsAvailable__c = 18,
                DashboardsUsagePast28Days__c = 19,
                UniqueDashboardsUsedPast28Days__c = 20,
                EditWau__c = 21
        );
        final WrikeData__c wrikeData2 = new WrikeData__c(
                Wrike_Account_Id__c = 2,
                MRR__c = 199,
                ApprovalReviewsCreated__c = 1,
                ProofingCommentsAdded__c = 2,
                ReportsAvailable__c = 3,
                RequestFormsAvailable__c = 4,
                RequestsFromRequestFormsPast28Days__c = 5,
                UniqueRequestFormsUsedPast28Days__c = 6,
                Custom_Fields__c = 7,
                CustomFieldsUsagePast28Days__c = 8,
                UniqueCustomFieldsUsedPast28Days__c = 9,
                PAAvailable__c = 10,
                PAUsagePast28Days__c = 11,
                UniquePAUsedPast28Days__c = 12,
                ReportsUsagePast28Days__c = 13,
                UniqueReportsUsedPast28Days__c = 14,
                CalendarsAvailable__c = 15,
                CalendarsUsagePast28Days__c = 16,
                UniqueCalendarsUsedPast28Days__c = 17,
                DashboardsAvailable__c = 18,
                DashboardsUsagePast28Days__c = 19,
                UniqueDashboardsUsedPast28Days__c = 20,
                EditWau__c = 21
        );
        insert wrikeData1;
        insert wrikeData2;


        final Subscription__c subscription1 = new Subscription__c (
                Account__c = account.Id,
                Wrike_Data__c = wrikeData1.Id,
                Wrike_Account_Id__c = 1,
                Status__c = 'Active'
        );
        final Subscription__c subscription2 = new Subscription__c (
                Account__c = account.Id,
                Wrike_Data__c = wrikeData2.Id,
                Wrike_Account_Id__c = 2,
                Status__c = 'Active'
        );
        insert subscription1;
        insert subscription2;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [
                SELECT Id, Subscription_Approval_Reviews_Created__c, Subscription_Proofing_Comments_Added__c,
                       Subscription_Reports_Available__c, Subscription_Request_Forms_Available__c,
                       Subscription_Request_Forms_Used_28_Days__c, Subscription_Forms_Requests_28_Days__c,
                       Subscription_CF__c, Subscription_CF_Usage_28_Days__c, Subscription_Unique_CF_Used_28_Days__c,
                       Subscription_PA_Available__c, Subscription_PA_Usage_28_Days__c, Subscription_Unique_PA_Used_28_Days__c,
                       Subscription_Reports_Usage_28_Days__c, Subscription_Unique_Reports_Used_28_Days__c,
                       Subscription_CLD_Available__c, Subscription_CLD_Usage_28_Days__c, Subscription_Unique_CLD_Used_28_Days__c,
                       Subscription_DB_Available__c, Subscription_DB_Usage_28_Days__c, Subscription_Unique_DB_Usage_28_Days__c,
                       Subscription_Edit_Wau__c
                FROM Account
                WHERE Id = :account.Id
        ];
        System.assertEquals(2, updatedAccount.Subscription_Approval_Reviews_Created__c);
        System.assertEquals(4, updatedAccount.Subscription_Proofing_Comments_Added__c);
        System.assertEquals(6, updatedAccount.Subscription_Reports_Available__c);
        System.assertEquals(8, updatedAccount.Subscription_Request_Forms_Available__c);
        System.assertEquals(10, updatedAccount.Subscription_Forms_Requests_28_Days__c);
        System.assertEquals(12, updatedAccount.Subscription_Request_Forms_Used_28_Days__c);
        System.assertEquals(14, updatedAccount.Subscription_CF__c);
        System.assertEquals(16, updatedAccount.Subscription_CF_Usage_28_Days__c);
        System.assertEquals(18, updatedAccount.Subscription_Unique_CF_Used_28_Days__c);
        System.assertEquals(20, updatedAccount.Subscription_PA_Available__c);
        System.assertEquals(22, updatedAccount.Subscription_PA_Usage_28_Days__c);
        System.assertEquals(24, updatedAccount.Subscription_Unique_PA_Used_28_Days__c);
        System.assertEquals(26, updatedAccount.Subscription_Reports_Usage_28_Days__c);
        System.assertEquals(28, updatedAccount.Subscription_Unique_Reports_Used_28_Days__c);
        System.assertEquals(30, updatedAccount.Subscription_CLD_Available__c);
        System.assertEquals(32, updatedAccount.Subscription_CLD_Usage_28_Days__c);
        System.assertEquals(34, updatedAccount.Subscription_Unique_CLD_Used_28_Days__c);
        System.assertEquals(36, updatedAccount.Subscription_DB_Available__c);
        System.assertEquals(38, updatedAccount.Subscription_DB_Usage_28_Days__c);
        System.assertEquals(40, updatedAccount.Subscription_Unique_DB_Usage_28_Days__c);
        System.assertEquals(42, updatedAccount.Subscription_Edit_Wau__c);
    }

    @IsTest
    static void testSubscriptionTerm() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Enterprise__c = true,
            Annual__c = true,
            MRR__c = 50
        );
        insert wrikeData;

        final Subscription__c subscription = new Subscription__c (
            Account__c = account.Id,
            Wrike_Data__c = wrikeData.Id,
            Wrike_Account_Id__c = 1,
            Status__c = 'Active'
        );
        insert subscription;

        test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        test.stopTest();

        final Account updatedAccount = [
            SELECT Id, Wrike_Subscription_Terms__c
            FROM Account
            WHERE Id = :account.Id
        ][0];
        System.assertEquals('Annual', updatedAccount.Wrike_Subscription_Terms__c);
    }
    
    @IsTest
    static void testInActiveProspects() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final User newUser = TestUtils.createUser('testusr1', 'test.user1@team.wrike.com', 'Standard User');
        account.OwnerId = newUser.Id;
        account.Type = 'Prospect';
        update account;
        final Task task = new Task(
            Subject = 'Call',
            Call_disposition__c = 'Follow Up',
            Status = 'Open',
            Priority = 'Normal',
            OwnerId = account.OwnerId,
            WhatId = account.Id
        );
        insert task;
        
        final Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = account.Id,
            StageName = '0-MQL',
            Type = 'Expansion',
            CloseDate = date.newInstance(2019,06,01),
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        
        Test.startTest();
        Database.executeBatch(new AccountUpdateJob());
        Test.stopTest();  
        
        final Account updatedAccount = [
            SELECT Id, OwnerId
            FROM Account
            WHERE Id = :account.Id
        ];
        final Task updatedTask = [
            SELECT Id, Status, Description, Cancelled__c
            FROM Task 
            WHERE Id =: task.Id 
        ];
        final Opportunity updatedOpp = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id =: opp.Id
        ];
        System.assertEquals('005F0000003lL5rIAE', updatedAccount.OwnerId);
        System.assertEquals('Completed', updatedTask.Status);
        System.assertEquals('Task cancelled when opp was closed lost', updatedTask.Description);
        System.assertEquals(true, updatedTask.Cancelled__c);
        System.assertEquals('Closed Lost', updatedOpp.StageName);
    }
}
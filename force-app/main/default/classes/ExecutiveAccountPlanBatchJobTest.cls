@IsTest
public class ExecutiveAccountPlanBatchJobTest {
    
    private static final String ACCOUNT_NAME = 'AccountTest';
    
    @TestSetup
    public static void setup() {
        Account testAccount = TestDataFactory.createAccount(ACCOUNT_NAME);
        TestUtils.insertAndAssert(testAccount);
        
        final Contact testContact = TestDataFactory.createContact(testAccount.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(testContact);
        
        Executive_Account_Plan__c testExecutiveAccountPlan = new Executive_Account_Plan__c(
            Account__c = testAccount.Id,
            Planning_Year__c = '2020',
            Account_MRR_Goal__c = 1500
        );
        insert testExecutiveAccountPlan;
    }
    
    @IsTest
    static void testAccountPlanRelationshipCreation() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final Contact contact = TestUtils.findContact();
        contact.Department = 'IT';
        update contact;
        
        final Executive_Account_Plan__c testExecutiveAccountPlan = [
            SELECT Id 
            FROM Executive_Account_Plan__c 
            WHERE Account__c =: account.Id 
        ];
        final Account_Plan_Relationship__c testAccountPlanRelationship1 = new Account_Plan_Relationship__c(
            Executive_Account_Plan__c = testExecutiveAccountPlan.Id,
            Contact__c = contact.Id,
            Buying_Role__c = 'Decision Maker',
            Support__c = 'Confirmed Champion'
        );
        insert testAccountPlanRelationship1;
        
        final Account_Plan_Relationship__c testAccountPlanRelationship2 = new Account_Plan_Relationship__c(
            Executive_Account_Plan__c = testExecutiveAccountPlan.Id,
            Contact__c = contact.Id,
            Buying_Role__c = 'Decision Maker'
        );
        insert testAccountPlanRelationship2;
        
        final Account_Plan_Relationship__c testAccountPlanRelationship3 = new Account_Plan_Relationship__c(
            Executive_Account_Plan__c = testExecutiveAccountPlan.Id,
            Contact__c = contact.Id,
            Support__c = 'Champion'
        );
        insert testAccountPlanRelationship3;
        
        Test.startTest();
        Database.executeBatch(new ExecutiveAccountPlanBatchJob());
        Test.stopTest();
        
        final Executive_Account_Plan__c updatedEAPRecord = findEAPRecord(testExecutiveAccountPlan.Id);
        
        System.assertEquals(2, updatedEAPRecord.Number_of_Decision_Makers__c);
        System.assertEquals(1, updatedEAPRecord.Number_of_Champions__c);
        System.assertEquals('TestDataFactoryName Test', updatedEAPRecord.Account_Plan_Champion_Name__c);
        System.assertEquals('IT', updatedEAPRecord.Account_Plan_Champion_Department__c);
    }
    
    @IsTest
    static void testChurnedAccountCreation() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Executive_Account_Plan__c testExecutiveAccountPlan = [
            SELECT Id 
            FROM Executive_Account_Plan__c 
            WHERE Account__c =: account.Id 
        ];
        
        account.Type = 'Churned';
        account.Executive_Account_Plan__c = testExecutiveAccountPlan.Id;
        update account;
        
        Test.startTest();
        Database.executeBatch(new ExecutiveAccountPlanBatchJob());
        Test.stopTest();
        
        final Executive_Account_Plan__c updatedEAPRecord = findEAPRecord(testExecutiveAccountPlan.Id );
        
        System.assertEquals(1, updatedEAPRecord.Number_of_Churned_Accounts__c);
    }
    
    @IsTest
    static void testProspectAccountCreation() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Executive_Account_Plan__c testExecutiveAccountPlan = [
            SELECT Id 
            FROM Executive_Account_Plan__c 
            WHERE Account__c =: account.Id 
        ];
        
        account.Type = 'Prospect';
        account.Executive_Account_Plan__c = testExecutiveAccountPlan.Id;
        update account;
        
        Test.startTest();
        Database.executeBatch(new ExecutiveAccountPlanBatchJob());
        Test.stopTest();
        
        final Executive_Account_Plan__c updatedEAPRecord = findEAPRecord(testExecutiveAccountPlan.Id );
        
        System.assertEquals(1, updatedEAPRecord.Number_of_Prospect_Accounts__c);
    }
    
    @IsTest
    static void testCustomerAccountCreation() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Executive_Account_Plan__c testExecutiveAccountPlan = [
            SELECT Id 
            FROM Executive_Account_Plan__c 
            WHERE Account__c =: account.Id 
        ];
        
        account.Type = 'Customer';
        account.Executive_Account_Plan__c = testExecutiveAccountPlan.Id;
        update account;
        
        Test.startTest();
        Database.executeBatch(new ExecutiveAccountPlanBatchJob());
        Test.stopTest();
        
        final Executive_Account_Plan__c updatedEAPRecord = findEAPRecord(testExecutiveAccountPlan.Id );
        
        System.assertEquals(1, updatedEAPRecord.Number_of_Customer_Accounts__c);
    }
    
    @IsTest
    static void testOppCreation() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        Opportunity opportunity1 = TestDataFactory.createOpportunity(account.Id, 123);
        TestUtils.insertAndAssert(opportunity1);
        
        Opportunity opportunity2 = TestDataFactory.createOpportunity(account.Id, 456);
        TestUtils.insertAndAssert(opportunity2);
        
        Opportunity opportunity3 = TestDataFactory.createOpportunity(account.Id, 789);
        TestUtils.insertAndAssert(opportunity3);
        
        final Executive_Account_Plan__c testExecutiveAccountPlan = [
            SELECT Id 
            FROM Executive_Account_Plan__c 
            WHERE Account__c =: account.Id 
        ];
        
        opportunity1.StageName = 'Closed Won';
        opportunity1.Executive_Account_Plan__c = testExecutiveAccountPlan.Id;
        opportunity1.Wrike_Quote_MRR_Amount__c = 1500;
        update opportunity1;
        
        opportunity2.StageName = '0-MQL';
        opportunity2.Executive_Account_Plan__c = testExecutiveAccountPlan.Id;
        opportunity2.Wrike_Quote_MRR_Amount__c = 2500;
        update opportunity2;
        
        opportunity3.StageName = 'Closed Won';
        opportunity3.Executive_Account_Plan__c = testExecutiveAccountPlan.Id;
        opportunity3.Wrike_Quote_MRR_Amount__c = 2500;
        update opportunity3;
        
        Test.startTest();
        Database.executeBatch(new ExecutiveAccountPlanBatchJob());
        Test.stopTest();
        
        final Executive_Account_Plan__c updatedEAPRecord = findEAPRecord(testExecutiveAccountPlan.Id);
        
        System.assertEquals(2, updatedEAPRecord.Total_Closed_Sales_Opportunities__c);
        System.assertEquals(3, updatedEAPRecord.Total_Sales_Opportunties__c);
        System.assertEquals(2500, updatedEAPRecord.Sum_of_Open_Opportunity_MRR__c);
        System.assertEquals(4000, updatedEAPRecord.Sum_of_Closed_Opportunity_MRR__c);
    }
    
    private static Executive_Account_Plan__c findEAPRecord(final Id eapId) {
        return [
            SELECT Id, Number_of_Decision_Makers__c, Number_of_Champions__c, Account_Plan_Champion_Name__c, Account_Plan_Champion_Department__c,
            	   Number_of_Churned_Accounts__c, Number_of_Prospect_Accounts__c, Number_of_Customer_Accounts__c, Total_Closed_Sales_Opportunities__c, 
            	   Total_Sales_Opportunties__c, Sum_of_Open_Opportunity_MRR__c, Sum_of_Closed_Opportunity_MRR__c
            FROM Executive_Account_Plan__c
            WHERE Id = :eapId
        ];
    }
}
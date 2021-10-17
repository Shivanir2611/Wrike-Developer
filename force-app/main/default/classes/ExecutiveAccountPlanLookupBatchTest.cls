@IsTest
public class ExecutiveAccountPlanLookupBatchTest {
    
    private static final String ACCOUNT_NAME = 'ExecutiveAccountPlanLookupBatch';
    
    @TestSetup
    public static void setup() {
        Account testAccount = TestDataFactory.createAccount(ACCOUNT_NAME);
        TestUtils.insertAndAssert(testAccount);
        
        final Executive_Account_Plan__c eapRecord1 = new Executive_Account_Plan__c(
            Account__c = testAccount.Id,
            Planning_Year__c = '2020',
            Account_MRR_Goal__c = 1000
        );
        insert eapRecord1;
        Test.setCreatedDate(eapRecord1.Id, DateTime.newInstance(2020,7,10));
        
        final Executive_Account_Plan__c eapRecord2 = new Executive_Account_Plan__c(
            Account__c = testAccount.Id,
            Planning_Year__c = '2020',
            Account_MRR_Goal__c = 20
        );
        insert eapRecord2;
        Test.setCreatedDate(eapRecord2.Id, DateTime.newInstance(2020,7,12));
        
    }
    
    @IsTest
    static void testSubscriptionEAPUpdate(){
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(1, true, 'RU', '', 'City', 'Street', 'Postal', 1500);
        TestUtils.insertAndAssert(wrikeData1);
        
        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Free', null, null);
        TestUtils.insertAndAssert(subscription1);
        
        final Executive_Account_Plan__c eapRecord1 = findEAPRecord(1000);
        
        final Executive_Account_Plan__c eapRecord2 = findEAPRecord(20);
        
        Test.startTest();
        Database.executeBatch(new ExecutiveAccountPlanLookupBatch());
        Test.stopTest();
        
        final Subscription__c updatedSubscription = [
            SELECT Id, Executive_Account_Plan__c
            FROM Subscription__c 
            WHERE Id =: subscription1.Id
        ];
        System.assertEquals(eapRecord2.Id, updatedSubscription.Executive_Account_Plan__c);
    }
    
    @IsTest
    static void testDeploymentEAPUpdate(){
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Executive_Account_Plan__c eapRecord1 = findEAPRecord(1000);
        
        final Executive_Account_Plan__c eapRecord2 = findEAPRecord(20);
        
        final Deployment__c deployment = new Deployment__c(
            Name = 'Test Deployment 1',
            Account__c = account.Id
        );
        insert deployment;
        
        Test.startTest();
        Database.executeBatch(new ExecutiveAccountPlanLookupBatch());
        Test.stopTest();
        
        final Deployment__c updatedDeployment = [
            SELECT Id, Executive_Account_Plan__c
            FROM Deployment__c 
            WHERE Id =: deployment.Id
        ];
        System.assertEquals(eapRecord2.Id, updatedDeployment.Executive_Account_Plan__c);
    }
    
    
    @IsTest
    static void testOpportunityEAPUpdate(){
    	final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Executive_Account_Plan__c eapRecord1 = findEAPRecord(1000);
        
        final Executive_Account_Plan__c eapRecord2 = findEAPRecord(20);
        
        final Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Discovery',
            CloseDate = Date.newInstance(2020, 1, 1),
            AccountId = account.Id
        );
        insert testOpportunity;
        
        Test.startTest();
        Database.executeBatch(new ExecutiveAccountPlanLookupBatch());
        Test.stopTest();
        
        final Opportunity updatedOpportunity = [
            SELECT Id, Executive_Account_Plan__c
            FROM Opportunity 
            WHERE Id =: testOpportunity.Id
        ];
        System.assertEquals(eapRecord2.Id, updatedOpportunity.Executive_Account_Plan__c);     
    }
    
    private static Executive_Account_Plan__c findEAPRecord(final Integer mrrGoal) {
        return [
            SELECT Id 
            FROM Executive_Account_Plan__c 
            WHERE Account_MRR_Goal__c =: mrrGoal
        ];
    }
}
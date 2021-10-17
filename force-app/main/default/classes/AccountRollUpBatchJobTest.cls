@IsTest
public class AccountRollUpBatchJobTest {
    
    private static final String ACCOUNT_NAME = 'AccountRollUpBatchJobTest';
    
    @TestSetup
    public static void setup() {
        Account testAccount = TestDataFactory.createAccount(ACCOUNT_NAME);
        TestUtils.insertAndAssert(testAccount);
    }
    
    @IsTest
    static void testSubscriptionUpdate() {
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final WrikeData__c wrikeData1 = TestDataFactory.createWrikeData(1, true, 'RU', '', 'City', 'Street', 'Postal', 1500);
        TestUtils.insertAndAssert(wrikeData1);
        wrikeData1.Churned_Date__c = Date.newInstance(2020, 04, 11);
        wrikeData1.EditWau__c = 100.00;
        wrikeData1.Enterprise_Creative__c = true;
        wrikeData1.License_Users__c = 20.00;
        wrikeData1.Annual__c = true;
        update wrikeData1;
        
        final WrikeData__c wrikeData2 = TestDataFactory.createWrikeData(2, true, 'RU', '', 'City1', 'Street1', 'Postal1', 200);
        TestUtils.insertAndAssert(wrikeData2);
        wrikeData2.Churned_Date__c = Date.newInstance(2020, 05, 11);
        wrikeData2.EditWau__c = 50.00;
        wrikeData2.Business__c = true;
        wrikeData2.License_Users__c = 25.00;
        wrikeData2.Internal_Collaborators__c = 5;
        wrikeData2.External_Collaborators__c = 10;
        wrikeData2.Total_Collaborators_Purchased__c = 15;
        wrikeData2.Annual__c = false;
        update wrikeData2;
        
        final WrikeData__c wrikeData3 = TestDataFactory.createWrikeData(3, true, 'RU', '', 'City2', 'Street2', 'Postal2', 1000);
        TestUtils.insertAndAssert(wrikeData3);
        wrikeData3.Enterprise_Creative__c = true;
        update wrikeData3;
        
        final Subscription__c subscription1 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData1.Id, 'Free', null, null);
        final Subscription__c subscription2 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData2.Id, 'Active', null, null);
        final Subscription__c subscription3 = TestDataFactory.createWrikeSubscription(account.Id, wrikeData3.Id, 'Active', null, null);
        TestUtils.insertAndAssert(subscription1);
        TestUtils.insertAndAssert(subscription2);
        TestUtils.insertAndAssert(subscription3);
        
        Test.startTest();
        Database.executeBatch(new AccountRollUpBatchJob());
        Test.stopTest();
        
        final Account updatedAccount = findAccountById(account.Id);
        
        System.assertEquals(Date.newInstance(2020, 05,11), updatedAccount.Max_Subscription_Churn_Date__c);
        System.assertEquals('2', updatedAccount.Number_of_Active_Subscriptions__c);
        System.assertEquals('1', updatedAccount.Number_of_Churned_Subscriptions__c);
        System.assertEquals(subscription3.Id, updatedAccount.Primary_Wrike_Subscription__c);
        System.assertEquals(15, updatedAccount.Total_Collaborators_Purchased__c);
        System.assertEquals(5, updatedAccount.Internal_Collaborators__c);
        System.assertEquals(10, updatedAccount.External_Collaborators__c);
    }
    
    @IsTest
    static void testEAPUpdate(){
    	final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        final Executive_Account_Plan__c eapRecord1 = new Executive_Account_Plan__c(
            Account__c = account.Id,
            Planning_Year__c = '2020',
            Account_MRR_Goal__c = 1000
        );
        insert eapRecord1;
        Test.setCreatedDate(eapRecord1.Id, DateTime.newInstance(2020,7,10));
        
        final Executive_Account_Plan__c eapRecord2 = new Executive_Account_Plan__c(
            Account__c = account.Id,
            Planning_Year__c = '2020',
            Account_MRR_Goal__c = 20
        );
        insert eapRecord2;
        Test.setCreatedDate(eapRecord2.Id, DateTime.newInstance(2020,7,12));
        
        Test.startTest();
        Database.executeBatch(new AccountRollUpBatchJob());
        Test.stopTest();

        final Account updatedAccount = findAccountById(account.Id);
        
        System.assertEquals(eapRecord2.Id, updatedAccount.Executive_Account_Plan__c);
    }
    
    private static Account findAccountById(final Id accountId) {
        return [
            SELECT Id, Executive_Account_Plan__c, Max_Subscription_Churn_Date__c, Number_of_Active_Subscriptions__c, 
            	   Number_of_Churned_Subscriptions__c, Primary_Wrike_Subscription__c, Total_Collaborators_Purchased__c, 
            	   Internal_Collaborators__c, External_Collaborators__c
            FROM Account
            WHERE Id = :accountId
        ];
    }
}
@IsTest
public class WrikeDeploymentUpdateJobTest {
    
    @IsTest
    static void wrikeDeploymentInsertTest(){
        Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1
        );
        insert wrikeData;
        
        final Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Discovery',
            CloseDate = Date.today(),
            Department__c = 'IT',
            Billing__c = 'Credit Card',
            Billing_Terms__c = 'Monthly',
            Marketing_using_Wrike__c = 'No',
            Deployment__c = 'No',
            Employee_Size__c = 1000,
            Wrike_Account_Id__c = 1,
            Wrike_Data__c = wrikeData.Id,
            Account = account
        );
        insert opportunity;
        
        final Subscription__c subscription = new Subscription__c (
            OwnerId = UserInfo.getUserId(),
            Account__c = account.Id,
            Status__c = 'Active',
            Wrike_Account_Id__c = 1
        );
        insert subscription;
        
        final Deployment__c deployment = new Deployment__c(
            Name = 'Test Deployment 1',
            Account__c = account.Id,
            Opportunity__c = opportunity.Id
        );
        insert deployment;
        
        Test.startTest();
        Database.executeBatch(new WrikeDeploymentUpdateJob());
        Test.stopTest();
        
        final Deployment__c updatedDeployment = [
            SELECT Id, Subscription__c, Wrike_Data__c
            FROM Deployment__c
            WHERE Id =: deployment.Id
        ];
        
        System.assertEquals(updatedDeployment.Subscription__c, subscription.Id);
        System.assertEquals(updatedDeployment.Wrike_Data__c, wrikeData.Id);
    }
}
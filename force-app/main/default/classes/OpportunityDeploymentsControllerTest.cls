@IsTest
public class OpportunityDeploymentsControllerTest {
    
    @IsTest
    static void testOpportunityDeploymentsUpdate(){
        final Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        
        final Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 1);
        insert testOpportunity;
        
        final Subscription__c testSubscription = new Subscription__c(
            Name = 'Test Subscription',
            Account__c = testAccount.Id
        );
        insert testSubscription; 
        
        final Deployment__c testDeployment1 = new Deployment__c(
            Name = 'Test Deployment 1',
            Subscription__c = testSubscription.Id,
            Account__c = testAccount.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testDeployment1;
        
        final Deployment__c testDeployment2 = new Deployment__c(
            Name = 'Test Deployment 2',
            Subscription__c = testSubscription.Id,
            Account__c = testAccount.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert testDeployment2;
        
        Test.startTest();
        List<Deployment__c> relatedDeploymentList = OpportunityDeploymentsController.getDeployments(testDeployment1.Id);
        Test.stopTest();
        
        System.assertEquals(false, relatedDeploymentList.isEmpty());
    }
}
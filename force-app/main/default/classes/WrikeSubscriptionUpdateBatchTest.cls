@IsTest
private class WrikeSubscriptionUpdateBatchTest {

    @TestSetup
    static void setup() {
        final Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);
        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 123);
        testOpportunity.Deployment_Package__c = 'Small = (5-30 users)';
        TestUtils.insertAndAssert(testOpportunity);
    }

    @IsTest
    static void testUpdateSubscriptionWithOneDeployment() {
        final Account account = TestUtils.findAccount();
        final Opportunity opportunity = TestUtils.findOpportunity();

        final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, null, 'Active', 123, 555);
        TestUtils.insertAndAssert(subscription);

        final Datetime startDateTime = Datetime.now();
        final Datetime endDateTime = startDateTime.addDays(1);
        final Deployment__c deployment = TestDataFactory.createDeployment(opportunity.Id, account.Id, 'New', startDateTime, endDateTime);
        deployment.Subscription__c = subscription.Id;
        TestUtils.insertAndAssert(deployment);

        Test.startTest();

        Database.executeBatch(new WrikeSubscriptionUpdateBatch());

        Test.stopTest();

        final List<Subscription__c> updatedSubscriptions = TestUtils.findSubscriptions();
        System.assertEquals(1, updatedSubscriptions.size());
        System.assertEquals(deployment.Id, updatedSubscriptions.get(0).LastDeployment__c);
        System.assertEquals(deployment.Status__c, updatedSubscriptions.get(0).DeploymentStatus__c);
        System.assert(deployment.Start_Date__c.isSameDay(updatedSubscriptions.get(0).DeploymentStartDateTime__c));
        System.assert(deployment.End_Date__c.isSameDay(updatedSubscriptions.get(0).DeploymentEndDateTime__c));
        System.assertEquals(deployment.Deployment_Package__c, updatedSubscriptions.get(0).DeploymentPackage__c);


        final List<Deployment__c> updatedDeployments = TestUtils.findDeployments();
        System.assertEquals(1, updatedDeployments.size());
        System.assertEquals(subscription.Id, updatedDeployments.get(0).Subscription__c);
    }

    @IsTest
    static void testUpdateSubscriptionWithLastDeployment() {
        final Account account = TestUtils.findAccount();
        final Opportunity opportunity = TestUtils.findOpportunity();

        final Subscription__c subscription = TestDataFactory.createWrikeSubscription(account.Id, null, 'Active', 123, 555);
        TestUtils.insertAndAssert(subscription);

        final Datetime startDateTime = Datetime.now();
        final Datetime endDateTime = startDateTime.addDays(1);
        final Deployment__c deployment1 = TestDataFactory.createDeployment(opportunity.Id, account.Id, 'New', startDateTime, endDateTime);
        final Deployment__c deployment2 = TestDataFactory.createDeployment(opportunity.Id, account.Id, 'Started', startDateTime.addDays(2), endDateTime.addDays(2));
        Deployment__c deployment3 = TestDataFactory.createDeployment(opportunity.Id, account.Id, 'Completed', startDateTime.addDays(3), endDateTime.addDays(3));
        deployment1.Subscription__c = subscription.Id;
        deployment2.Subscription__c = subscription.Id;
        deployment3.Subscription__c = subscription.Id;
        TestUtils.insertAndAssert(new List<Deployment__c>{deployment1, deployment2, deployment3});

        Test.startTest();

        Database.executeBatch(new WrikeSubscriptionUpdateBatch());

        Test.stopTest();

        final List<Subscription__c> updatedSubscriptions = TestUtils.findSubscriptions();
        System.assertEquals(1, updatedSubscriptions.size());
        deployment3 = TestUtils.findDeploymentById(deployment3.Id);
        System.assertEquals(deployment3.Id, updatedSubscriptions.get(0).LastDeployment__c);
        System.assertEquals(deployment3.Status__c, updatedSubscriptions.get(0).DeploymentStatus__c);
        System.assert(deployment3.Start_Date__c.isSameDay(updatedSubscriptions.get(0).DeploymentStartDateTime__c));
        System.assert(deployment3.End_Date__c.isSameDay(updatedSubscriptions.get(0).DeploymentEndDateTime__c));
        System.assertEquals(deployment3.Deployment_Package__c, updatedSubscriptions.get(0).DeploymentPackage__c);
    }
}
@IsTest
public class WrikeDeploymentTriggerTest{
    
    @testSetup static void datacreation() {
        final Account accountRecord = new Account(
            Name = 'Test Account',
            BillingCountryCode = 'US'
        );
        insert accountRecord;
        
        final Account accountRecord2 = new Account(
            Name = 'Test Account 2',
            BillingCountryCode = 'US'
        );
        insert accountRecord2;
        
        List<Contact> contactList = new List<Contact>();        
        final Contact contact1 =new Contact(
            FirstName='First Name',
            LastName = 'Last Name',
            Email = 'email@gmail.com',
            Phone = '974-380-0309',
            AccountId = accountRecord.Id
        ); 
        insert contact1; 
        
        final Contact contact2 =new Contact(
            FirstName='First Name 1',
            LastName = 'Last Name 1',
            Email = 'test@gmail.com',
            Phone = '123-456-7890',
            AccountId = accountRecord.Id
        ); 
        insert contact2; 
        
        final Subscription__c subscriptionRecord = new Subscription__c(
            Name = 'Test Subscription',
            Account__c = accountRecord.Id
        );
        insert subscriptionRecord; 
        
        final Subscription__c subscriptionRecord2 = new Subscription__c(
            Name = 'Second Test Subscription',
            Account__c = accountRecord2.id
        );
        insert subscriptionRecord2; 
        
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'Deployment | Partner User'];
        User portalAccountOwner1 = new User(
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testz@test.com',
            Alias = 'test',
            Email='test@gmail.com',
            EmailEncodingKey='UTF-8',
            Firstname='First',
            Lastname='Last',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            Country='United States',
            IsActive=True,
            ContactId = contact1.Id
        );
        insert portalAccountOwner1; 
        
        User portalAccountOwner2 = new User(
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testa@test.com',
            Alias = 'test',
            Email='testing@gmail.com',
            EmailEncodingKey='UTF-8',
            Firstname='Firstname',
            Lastname='Lastname',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            Country='United States',
            IsActive=True,
            ContactId = contact2.Id
        );
        insert portalAccountOwner2;
    }
    
    @IsTest static void testDeploymentInsert() {
        Test.startTest();
        Account acct = [SELECT Id FROM Account WHERE Name='Test Account'];
        Subscription__c sub = [SELECT Id FROM Subscription__c WHERE Name='Test Subscription'];
        User portalUser = [SELECT Id FROM User WHERE Email='test@gmail.com'];
        final Deployment__c deployment = new Deployment__c(
            Name = 'Test Deployment 1',
            Subscription__c = sub.Id,
            Account__c = acct.Id,
            OwnerId = portalUser.Id  
        );
        insert deployment;
        Database.executeBatch(new WrikeDeploymentBatchJob());
        WrikeDeploymentBatchJob testShareRecords = new WrikeDeploymentBatchJob();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Scheduled', sch, testShareRecords);
        Test.stopTest();
        
        List<AccountShare> newAccountShares = [
            SELECT Id 
            FROM AccountShare 
            WHERE UserOrGroupId =: portalUser.Id 
            AND AccountId =: deployment.Account__c
        ];
        List<Subscription__Share> newSubscriptionsShares = [
            SELECT Id 
            FROM Subscription__Share 
            WHERE UserOrGroupId =: portalUser.Id 
            AND ParentId =: deployment.Subscription__c
        ];
        System.assertEquals(newAccountShares.size(), 0);
        System.assertEquals(newSubscriptionsShares.size(), 0);
    }
    
    @IsTest static void testDeploymentUpdate() {    
        Account acct = [SELECT Id FROM Account WHERE Name='Test Account'];
        Subscription__c sub = [SELECT Id FROM Subscription__c WHERE Name='Test Subscription'];
        User portalUser = [SELECT Id FROM User WHERE Email='test@gmail.com'];
        final Deployment__c deployment = new Deployment__c(
            Name = 'Test Deployment 1',
            Subscription__c = sub.Id,
            Account__c = acct.Id,
            OwnerId = portalUser.Id  
        );
        
        insert deployment;
        Test.startTest();
        User portalUser2 = [SELECT Id FROM User WHERE Email='testing@gmail.com'];
        deployment.OwnerId = portalUser2.Id;
        update deployment;
        Database.executeBatch(new WrikeDeploymentBatchJob());
        WrikeDeploymentBatchJob testShareRecords = new WrikeDeploymentBatchJob();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Scheduled', sch, testShareRecords);
        Test.stopTest();
        
        List<AccountShare> oldAccountShares = [
            SELECT Id 
            FROM AccountShare 
            WHERE UserOrGroupId =: portalUser.Id 
            AND AccountId =: deployment.Account__c
        ];
        List<Subscription__Share> oldSubscriptionsShares = [
            SELECT Id 
            FROM Subscription__Share 
            WHERE UserOrGroupId =: portalUser.Id 
            AND ParentId =: deployment.Subscription__c
        ];
        System.assertEquals(oldAccountShares.size(), 0);
        System.assertEquals(oldSubscriptionsShares.size(), 0);
        
        List<AccountShare> newAccountShares = [
            SELECT Id 
            FROM AccountShare 
            WHERE UserOrGroupId =: portalUser2.Id 
            AND AccountId =: deployment.Account__c
        ];
        List<Subscription__Share> newSubscriptionsShares = [
            SELECT Id 
            FROM Subscription__Share 
            WHERE UserOrGroupId =: portalUser2.Id 
            AND ParentId =: deployment.Subscription__c
        ];
        System.assertEquals(newAccountShares.size(), 1);
        System.assertEquals(newSubscriptionsShares.size(), 1);
    }
    
    @IsTest static void testMultipleDeployments() {
        Test.startTest();
        Account acct = [SELECT Id FROM Account WHERE Name='Test Account'];
        List<Subscription__c> sub = [SELECT Id FROM Subscription__c];
        List<User> portalUser = [SELECT Id FROM User];
        final Deployment__c deployment = new Deployment__c(
            Name = 'Test Deployment 1',
            Subscription__c = sub[0].Id,
            Account__c = acct.Id,
            OwnerId = portalUser[0].Id  
        );  
        insert deployment;
        
        final Deployment__c deployment2 = new Deployment__c(
            Name = 'Test Deployment 2',
            Subscription__c = sub[1].Id,
            Account__c = acct.Id,
            OwnerId = portalUser[1].Id  
        );  
        insert deployment2; 
        
        deployment.OwnerId = portalUser[1].Id;
        update deployment;
        WrikeDeploymentShareLogic.runOwnerRules(null,'Batch');
        WrikeDeploymentShareLogic.runOwnerRules(deployment.Id,'Current Deployment Record');
        deployment2.Subscription__c = sub[0].Id; 
        update deployment2;
        Database.executeBatch(new WrikeDeploymentBatchJob());
        WrikeDeploymentBatchJob testShareRecords = new WrikeDeploymentBatchJob();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Scheduled', sch, testShareRecords);
        Test.stopTest();    
        
        List<AccountShare> oldAccountSharesDeployment = [
            SELECT Id 
            FROM AccountShare 
            WHERE UserOrGroupId =: portalUser[0].Id 
            AND AccountId =: acct.Id
        ];
        List<Subscription__Share> oldSubscriptionsSharesDeployment = [
            SELECT Id 
            FROM Subscription__Share 
            WHERE UserOrGroupId =: portalUser[0].Id 
            AND ParentId =: sub[0].Id
        ];
        System.assertEquals(oldAccountSharesDeployment.size(), 0);
        System.assertEquals(oldSubscriptionsSharesDeployment.size(), 0);
        
        List<AccountShare> newAccountSharesDeployment = [
            SELECT Id 
            FROM AccountShare 
            WHERE UserOrGroupId =: portalUser[1].Id 
            AND AccountId =: acct.Id
        ];
        List<Subscription__Share> newSubscriptionsSharesDeployment = [
            SELECT Id 
            FROM Subscription__Share 
            WHERE UserOrGroupId =: portalUser[1].Id 
            AND ParentId =: sub[0].Id
        ];
        System.assertNotEquals(newAccountSharesDeployment.size(), 1);
        System.assertNotEquals(newSubscriptionsSharesDeployment.size(), 1);
        
        List<AccountShare> oldAccountSharesDeployment2 = [
            SELECT Id 
            FROM AccountShare 
            WHERE UserOrGroupId =: portalUser[1].Id 
            AND AccountId =: acct.Id
        ];
        List<Subscription__Share> oldSubscriptionsSharesDeployment2 = [
            SELECT Id 
            FROM Subscription__Share 
            WHERE UserOrGroupId =: portalUser[1].Id 
            AND ParentId =: sub[1].Id
        ];
        List<Subscription__Share> newSubscriptionsSharesDeployment2 = [
            SELECT Id 
            FROM Subscription__Share 
            WHERE UserOrGroupId =: portalUser[1].Id 
            AND ParentId =: sub[0].Id
        ];
        System.assertEquals(oldAccountSharesDeployment2.size(), 0);
        System.assertEquals(oldSubscriptionsSharesDeployment2.size(), 0);
        System.assertNotEquals(newSubscriptionsSharesDeployment2.size(), 1);  
    }  
}
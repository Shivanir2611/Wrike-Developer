@IsTest
public class WrikeDeploymentEmailHandlerTest {
    
    @testSetup static void dataCreation(){
        Contact newContact = new Contact(
            LastName = 'Test Last Name',
            FirstName = 'Test First Name',
            Email = 'testemailservices@email.com'
        );
        insert newContact;
        
        Account newAccount = new Account(
            Name = 'Test Account',
            Email_Domain__c = 'gsu.edu'
        );
        insert newAccount;
    }
    
    @IsTest static void taskCreationTest(){
        Contact newContact = [
            SELECT Id, Email
            FROM Contact
            WHERE LastName = 'Test Last Name'
        ];
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        List<String> emails = new List<String>{'testemailservices@email.com', 'testemailservices@gsu.edu', 'testemailservices@ksu.edu'};
        email.subject = 'Test Deployment Services';
        email.fromname = 'FirstName LastName';
        email.fromAddress = 'test@gmail.com'; 
        email.plainTextBody = 'This is a test Deployment services notice';
        email.toAddresses = emails;
        
        WrikeDeploymentEmailHandler emailProcess = new WrikeDeploymentEmailHandler();
        
        Test.startTest();
        emailProcess.handleInboundEmail(email, env);
        Test.stopTest();
        
        Task contactTask = [
            SELECT Id, CallDisposition, Status, Type, TaskSubtype, ActivityDate, Subject, Description, OwnerId, Priority, Sender__c, WhatId, WhoId
            FROM Task
            WHERE WhoId =: newContact.Id
        ];
        
        System.assertNotEquals(null, contactTask.Id);
        System.assertEquals('Follow Up', contactTask.CallDisposition);
        System.assertEquals('Completed', contactTask.Status);
        System.assertEquals('Email', contactTask.Type);
        System.assertEquals('Email', contactTask.TaskSubtype);
        System.assertEquals(System.today(), contactTask.ActivityDate);
        System.assertEquals('Test Deployment Services', contactTask.Subject);
        System.assertEquals('This is a test Deployment services notice', contactTask.Description);
        System.assertEquals('005F0000003lL5rIAE', String.valueOf(contactTask.OwnerId));
        System.assertEquals('Normal', contactTask.Priority);
        System.assertEquals(newContact.Id, contactTask.WhoId);
        System.assertEquals(null, contactTask.WhatId);
        System.assertEquals('test@gmail.com', contactTask.Sender__c);
        
        Account newAccount = [
            SELECT Id, Email_Domain__c
            FROM Account
            WHERE Name = 'Test Account'
        ];
        
        Task accountTask = [
            SELECT Id, CallDisposition, Status, Type, TaskSubtype, ActivityDate, Subject, Description, OwnerId, Priority, Sender__c, WhatId, WhoId
            FROM Task
            WHERE WhatId =: newAccount.Id
        ];
        
        System.assertNotEquals(null, accountTask.Id);
        System.assertEquals('Follow Up', accountTask.CallDisposition);
        System.assertEquals('Completed', accountTask.Status);
        System.assertEquals('Email', accountTask.Type);
        System.assertEquals('Email', accountTask.TaskSubtype);
        System.assertEquals(System.today(), accountTask.ActivityDate);
        System.assertEquals('Test Deployment Services', accountTask.Subject);
        System.assertEquals('This is a test Deployment services notice', accountTask.Description);
        System.assertEquals('005F0000003lL5rIAE', String.valueOf(accountTask.OwnerId));
        System.assertEquals('Normal', accountTask.Priority);
        System.assertEquals(newAccount.Id, accountTask.WhatId);
        System.assertEquals(null, accountTask.WhoId);
        System.assertEquals('test@gmail.com', accountTask.Sender__c);
        
        Task noRelationTask = [
            SELECT Id, CallDisposition, Status, Type, TaskSubtype, ActivityDate, Subject, Description, OwnerId, Priority, Sender__c, WhatId, WhoId
            FROM Task
            WHERE Subject = 'Test Deployment Services'
            AND WhatId = null
            AND WhoId = null
        ];
        
        System.assertEquals('Follow Up', noRelationTask.CallDisposition);
        System.assertEquals('Completed', noRelationTask.Status);
        System.assertEquals('Email', noRelationTask.Type);
        System.assertEquals('Email', noRelationTask.TaskSubtype);
        System.assertEquals(System.today(), noRelationTask.ActivityDate);
        System.assertEquals('Test Deployment Services', noRelationTask.Subject);
        System.assertEquals('This is a test Deployment services notice', noRelationTask.Description);
        System.assertEquals('005F0000003lL5rIAE', String.valueOf(noRelationTask.OwnerId));
        System.assertEquals('Normal', noRelationTask.Priority);
        System.assertEquals(null, noRelationTask.WhatId);
        System.assertEquals(null, noRelationTask.WhoId);
        System.assertEquals('test@gmail.com', noRelationTask.Sender__c);
    }
}
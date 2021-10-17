@IsTest
public class TaskTriggerTest {

    @TestSetup
    static void setup() {
        TestUtils.insertAndAssert(TestDataFactory.createLead());
        TestUtils.insertAndAssert(TestDataFactory.createAccount());
        TestUtils.insertAndAssert(TestDataFactory.createContact());
    }

    @IsTest
    static void testEventCompleted() {
        final Event_Data__c eventData = new Event_Data__c();
        insert eventData;
        final Account account = new Account(Name = 'Test Account', Event_Data__c = eventData.Id);
        insert account;
        final Event__c event = new Event__c(
            Event_Data__c = eventData.Id,
            Account__c = account.Id,
            Type__c = 'QuoteRequest'
        ); 
        insert event;
        final Task task = new Task(
            WhatId = account.Id,
            Status = 'Open',
            Subject = 'Test Task1',
            ActivityDate = Date.today(),
            Event__c = event.Id
        );
        insert task;
        Test.startTest();
        task.Status = 'Completed';
        update task;
        Test.stopTest();
        System.assertEquals('Completed', [SELECT Status__c FROM Event__c WHERE Id = :event.Id].Status__c);     
    }

    @IsTest
    static void testNoActivityCreated() {
        final Lead lead = TestUtils.findLead();
        final Contact testContact = TestUtils.findContact();

        TestUtils.insertAndAssert(new List<Task>{
            TestDataFactory.createTask(lead.Id, null, 'Email', 'Email', null, null, 'taskId'),
            TestDataFactory.createTask(testContact.Id, null, 'Email', 'Email', null, null, 'taskId')
        });

        final List<Activity__c> leadActivities = TestUtils.findActivityForLead(lead.Id);
        System.assert(leadActivities.isEmpty(), 'No activities should be created.');
        final List<Activity__c> contactActivities = TestUtils.findActivityForContact(testContact.Id);
        System.assert(contactActivities.isEmpty(), 'No activities should be created.');
    }
    
    @IsTest
    static void testOutboundCallCreated() {
        final Lead lead = TestUtils.findLead();
        final Contact testContact = TestUtils.findContact();

        Task leadTask = TestDataFactory.createTask(lead.Id, null, 'Call', 'Outbound Call', 60, 'Outbound');
        Task contactTask = TestDataFactory.createTask(testContact.Id, null, 'Call', 'Outbound Call', 60, 'Outbound');
        TestUtils.insertAndAssert(new List<Task>{leadTask, contactTask});

        final List<Activity__c> leadActivities = TestUtils.findActivityForLead(lead.Id);
        System.assertEquals(1, leadActivities.size());
        System.assertEquals('Call', leadActivities.get(0).Type__c);
        System.assertEquals('Outbound', leadActivities.get(0).Sub_Type__c);
        System.assertEquals('Outbound Call', leadActivities.get(0).Subject__c);
        System.assertEquals(60, leadActivities.get(0).Duration__c);
        System.assertEquals(leadTask.Id, leadActivities.get(0).Task_Id__c);

        final List<Activity__c> contactActivities = TestUtils.findActivityForContact(testContact.Id);
        System.assertEquals(1, contactActivities.size());
        System.assertEquals('Call', contactActivities.get(0).Type__c);
        System.assertEquals('Outbound', contactActivities.get(0).Sub_Type__c);
        System.assertEquals('Outbound Call', contactActivities.get(0).Subject__c);
        System.assertEquals(60, contactActivities.get(0).Duration__c);
        System.assertEquals(contactTask.Id, contactActivities.get(0).Task_Id__c);
    }
    
    @IsTest
    static void testInboundCallCreated() {
        final Lead lead = TestUtils.findLead();
        final Contact testContact = TestUtils.findContact();
        Task leadTask = TestDataFactory.createTask(lead.Id, null, 'Call', 'Inbound Call', 60, 'Inbound');
        Task contactTask = TestDataFactory.createTask(testContact.Id, null, 'Call', 'Inbound Call', 60, 'Inbound');
        TestUtils.insertAndAssert(new List<Task>{leadTask, contactTask});

        final List<Activity__c> leadActivities = TestUtils.findActivityForLead(lead.Id);
        System.assertEquals(1, leadActivities.size());
        System.assertEquals('Call', leadActivities.get(0).Type__c);
        System.assertEquals('Inbound', leadActivities.get(0).Sub_Type__c);
        System.assertEquals('Inbound Call', leadActivities.get(0).Subject__c);
        System.assertEquals(60, leadActivities.get(0).Duration__c);
        System.assertEquals(leadTask.Id, leadActivities.get(0).Task_Id__c);

        final List<Activity__c> contactActivities = TestUtils.findActivityForContact(testContact.Id);
        System.assertEquals(1, contactActivities.size());
        System.assertEquals('Call', contactActivities.get(0).Type__c);
        System.assertEquals('Inbound', contactActivities.get(0).Sub_Type__c);
        System.assertEquals('Inbound Call', contactActivities.get(0).Subject__c);
        System.assertEquals(60, contactActivities.get(0).Duration__c);
        System.assertEquals(contactTask.Id, contactActivities.get(0).Task_Id__c);
    }
    
    @IsTest
    static void testOutboundEmailCreated() {
        final Lead lead = TestUtils.findLead();
        final Contact testContact = TestUtils.findContact();

        Task leadTask = TestDataFactory.createTask(lead.Id, null, 'Email', '[Outreach] [Email] [Out] Test', null, null);
        Task contactTask = TestDataFactory.createTask(testContact.Id, null, 'Email', '[Outreach] [Email] [Out] Test', null, null);
        TestUtils.insertAndAssert(new List<Task>{leadTask, contactTask});

        final List<Activity__c> leadActivities = TestUtils.findActivityForLead(lead.Id);
        System.assertEquals(1, leadActivities.size());
        System.assertEquals('Email', leadActivities.get(0).Type__c);
        System.assertEquals('Outbound', leadActivities.get(0).Sub_Type__c);
        System.assertEquals(leadTask.Subject, leadActivities.get(0).Subject__c);
        System.assertEquals(leadTask.Id, leadActivities.get(0).Task_Id__c);

        final List<Activity__c> contactActivities = TestUtils.findActivityForContact(testContact.Id);
        System.assertEquals(1, contactActivities.size());
        System.assertEquals('Email', contactActivities.get(0).Type__c);
        System.assertEquals('Outbound', contactActivities.get(0).Sub_Type__c);
        System.assertEquals(contactTask.Subject, contactActivities.get(0).Subject__c);
        System.assertEquals(contactTask.Id, contactActivities.get(0).Task_Id__c);
    }
    
    @IsTest
    static void testInboundEmailCreated() {
        final Lead lead = TestUtils.findLead();
        final Contact testContact = TestUtils.findContact();

        Task leadTask = TestDataFactory.createTask(lead.Id, null, 'Email', '[Outreach] [Email] [In] Test', null, null);
        Task contactTask = TestDataFactory.createTask(testContact.Id, null, 'Email', '[Outreach] [Email] [In] Test', null, null);
        TestUtils.insertAndAssert(new List<Task>{leadTask, contactTask});

        final List<Activity__c> leadActivities = TestUtils.findActivityForLead(lead.Id);
        System.assertEquals(1, leadActivities.size());
        System.assertEquals('Email', leadActivities[0].Type__c);
        System.assertEquals('Inbound', leadActivities[0].Sub_Type__c);
        System.assertEquals(leadTask.Subject, leadActivities[0].Subject__c);
        System.assertEquals(leadTask.Id, leadActivities[0].Task_Id__c);

        final List<Activity__c> contactActivities = TestUtils.findActivityForContact(testContact.Id);
        System.assertEquals(1, contactActivities.size());
        System.assertEquals('Email', contactActivities[0].Type__c);
        System.assertEquals('Inbound', contactActivities[0].Sub_Type__c);
        System.assertEquals(contactTask.Subject, contactActivities[0].Subject__c);
        System.assertEquals(contactTask.Id, contactActivities[0].Task_Id__c);
    }
}
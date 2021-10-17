@IsTest
public class OpportunityContactRoleTriggerTest {
    
    @IsTest
    static void testTaskCreation(){
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(contact);
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, contact.Id);
        TestUtils.insertAndAssert(opportunity);
        final Task task = new Task(
            WhoId = contact.Id,
            Status = 'Open',
            Subject = 'Test Task1',
            ActivityDate = Date.today(),
            Type = 'Email'
        );
        insert task;
        
        Test.startTest();
        final OpportunityContactRole oppContactRole = new OpportunityContactRole(
            ContactId = contact.Id,
            OpportunityId = opportunity.Id
        );
        insert oppContactRole;
        Test.stopTest();
        
        final Task opportunityTask = [
            SELECT Id, WhatId 
            FROM Task 
            WHERE WhoId =: contact.Id
        ];
        
        System.assertEquals(opportunityTask.WhatId, opportunity.Id);
    }
    
    @IsTest
    static void testMultipleOppCase(){
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(contact);
        final Opportunity opportunity1 = TestDataFactory.createOpportunity(account.Id, contact.Id);
        TestUtils.insertAndAssert(opportunity1);
        final Opportunity opportunity2 = TestDataFactory.createOpportunity(account.Id, contact.Id);
        TestUtils.insertAndAssert(opportunity2);
        
        Test.setCreatedDate(opportunity2.Id, DateTime.newInstance(2020,3,3));
        update opportunity2;
        
        final Task task = new Task(
            WhoId = contact.Id,
            Status = 'Open',
            Subject = 'Test Task1',
            ActivityDate = Date.today(),
            Type = 'Email'
        );
        insert task;
        
        Test.startTest();
        final OpportunityContactRole oppContactRole1 = new OpportunityContactRole(
            ContactId = contact.Id,
            OpportunityId = opportunity1.Id
        );
        insert oppContactRole1;
        final OpportunityContactRole oppContactRole2 = new OpportunityContactRole(
            ContactId = contact.Id,
            OpportunityId = opportunity2.Id
        );
        insert oppContactRole2;
        Test.stopTest();
        
        final Task opportunityTask = [
            SELECT Id, WhatId 
            FROM Task 
            WHERE WhoId =: contact.Id
        ];
        
        System.assertEquals(opportunityTask.WhatId, opportunity1.Id);
    }
    
    @IsTest
    static void testTaskAfterCreation(){
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(contact);
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, contact.Id);
        TestUtils.insertAndAssert(opportunity);
        final OpportunityContactRole oppContactRole = new OpportunityContactRole(
            ContactId = contact.Id,
            OpportunityId = opportunity.Id
        );
        insert oppContactRole;
        final Task task = new Task(
            Status = 'Open',
            Subject = 'Test Task1',
            ActivityDate = Date.today(),
            Type = 'Email'
        );
        insert task;
        
        Test.startTest();
        task.WhoId = contact.Id;
        update task;
        Test.stopTest();
        
        final Task opportunityTask = [
            SELECT Id, WhatId 
            FROM Task 
            WHERE WhoId =: contact.Id
        ];
        
    	System.assertEquals(opportunityTask.WhatId, opportunity.Id);
    }   
}
@IsTest
public class RenewalOpportunityUpdateJobTest {
    private static final String TestUserEmail = 'test.cpq.renewal@team.wrike.com';

    @TestSetup
    static void setup() {
        TestUtils.createUser('cpq.renewal', TestUserEmail, 'System Administrator');
    }

    @IsTest
    static void testOpportunityUpdate() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Opportunity oldOpportunity = TestDataFactory.createOpportunity(account.Id, 123);
        oldOpportunity.AE_Sourced__c = true;
        oldOpportunity.Forecast__c = true;
        oldOpportunity.Manager_Notes__c = 'Manager notes';
        oldOpportunity.NextStep = 'Next step data';
        oldOpportunity.Next_Step__c = 'Next step summary data';
        oldOpportunity.Wrike_Task_URL__c = 'https://www.wrike.com/open.htm?id=12345';
        oldOpportunity.OwnerId = TestUtils.getUserByEmail(TestUserEmail)[0].Id;
        oldOpportunity.StageName = '1-Connect';
        oldOpportunity.Type = 'Renewal';
        oldOpportunity.Contract_Start_Date__c = Date.today().addDays(30);
        insert oldOpportunity;
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        insert contact;
        final OpportunityContactRole contactRole = TestDataFactory.createOpportunityContactRole(contact.Id, oldOpportunity.Id);
        insert contactRole;
        insert new Note(
            Title = 'Test Note',
            ParentId = oldOpportunity.Id,
            Body = 'Test Note Body'
        );
        final Task openTask = new Task(
            Subject = 'Open Task',
            WhatId = oldOpportunity.Id,
            Status = 'Open',
            ActivityDate = Date.today(),
            Type = 'Email'
        );
        insert openTask;
        final Task completedTask = new Task(
            Subject = 'Completed Task',
            WhatId = oldOpportunity.Id,
            Status = 'Completed',
            ActivityDate = Date.today(),
            Type = 'Email'
        );
        insert completedTask;

        final Contract contract = new Contract(
                Wrike_Account_ID__c = 123,
                AccountId = account.Id,
                StartDate = Date.today().addDays(-1),
                EndDate = Date.today().addMonths(12),
                SBQQ__RenewalTerm__c = 12,
                RecordTypeId = SchemaUtils.getRecordTypeIdByName(Contract.getSObjectType(), 'CPQ Contracts')
        );
        insert contract;
        final Opportunity cpqOpportunity = TestDataFactory.createOpportunity(account.Id, 123);
        cpqOpportunity.StageName = 'Need to Contact';
        cpqOpportunity.SBQQ__RenewedContract__c = contract.Id;
        cpqOpportunity.Type = 'Renewal';
        insert cpqOpportunity;

        Test.startTest();
        Database.executeBatch(new RenewalOpportunityUpdateJob(), 1);
        Test.stopTest();
        final Opportunity updatedOldOpp = [
                SELECT StageName, Rejected_pass_reason__c
                FROM Opportunity
                WHERE Id = :oldOpportunity.Id
        ];
        System.assertEquals('Reject', updatedOldOpp.StageName);
        System.assertEquals('Duplicate', updatedOldOpp.Rejected_pass_reason__c);
        final Opportunity updatedOpp = [
                SELECT Id,
                       StageName,
                       AE_Sourced__c,
                       Manager_Notes__c,
                       NextStep,
                       Next_Step__c,
                       Forecast__c,
                       Wrike_Task_URL__c,
                       Owner.Email,
                       ZuoraRenewalOpportunity__c,
                       (SELECT Title, Body FROM Notes),
                       (SELECT ContactId FROM OpportunityContactRoles),
                       (SELECT Id FROM OpenActivities),
                       (SELECT Id FROM ActivityHistories)
                FROM Opportunity
                WHERE Id = :cpqOpportunity.Id
        ];
        System.assertEquals('1-Connect', updatedOpp.StageName);
        System.assertEquals(TestUserEmail, updatedOpp.Owner.Email);
        System.assertEquals(oldOpportunity.Id, updatedOpp.ZuoraRenewalOpportunity__c);
        System.assertEquals(true, updatedOpp.AE_Sourced__c);
        System.assertEquals(true, updatedOpp.Forecast__c);
        System.assertEquals('Manager notes', updatedOpp.Manager_Notes__c);
        System.assertEquals('Next step data', updatedOpp.NextStep);
        System.assertEquals('Next step summary data', updatedOpp.Next_Step__c);
        System.assertEquals('https://www.wrike.com/open.htm?id=12345', updatedOpp.Wrike_Task_URL__c);
        System.assertEquals(false, updatedOpp.Notes.isEmpty());
        System.assertEquals('Test Note', updatedOpp.Notes[0].Title);
        System.assertEquals('Test Note Body', updatedOpp.Notes[0].Body);
        System.assertEquals(false, updatedOpp.OpportunityContactRoles.isEmpty());
        System.assertEquals(contactRole.ContactId, updatedOpp.OpportunityContactRoles[0].ContactId);
        System.assertEquals(false, updatedOpp.OpenActivities.isEmpty());
        System.assertEquals(openTask.Id, updatedOpp.OpenActivities[0].Id);
        System.assertEquals(false, updatedOpp.ActivityHistories.isEmpty());
        System.assertEquals(completedTask.Id, updatedOpp.ActivityHistories[0].Id);
    }
}
@IsTest
public class LeadSnapshotProcessCreationTest {

    @IsTest
    public static void testLeadSnapshotCreated() {

        final QueueSobject queueSObject = [SELECT QueueId FROM QueueSobject WHERE SobjectType = 'Lead' LIMIT 1];
        final Group queue = [SELECT Id FROM Group WHERE Id = :queueSObject.QueueId LIMIT 1];
               
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 13245768,
            Tasks_Created__c = 10,
            Invitations__c = 10,
            Activities__c = 10,
            License_Name__c = 'Free'
        );
        insert wrikeData;

        final Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            LeadSource = 'Web',
            Lead_Sub_Source__c = 'eBook',
            Wrike_Account_Id__c = 13245768,
            OwnerId = queue.Id,
            NumberOfEmployees = 100,
            Wrike_Data__c = wrikeData.Id
        );
        insert lead;
        System.assert([SELECT Id FROM Lead_Snapshot__c WHERE Lead__c = :lead.Id].isEmpty(),
                'Lead snapshot created without assignment to active user');

        final User activeUser = TestUtils.getActiveUser();

        lead.OwnerId = activeUser.Id;
        update lead;

        final List<Lead_Snapshot__c> snapshots = [SELECT Id, Assigned_To__c, Activity_Stream__c, Analytics_score__c,
                Employee_Size__c, Invited_Users__c, LeadSource__c, Type__c,
                Wrike_Tasks_Created__c, Wrike_License_Name__c, Wrike_Account_Id__c
                FROM Lead_Snapshot__c WHERE Lead__c = :lead.Id];
        System.assert(!snapshots.isEmpty(), 'Lead snapshot not created');
        System.assertEquals(1, snapshots.size(), 'More than one Lead snapshots created: ' + snapshots.size());

        final Lead_Snapshot__c snapshot = snapshots.get(0);
        final Lead updatedLead = [SELECT Id, OwnerId, Activity_Stream__c, Analytics_score__c,
                Employee_Size__c, Invited_Users__c, LeadSource,
                Wrike_Tasks_Created__c, Wrike_License_Name__c, Wrike_Account_Id__c
                FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(updatedLead.OwnerId, snapshot.Assigned_To__c);
        System.assertEquals(updatedLead.Activity_Stream__c, snapshot.Activity_Stream__c);
        System.assertEquals(updatedLead.Analytics_score__c, snapshot.Analytics_score__c);
        System.assertEquals(updatedLead.Employee_Size__c, snapshot.Employee_Size__c);
        System.assertEquals(updatedLead.Invited_Users__c, snapshot.Invited_Users__c);
        System.assertEquals(updatedLead.LeadSource, snapshot.LeadSource__c);
        System.assertEquals(updatedLead.Wrike_Tasks_Created__c, snapshot.Wrike_Tasks_Created__c);
        System.assertEquals(updatedLead.Wrike_License_Name__c, snapshot.Wrike_License_Name__c);
        System.assertEquals(updatedLead.Wrike_Account_Id__c, snapshot.Wrike_Account_Id__c);
        System.assertEquals('Assignment', snapshot.Type__c);

        lead.OwnerId = queue.Id;
        update lead;
        System.assertEquals(1, [SELECT Id FROM Lead_Snapshot__c WHERE Lead__c = :lead.Id].size(),
                'Lead snapshot created after assignment to queue');
    }
}
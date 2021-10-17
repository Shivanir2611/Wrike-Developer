@IsTest
public class LeadRecycleFlowJobTest {
    
    @IsTest
    static void testLeadRecycleFlowUpdate() {
        final User testUser = TestUtils.getActiveUser();
        final Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            LeadSource = 'Web',
            Lead_Sub_Source__c = 'eBook',
            CountryCode = 'US',
            Status = LeadService.RECYCLE_STATUS,
            Recycle_Reasons__c = 'Recycle Workflow',
            Follow_Up_Timeframe__c = 'No Follow Up',
            OwnerId = testUser.Id
        );
        insert testLead;
        
        Test.startTest();
        new LeadRecycleFlowJob().execute(null, new List<Lead>{testLead});
        Test.stopTest();
        
        final Lead updatedLead = [
            SELECT Id, QueueList__c, Last_Recycled_Date__c
            FROM Lead
            WHERE Id =: testLead.Id
        ];
        
        System.assertEquals('Recycled Lead Queue', updatedLead.QueueList__c);
        System.assertNotEquals(null, updatedLead.Last_Recycled_Date__c);
    }
}
@IsTest
public class LeadWorkflowJobTest {

    @IsTest
    public static void testLeadUpdated() {
        final Lead lead = TestDataFactory.createLead();
        TestUtils.insertAndAssert(lead);
        
        Test.startTest();
        Database.executeBatch(new LeadWorkflowJob());
        Test.stopTest();
        final Lead updateLead = [
            SELECT Last_Evaluated_Date__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assert(updateLead.Last_Evaluated_Date__c != null, 'Last Evaluated_Date was not set.');
    }
    

    @IsTest
    public static void testRecycledLeadNotUpdated() {
        final Lead lead = TestDataFactory.createLead();
        lead.Status = LeadService.RECYCLE_STATUS;
        lead.OwnerId = WrikeConstants.RLQ_ID;
        lead.Recycle_Reasons__c = 'Automated Recycle';
        lead.Follow_Up_Timeframe__c = '15 Days';
        TestUtils.insertAndAssert(lead);
        
        Test.startTest();
        Database.executeBatch(new LeadWorkflowJob());
        Test.stopTest();
        final Lead updateLead = [
            SELECT Last_Evaluated_Date__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assert(updateLead.Last_Evaluated_Date__c == null, 'Last Evaluated_Date should be blank.');
    }
}
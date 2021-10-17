@IsTest
public class LeadRecycleJobTest {
    
    @IsTest
    static void testLeadOwnerUpdated() {
        final Lead testLead = TestDataFactory.createLead();
        TestUtils.insertAndAssert(testLead);
        
        Test.startTest();
        new LeadRecycleJob().execute(null, new List<Lead>{testLead});
        Test.stopTest();
        
        Lead updatedLead = TestUtils.findLeadById(testLead.Id);
        System.assertEquals(WrikeConstants.RLQ_ID, updatedLead.OwnerId);
    }
}
@IsTest
public class OpportunityEmailServiceTest {
    
    @IsTest
    static void testEmailUtility(){
        final Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = '0-MQL',
            CloseDate = Date.today(),
            Wrike_Account_Id__c = 1
        );
        insert opp;
        final List<Id> oppIds = new List<Id>{opp.Id};
        
        Test.startTest();
        OpportunityEmailService.sendNotificationEmail(oppIds);
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        
        System.assertEquals(1, emailInvocations, 'An email should be sent');
    }
}
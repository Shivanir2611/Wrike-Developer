@IsTest
public class OpportunityUpdateJobTest {
    
    @IsTest
    static void setup() {
        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);
        
        Opportunity testOpportunity1 = TestDataFactory.createOpportunity(testAccount.Id, 123);
        TestUtils.insertAndAssert(testOpportunity1);
        
        testOpportunity1.StageName = 'Closed Won - Pending';
        TestUtils.updateAndAssert(testOpportunity1);
        
        Quote__c quote1 = TestDataFactory.createQuote(testOpportunity1.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(quote1);
        
        quote1.Status__c = WrikeQuote.Status.SENT.name();
        TestUtils.updateAndAssert(quote1);
        
        Test.startTest();
        Database.executeBatch(new OpportunityUpdateJob());
        Test.stopTest();
        
        final Opportunity updatedOpp = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE Id =: testOpportunity1.Id
        ];
        System.assertEquals(updatedOpp.StageName, 'Closed Won');
    }
}
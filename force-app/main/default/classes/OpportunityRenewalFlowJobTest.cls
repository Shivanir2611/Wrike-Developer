@IsTest
public class OpportunityRenewalFlowJobTest {
    
    @IsTest
    static void testOpportunityRenewalFlowUpdate() {
        final User testUser = TestUtils.getActiveUser();
        
        final Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);
        
        final Contact testContact = TestDataFactory.createContact(testAccount.Id, 'Test1', 'testcontact@address.com');
        TestUtils.insertAndAssert(testContact);
        
        final Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 1);
        testOpportunity.StageName = 'Closed Won';
        TestUtils.insertAndAssert(testOpportunity);
        
        final Partner__c testPartner = new Partner__c();
        testPartner.Partner_Contact__c = testContact.Id;
        testPartner.Opportunity__c = testOpportunity.Id;
        testPartner.Partner__c = testAccount.Id;
        testPartner.Engagement_Level__c = 'Reseller';
        testPartner.Partner_Manager__c = testUser.Id;
        insert testPartner;
		
        final Opportunity testRenewalOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 1);
        testRenewalOpportunity.OwnerId = WrikeConstants.SF_ADMIN_ID;
        testRenewalOpportunity.Type = 'Renewal';
        TestUtils.insertAndAssert(testRenewalOpportunity);
        
        Test.startTest();
        new OpportunityRenewalFlowJob().execute(null, new List<Opportunity>{testRenewalOpportunity});
        Test.stopTest();
        
        final Opportunity updatedOpportunity = [
            SELECT Id, Renewal_Partner_Manager__c
            FROM Opportunity
            WHERE Id =: testRenewalOpportunity.Id
        ];
        final List<Partner__c> updatedPartner = [
            SELECT Id
            FROM Partner__c
            WHERE Opportunity__c =: testRenewalOpportunity.Id
        ];
        
        System.assertEquals(false, updatedPartner.isEmpty());
        System.assertNotEquals(null, updatedOpportunity.Renewal_Partner_Manager__c);
    }
}
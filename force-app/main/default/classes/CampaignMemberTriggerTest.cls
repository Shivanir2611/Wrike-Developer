@IsTest
public class CampaignMemberTriggerTest {
    
    @TestSetup
    static void setup() {
        TestUtils.insertAndAssert(new Settings__c(DisableCampaignMemberBatchJob__c = false));
        
        final Lead lead = TestDataFactory.createLead(null, 'testlead@address.com');
        TestUtils.insertAndAssert(lead);
        
        final Campaign campaign = new Campaign(
            Name = 'Test Campaign',
            IsActive = true
        );
        insert campaign;
		        
        final CampaignMember campaignMember = new CampaignMember(
            CampaignId = campaign.Id,
            Status = 'Sent',
            LeadId = lead.Id
        );
        insert campaignMember;
    }
    
    @IsTest
    static void testCampaignMemberInsert() {
        final EmailData__c emailData = [SELECT Email__c FROM EmailData__c WHERE Email__c = 'testlead@address.com'];
        final CampaignMember campaignMember = [SELECT Id FROM CampaignMember WHERE Status='Sent'];
        
        final EmailData__c updatedEmailData = [
            SELECT Id, Most_Recent_Campaign__c, Campaign_Member_Status__c
            FROM EmailData__c
            WHERE Email__c =: emailData.Email__c
        ];
        System.assertEquals(updatedEmailData.Most_Recent_Campaign__c, 'Test Campaign');
        System.assertEquals(updatedEmailData.Campaign_Member_Status__c, 'Sent');  
    }
    
    @IsTest
    static void testCampaignMemberUpdate() {
        final EmailData__c emailData = [SELECT Email__c FROM EmailData__c WHERE Email__c = 'testlead@address.com'];
        final CampaignMember campaignMember = [SELECT Id FROM CampaignMember WHERE Status='Sent'];
        
        campaignMember.Status = 'Responded';
        update campaignMember;
        
        final EmailData__c updatedEmailData = [
            SELECT Id, Most_Recent_Campaign__c, Campaign_Member_Status__c
            FROM EmailData__c
            WHERE Email__c =: emailData.Email__c
        ];
        System.assertEquals(updatedEmailData.Most_Recent_Campaign__c, 'Test Campaign');
        System.assertEquals(updatedEmailData.Campaign_Member_Status__c, 'Responded');  
    }
}
@IsTest
public class LeadCampaignsControllerTest {

    @IsTest
    static void testLeadCampaignsUpdate(){
    	final Campaign newCampaign = new Campaign(
            Name = 'Low Touch Program',
            IsActive = true
        );
        insert newCampaign;
        
        final Lead lead = TestDataFactory.createLead();
        lead.Email = 'testemail@address.com';
        TestUtils.insertAndAssert(lead);
        
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testemail@address.com');
        TestUtils.insertAndAssert(contact);
        
        final CampaignMember newLeadCampaignMember = new CampaignMember(
            CampaignId = newCampaign.Id,
            LeadId = lead.Id
        );
        insert newLeadCampaignMember;
        
        final CampaignMember newContactCampaignMember = new CampaignMember(
            CampaignId = newCampaign.Id,
            ContactId = contact.Id
        );
        insert newContactCampaignMember;
        
        Test.startTest();
        List<CampaignMember> relatedCampaignMemberList = LeadCampaignsController.getCampaignMembers(lead.Id);
        Test.stopTest();
        
        System.assertEquals(false, relatedCampaignMemberList.isEmpty());
    }
}
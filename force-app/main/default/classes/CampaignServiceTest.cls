@IsTest
public class CampaignServiceTest {

    @IsTest
    static void testLeadUpdate() {
    	final Campaign newCampaign = new Campaign(
            Name = 'Low Touch Program',
            IsActive = true
        );
        insert newCampaign;
        
        final Lead lead = TestDataFactory.createLead();
        TestUtils.insertAndAssert(lead);
        
        Test.startTest();
        lead.Cold_Email_Status__c = 'Replied';
        lead.Cold_Email_Sequence__c = 'Low Touch Program';
        TestUtils.updateAndAssert(lead);
        Test.stopTest();

        final CampaignMember memberRecord = [SELECT Id, LeadId, ContactId FROM CampaignMember WHERE CampaignId =: newCampaign.Id];
        
        System.assertEquals(memberRecord.LeadId, lead.Id);
        System.assertEquals(memberRecord.ContactId, null);
    }
    
    @IsTest
    static void testContactUpdate() {
        final Campaign newCampaign = new Campaign(
            Name = 'Demo Requests & Inquiries To Sales',
            IsActive = true
        );
        insert newCampaign;
        
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(contact);
        
        Test.startTest();
        contact.Cold_Email_Status__c = 'Replied';
        contact.Cold_Email_Sequence__c = 'Demo Requests & Inquiries To Sales';
        TestUtils.updateAndAssert(contact);
        Test.stopTest();

        final CampaignMember memberRecord = [SELECT Id, LeadId, ContactId FROM CampaignMember WHERE CampaignId =: newCampaign.Id];
        
        System.assertEquals(memberRecord.ContactId, contact.Id);
        System.assertEquals(memberRecord.LeadId, null);
    }
    
    @IsTest
    static void testExistingLeadUpdate(){
    	final Lead lead = TestDataFactory.createLead();
        TestUtils.insertAndAssert(lead);
        
        final Campaign newCampaign = new Campaign(
            Name = 'Low Touch Program',
            IsActive = true
        );
        insert newCampaign;
        
        final CampaignMember newCampaignMember = new CampaignMember(
            CampaignId = newCampaign.Id,
            LeadId = lead.Id
        );
        insert newCampaignMember;
        
        Test.startTest();
        lead.Cold_Email_Status__c = 'Replied';
        lead.Cold_Email_Sequence__c = 'Low Touch Program';
        TestUtils.updateAndAssert(lead);
        Test.stopTest();

        final List<CampaignMember> memberRecordList = [SELECT Id, LeadId, ContactId FROM CampaignMember WHERE CampaignId =: newCampaign.Id];
        
        System.assertEquals(memberRecordList.size(), 1);
        System.assertEquals(memberRecordList[0].LeadId, lead.Id);
        System.assertEquals(memberRecordList[0].ContactId, null);
    }
    
    @IsTest
    static void testExistingContactUpdate() {
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(contact);
        
        final Campaign newCampaign = new Campaign(
            Name = 'Demo Requests & Inquiries To Sales',
            IsActive = true
        );
        insert newCampaign;
        
        final CampaignMember newCampaignMember = new CampaignMember(
            CampaignId = newCampaign.Id,
            ContactId = contact.Id
        );
        insert newCampaignMember;
        
        Test.startTest();
        contact.Cold_Email_Status__c = 'Replied';
        contact.Cold_Email_Sequence__c = 'Demo Requests & Inquiries To Sales';
        TestUtils.updateAndAssert(contact);
        Test.stopTest();

        final List<CampaignMember> memberRecordList = [SELECT Id, LeadId, ContactId FROM CampaignMember WHERE CampaignId =: newCampaign.Id];
        
        System.assertEquals(memberRecordList.size(), 1);
        System.assertEquals(memberRecordList[0].ContactId, contact.Id);
        System.assertEquals(memberRecordList[0].LeadId, null);
    }
}
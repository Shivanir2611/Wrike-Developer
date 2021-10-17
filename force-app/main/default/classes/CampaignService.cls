public class CampaignService {
    
    public static CampaignService getInstance() {
        return (CampaignService)ServiceLocator.getInstance(CampaignService.class);
    }
    
    public void leadCampaignConditionCheck(final List<Lead> newLeads, final Map<Id,Lead> oldMap){
        final Map<Id, String> leadMap = new Map<Id, String>();
        for(Lead lead : newLeads){
            final Lead oldLead = oldMap.get(lead.Id);
            if(oldLead.Cold_Email_Status__c != lead.Cold_Email_Status__c && lead.Cold_Email_Status__c == 'Replied' && lead.Cold_Email_Sequence__c != ''){
                leadMap.put(lead.Id, lead.Cold_Email_Sequence__c);
            }   
        }
        if(!leadMap.isEmpty()){
            leadSyncWithCampaigns(leadMap);
        }
    }
    
    public void contactCampaignConditionCheck(final List<Contact> newContacts, final Map<Id, Contact> oldMap){
        final Map<Id, String> contactMap = new Map<Id, String>();
        for(Contact contact : newContacts){
            final Contact oldContact = oldMap.get(contact.Id);
            if(oldContact.Cold_Email_Status__c != contact.Cold_Email_Status__c && contact.Cold_Email_Status__c == 'Replied' && contact.Cold_Email_Sequence__c != ''){
                contactMap.put(contact.Id, contact.Cold_Email_Sequence__c);
            }   
        }
        if(!contactMap.isEmpty()){
            contactSyncWithCampaigns(contactMap);
        }
    }
    
    private void contactSyncWithCampaigns(final Map<Id, String> contactMap){
        final List<CampaignMember> campaignMemberList = new List<CampaignMember>();
        final Set<String> existingCampaignMemberKeys = getExistingCampaignMembers(contactMap);
        if(!contactMap.isEmpty()){
            for(Campaign newCampaign : [
                SELECT Id, Name
                FROM Campaign
                WHERE Name =: contactMap.values()
            ]){
                for(Id contactId : contactMap.keySet()){
                    if(contactId != null && newCampaign.Name == contactMap.get(contactId) && !existingCampaignMemberKeys.contains(contactId + '_' + newCampaign.Id)){
                        CampaignMember memberRecord = new CampaignMember(
                            CampaignId = newCampaign.Id,
                            ContactId = contactId
                        );
                        campaignMemberList.add(memberRecord);    
                    }
                }
            }
            if(!campaignMemberList.isEmpty()){
                insert campaignMemberList;    
            }   
        }   
    }
    
    private void leadSyncWithCampaigns(final Map<Id, String> leadMap){
        final List<CampaignMember> campaignMemberList = new List<CampaignMember>();
        final Set<String> existingCampaignMemberKeys = getExistingCampaignMembers(leadMap);
        if(!leadMap.isEmpty()){
            for(Campaign newCampaign : [
                SELECT Id, Name
                FROM Campaign
                WHERE Name =: leadMap.values()
            ]){
                for(Id leadId : leadMap.keySet()){
                    if(leadId != null && newCampaign.Name == leadMap.get(leadId) && !existingCampaignMemberKeys.contains(leadId + '_' + newCampaign.Id)){
                        CampaignMember memberRecord = new CampaignMember(
                            CampaignId = newCampaign.Id,
                            LeadId = leadId
                        );
                        campaignMemberList.add(memberRecord);    
                    }
                }
            }
            if(!campaignMemberList.isEmpty()){
                insert campaignMemberList;    
            }   
        }
    }
    
    private Set<String> getExistingCampaignMembers(final Map<Id, String> recordMap){
        final Set<String> existingCampaignMembers = new Set<String>();
        for(CampaignMember newCampaignMember : [
            SELECT Id, LeadOrContactId, CampaignId
            FROM CampaignMember
            WHERE Campaign.Name IN : recordMap.values()
            AND LeadOrContactId IN : recordMap.keySet() 
        ]){
            existingCampaignMembers.add(newCampaignMember.LeadOrContactId + '_' + newCampaignMember.CampaignId); 
        }
        return existingCampaignMembers;
    }
}
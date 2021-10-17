public class CampaignMemberTriggerHandler {
    
    public static CampaignMemberTriggerHandler getInstance() {
        return (CampaignMemberTriggerHandler)ServiceLocator.getInstance(CampaignMemberTriggerHandler.class);
    }
    
    private Boolean disableCampaignMemberBatchRun = Settings__c.getOrgDefaults().DisableCampaignMemberBatchJob__c;
    
    public void afterInsert(final List<CampaignMember> campaignMembers) {
        if(!disableCampaignMemberBatchRun){
            getCampaignMemberEmailMap(campaignMembers, null);    
        }
    }
    
    public void afterUpdate(final List<CampaignMember> campaignMembers, final Map<Id, CampaignMember> oldMap) {
        if(!disableCampaignMemberBatchRun){
            getCampaignMemberEmailMap(campaignMembers, oldMap);
        }
    }
    
    private void getCampaignMemberEmailMap(final List<CampaignMember> campaignMembers, final Map<Id, CampaignMember> oldMap){
        Map<String, CampaignMember> campaignMemberEmailMap = new Map<String, CampaignMember>();
        for(CampaignMember campaignMember : campaignMembers){
            final CampaignMember oldCampaignMember = oldMap != null ? oldMap.get(campaignMember.Id) : null;
            if(oldCampaignMember == null || isCampaignMemberUpdate(oldCampaignMember, campaignMember)){
            	campaignMemberEmailMap.put(campaignMember.Email, campaignMember);	
            }
        }
        if(!campaignMemberEmailMap.isEmpty()){
            updateCampaignData(campaignMemberEmailMap);    
        }
    }
    
    private void updateCampaignData(final Map<String, CampaignMember> campaignMemberEmailMap){
        final Map<String, EmailData__c> updateEmailDataMap = new Map<String, EmailData__c>();
        
        for(CampaignMember campaignMember : campaignMemberEmailMap.values()){
            updateEmailDataMap.put(campaignMember.Email, new EmailData__c(
                Email__c = campaignMember.Email, 
                Most_Recent_Campaign__c = campaignMember.Campaign_Name__c, 
                Campaign_Member_Status__c = campaignMember.Status
            ));
        }
        Schema.SObjectField emailDataExternalField = EmailData__c.Fields.Email__c;
        if(!updateEmailDataMap.isEmpty()){
            Database.upsert(updateEmailDataMap.values(), emailDataExternalField, false);
        }
    }
    
    private Boolean isCampaignMemberUpdate(final CampaignMember oldCampaignMember, final CampaignMember newCampaignMember){
        return newCampaignMember.CampaignId != oldCampaignMember.CampaignId || 
            newCampaignMember.Status != oldCampaignMember.Status || 
            newCampaignMember.Email != oldCampaignMember.Email ||
            newCampaignMember.Campaign_Name__c != oldCampaignMember.Campaign_Name__c;
    }
}
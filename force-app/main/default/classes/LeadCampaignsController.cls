public class LeadCampaignsController {
    
    @AuraEnabled
    public static List<CampaignMember> getCampaignMembers(Id recordId){
        List<CampaignMember> campaignMemberList = new List<CampaignMember>();
        String leadEmail = [SELECT Email FROM Lead WHERE Id =: recordId AND Email != null]?.Email;
        if(String.isNotBlank(leadEmail)){
            campaignMemberList = [
                SELECT Id, CampaignId, Name, Status, Campaign.Name, LeadOrContactId
                FROM CampaignMember
                WHERE Lead.Email =: leadEmail
                    OR Contact.Email =: leadEmail
                ORDER BY CreatedDate DESC
            ];
        }
        return campaignMemberList;
    }
}
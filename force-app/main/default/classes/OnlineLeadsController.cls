global class OnlineLeadsController {
    private List<Lead> leads;
    
    public OnlineLeadsController() {
        refreshLeads();
    } 
    
    public List<Lead> getLeads() {
        return leads;
    }
    
    public void refreshLeads() {
        this.leads = [
            SELECT Id, Email, Online_Minutes__c
            FROM Lead 
            WHERE Wrike_User_Data__r.Online__c = true 
              AND OwnerId = :UserInfo.getUserId()
              AND IsConverted = false
              AND Status != 'Recycle'
              AND Wrike_License_Name__c != 'Free'
            ORDER BY Wrike_User_Data__r.Online_Date__c DESC
        ];
    }
}
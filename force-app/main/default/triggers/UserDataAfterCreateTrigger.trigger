trigger UserDataAfterCreateTrigger on UserData__c (after insert, after update) {
    final UserData__c[] userDataList = Trigger.new;
    final List<Decimal> wrikeUserIds = new List<Decimal>();
    for(UserData__c userData : userDataList) {
        wrikeUserIds.add(userData.Wrike_User_Id__c);
    }
    final List<Lead> leads = [SELECT Id, Wrike_User_Id__c, CreatedDate, Wrike_User_Data__c, MQL__c, Corporate_Email__c
                              FROM Lead 
                              WHERE IsConverted = false 
                              AND Wrike_User_Id__c IN :wrikeUserIds];
    if(!leads.isEmpty()) {
        final Map<Decimal, Lead> leadMap = new Map<Decimal, Lead>();
        for(Lead lead : leads) {
            leadMap.put(lead.Wrike_User_Id__c, lead);
        }
        final List<Lead> leadsToUpdate = new List<Lead>();
        for(UserData__c userData : userDataList) {
            final Lead lead = leadMap.get(userData.Wrike_User_Id__c);
            final Boolean mql = lead != null && lead.Corporate_Email__c && userData.Two_Login_Dates__c && lead.CreatedDate > DateTime.now().addDays(-8);
            if(lead != null && (lead.Wrike_User_Data__c == null || (!lead.MQL__c && mql))) {
                final Lead leadToUpdate = new Lead(Id = lead.Id);
                if(lead.Wrike_User_Data__c == null) {
                    leadToUpdate.Wrike_User_Data__c = userData.Id;
                }
                if(mql && !lead.MQL__c) {
                    leadToUpdate.MQL__c = true;    
                }
                leadsToUpdate.add(leadToUpdate);
            }
        }
        if(!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}
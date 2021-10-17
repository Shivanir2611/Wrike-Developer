public class SalesSettingsController {
    public List<UserBean> users {get; set;}

    public SalesSettingsController() {
        final Map<Id, SalesSettings__c> codeMap = getUserCodeMap();
        this.users = new List<UserBean>();
        for(User user : [SELECT Id, Name, Profile.Name, UserRole.Name FROM User WHERE IsActive = true ORDER BY Name]) {
            final UserBean userBean = new UserBean();
            userBean.userId = user.Id;
            userBean.name = user.Name;
            userBean.profile = user.Profile.Name;
            userBean.role = user.UserRole != null ? user.UserRole.Name : '';
            final SalesSettings__c settings = codeMap.get(user.Id); 
            userBean.settings = settings != null ? settings : new SalesSettings__c(SetupOwnerId = user.Id);
            this.users.add(userBean);    
        }
    }
    
    public PageReference cancel() {
        final Id userId = System.currentPageReference().getParameters().get('userId');
        return refresh();
    }
    
    public PageReference save() {
        final Map<Id, SalesSettings__c> codeMap = getUserCodeMap();
        final List<SalesSettings__c> updated = new List<SalesSettings__c>();
        for(UserBean user : users) {
            final SalesSettings__c settings = codeMap.get(user.userId);
            if((settings == null && user.settings.Referral_Code__c != null) || 
               (settings != null && user.settings.Referral_Code__c != settings.Referral_Code__c)) {
                updated.add(user.settings);
            }
        }
        if(!updated.isEmpty()) {
            try {
                Database.upsert(updated, Schema.SalesSettings__c.Id, true);
            } catch (System.DmlException e) {
                if(e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                        'Duplicated referral code for ' + [SELECT Name FROM User WHERE Id = :updated[e.getDmlIndex(0)].SetupOwnerId].Name));
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                }
                return null;    
            }
        }
        return refresh();
    }
    
    private PageReference refresh() {
        final PageReference ref = new PageReference(ApexPages.currentPage().getUrl());
        ref.setRedirect(true);
        return ref;
    }
    
    public Map<Id, SalesSettings__c> getUserCodeMap() {
        final List<SalesSettings__c> salesSettings = [SELECT Id, SetupOwnerId, Referral_Code__c FROM SalesSettings__c];
        final Map<Id, SalesSettings__c> codeMap = new Map<Id, SalesSettings__c>();
        for(SalesSettings__c settings : salesSettings) {
            codeMap.put(settings.SetupOwnerId, settings);
        }
        return codeMap;
    }
    
    public class UserBean {
        public Id userId {get; set;}
        public String name {get; set;}
        public String profile {get; set;}
        public String role {get; set;}
        public SalesSettings__c settings {get; set;}
    }
}
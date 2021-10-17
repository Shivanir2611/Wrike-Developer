trigger UserDataBeforeInsertUpdate on UserData__c (before insert, before update) {
    final UserData__c[] userDataList = Trigger.new;
    for(UserData__c userData : userDataList) {
        if(userData.Online__c && (Trigger.isInsert || !Trigger.oldMap.get(userData.Id).Online__c)) {
            userData.Online_Date__c = Datetime.now();
            final Date firstActiveDate = userData.First_Active_Date__c;
            if(firstActiveDate == null) {
                userData.First_Active_Date__c = Date.today();
            } else if(userData.Second_Active_Date__c == null && Date.today() > firstActiveDate ) {
                userData.Second_Active_Date__c = Date.today();
            }
        }
    }
}
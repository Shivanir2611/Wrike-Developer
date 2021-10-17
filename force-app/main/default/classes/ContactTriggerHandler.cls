public class ContactTriggerHandler {
    
    public static ContactTriggerHandler getInstance() {
        return (ContactTriggerHandler)ServiceLocator.getInstance(ContactTriggerHandler.class);
    }

    @TestVisible
    private static Boolean requestsCreated = false;
    
    public void beforeInsert(final List<Contact> newContactList) {
        final List<Activity_Data__c> activityData = new List<Activity_Data__c>();
        for(Contact contact : newContactList) {
            if (contact.Activity_Data__c == null) {
                activityData.add(new Activity_Data__c());
            }
        }
        insert activityData;
        for(Integer i = 0; i < newContactList.size(); i++) {
            final Contact contact = newContactList.get(i);
            if (contact.Activity_Data__c == null) {
                contact.Activity_Data__c = activityData.get(i).Id;
            }
        }
        populateContactEmail(newContactList, null);
    }
    
    public void beforeUpdate(final Map<Id, Contact> oldMap, final Map<Id, Contact> newMap) {
        final Map<Id, Activity_Data__c> activityDataMap = new Map<Id, Activity_Data__c>();
        for(Contact contact : newMap.values()) {
            if(contact.Activity_Data__c == null) {
                activityDataMap.put(contact.Id, new Activity_Data__c());
            }
        }
        if(!activityDataMap.isEmpty()) {
            insert activityDataMap.values();
            for(Id contactId : activityDataMap.keySet()) {
                newMap.get(contactId).Activity_Data__c = activityDataMap.get(contactId).Id;
            }
        }
        populateContactEmail(newMap.values(), oldMap);
    }
    
    public void afterInsert(final List<Contact> contacts) {
        ContactService.getInstance().updateEmailDomainInAccount(contacts);
    }

    public void afterUpdate(final List<Contact> contacts, final Map<Id, Contact> oldMap) {
        CampaignService.getInstance().contactCampaignConditionCheck(contacts, oldMap);
        if (!requestsCreated
                && Settings__c.getOrgDefaults().RequestsDisabled__c != true
                && UserInfo.getUserId().equals(Settings__c.getOrgDefaults().MarketoUserId__c)) {
            RequestService.getInstance().createRequests(contacts, oldMap);
            requestsCreated = true;
        }
    }
    
    private static void populateContactEmail(final List<Contact> contacts, final Map<Id, Contact> oldMap){
        final Map<String, EmailData__c> emailDataMap = new Map<String, EmailData__c>();
        for(Contact contact : contacts) {
            final Contact oldContact = oldMap != null ? oldMap.get(contact.Id) : null;
            if(String.isNotBlank(contact.Email) &&  (oldContact == null || contact.Email != oldContact.Email)) {
                emailDataMap.put(contact.Email.trim().toLowerCase(), new EmailData__c(
                    Email__c = contact.Email.trim().toLowerCase()
                ));
            }           	
        }
        if(!emailDataMap.isEmpty()) {
            Database.upsert(emailDataMap.values(), Schema.EmailData__c.Email__c, false);
            for(Contact contact : contacts) {
                if(String.isNotBlank(contact.Email)) {
                    final String email = contact.Email.trim().toLowerCase();
                    final Id emailDataId = emailDataMap.containsKey(email) ? emailDataMap.get(email).Id : null;
                    if(emailDataId != null) {
                        contact.EmailData__c = emailDataId;
                    }
                } else {
                    contact.EmailData__c = null;
                }
            }
        }
    }
}
trigger EmailDataTrigger on EmailData__c (after update) {

    if(Trigger.isUpdate) {
        EmailDataService.getInstance().updateRelatedLeadsAndContacts(Trigger.oldMap, Trigger.newMap);
    }
}
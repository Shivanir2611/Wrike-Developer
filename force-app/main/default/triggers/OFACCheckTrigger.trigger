trigger OFACCheckTrigger on OfacCheck__c (before update, after update) {

    if(Trigger.isBefore && Trigger.isUpdate) {
        OFACCheckTriggerHandler.getInstance().beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }

    if(Trigger.isAfter && Trigger.isUpdate) {
        OFACCheckTriggerHandler.getInstance().afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
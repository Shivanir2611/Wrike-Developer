trigger DocuSignStatusTrigger on dsfs__DocuSign_Status__c (after insert, after update) {

    final DocuSignStatusTriggerHandler handler = DocuSignStatusTriggerHandler.getInstance();

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
trigger DocuSignEnvelopeTrigger on dsfs__DocuSign_Envelope__c (after update) {

    final DocuSignEnvelopeTriggerHandler handler = DocuSignEnvelopeTriggerHandler.getInstance();

    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
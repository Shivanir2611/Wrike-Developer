trigger WrikeQuoteTrigger on Quote__c (after insert, before update, after update, after delete) {

    if(Trigger.isBefore && Trigger.isUpdate) {
        WrikeQuoteTriggerHandler.getInstance().beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }

    if(Trigger.isAfter && Trigger.isInsert) {
        WrikeQuoteTriggerHandler.getInstance().afterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isDelete) {
        WrikeQuoteTriggerHandler.getInstance().afterDelete(Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        WrikeQuoteTriggerHandler.getInstance().afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update) {

    final OpportunityTriggerHandler handler = OpportunityTriggerHandler.getInstance();

    if(Trigger.isBefore && Trigger.isInsert) {
        handler.beforeInsert(Trigger.new);
    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        handler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }

    if (Trigger.isBefore && Trigger.isDelete) {
        handler.beforeDelete(Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.newMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
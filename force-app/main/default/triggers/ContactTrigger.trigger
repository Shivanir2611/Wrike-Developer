trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    final ContactTriggerHandler handler = ContactTriggerHandler.getInstance();
    if(Trigger.isBefore && Trigger.isInsert) {
        handler.beforeInsert(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate) {
        handler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
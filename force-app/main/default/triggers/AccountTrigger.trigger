trigger AccountTrigger on Account (before insert, before update, after update) {
    final AccountTriggerHandler handler = AccountTriggerHandler.getInstance();
    if(Trigger.isBefore && Trigger.isInsert) {
        handler.beforeInsert(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate) {
        handler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
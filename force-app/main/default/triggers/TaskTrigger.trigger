trigger TaskTrigger on Task (after insert, after update, before insert, before update) {
    final TaskTriggerHandler handler = TaskTriggerHandler.getInstance();
    if(Trigger.IsBefore && Trigger.IsInsert){
        handler.beforeInsert(trigger.new);
    }
    if(Trigger.IsBefore && Trigger.IsUpdate){
        handler.beforeUpdate(trigger.oldMap, trigger.newMap);
    }
    if (Trigger.IsAfter && Trigger.IsInsert){
        handler.afterInsert(trigger.newMap);
    }
    if (Trigger.IsAfter && Trigger.IsUpdate){
        handler.afterUpdate(trigger.oldMap, trigger.newMap);
    }
}
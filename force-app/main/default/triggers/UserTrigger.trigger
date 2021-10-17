trigger UserTrigger on User (after update) {
    final UserTriggerHandler handler = UserTriggerHandler.getInstance();

    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
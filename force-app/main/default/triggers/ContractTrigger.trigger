trigger ContractTrigger on Contract (before update, after update, before delete) {

    final ContractTriggerHandler handler = ContractTriggerHandler.getInstance();

    if (Trigger.isBefore && Trigger.isUpdate) {
        handler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }

    if (Trigger.isBefore && Trigger.isDelete) {
        handler.beforeDelete(Trigger.old);
    }
}
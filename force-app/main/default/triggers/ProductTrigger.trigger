trigger ProductTrigger on Product2 (before delete) {

    final ProductTriggerHandler handler = ProductTriggerHandler.getInstance();

    if (Trigger.isBefore && Trigger.isDelete) {
        handler.beforeDelete(Trigger.old);
    }
}
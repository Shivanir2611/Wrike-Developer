trigger OrderTrigger on Order (before insert, before delete) {

    final OrderTriggerHandler handler = OrderTriggerHandler.getInstance();

    if (Trigger.isBefore && Trigger.isInsert) {
        handler.beforeInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isDelete) {
        handler.beforeDelete(Trigger.old);
    }
}
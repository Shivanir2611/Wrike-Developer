trigger OrderItemTrigger on OrderItem (before insert) {
    final OrderItemTriggerHandler handler = OrderItemTriggerHandler.getInstance();

    if (Trigger.isBefore && Trigger.isInsert) {
        handler.beforeInsert(Trigger.new);
    }
}
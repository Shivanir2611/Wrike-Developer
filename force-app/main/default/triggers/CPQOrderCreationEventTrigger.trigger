trigger CPQOrderCreationEventTrigger on CPQContractCreation__e (after insert) {

    final List<Id> orderIds = new List<Id>();
    for (CPQContractCreation__e event : Trigger.new) {
        orderIds.add(event.OrderId__c);
    }
    final List<Order> orders = [
            SELECT Id
            FROM Order
            WHERE Id IN :orderIds
              AND Status = 'Draft'
              AND SBQQ__Contracted__c = false
            FOR UPDATE
    ];
    if (!orders.isEmpty()) {
        for (Order order : orders) {
            order.Status = 'Activated';
            order.SBQQ__Contracted__c = true;
        }
        update orders;
    }
}
public class OrderItemTriggerHandler {

    public static OrderItemTriggerHandler getInstance() {
        return (OrderItemTriggerHandler)ServiceLocator.getInstance(OrderItemTriggerHandler.class);
    }

    public void beforeInsert(final List<OrderItem> orderItems) {
        final List<Id> quoteLineIds = new List<Id>();
        for (OrderItem item : orderItems) {
            if (item.SBQQ__QuoteLine__c != null) {
                quoteLineIds.add(item.SBQQ__QuoteLine__c);
            }
        }
        if (!quoteLineIds.isEmpty()) {
            updateDatesFromQuoteLine(orderItems, quoteLineIds);
        }
    }

    private void updateDatesFromQuoteLine(final List<OrderItem> orderItems,
                                          final List<Id> quoteLineIds) {
        final Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN :quoteLineIds
        ]);
        for (OrderItem item : orderItems) {
            final SBQQ__QuoteLine__c quoteLine = quoteLineMap.get(item.SBQQ__QuoteLine__c);
            if (quoteLine != null) {
                item.ServiceDate = quoteLine.SBQQ__EffectiveStartDate__c;
                item.EndDate = quoteLine.SBQQ__EffectiveEndDate__c;
            }
        }
    }
}
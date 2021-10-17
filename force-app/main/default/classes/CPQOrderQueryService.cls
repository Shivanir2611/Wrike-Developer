public class CPQOrderQueryService {

    public static CPQOrderQueryService getInstance() {
        return (CPQOrderQueryService)ServiceLocator.getInstance(CPQOrderQueryService.class);
    }

    public Order findOrderByQuoteId(final Id quoteId) {
        final List<Order> orders = [
                SELECT Id, Status, SBQQ__Quote__c,
                       (SELECT Id, SBQQ__QuoteLine__c FROM OrderItems)
                  FROM Order
                 WHERE SBQQ__Quote__c = :quoteId
        ];
        return orders.isEmpty() ? null : orders.get(0);
    }
}
public class OrderTriggerHandler {

    public static OrderTriggerHandler getInstance() {
        return (OrderTriggerHandler)ServiceLocator.getInstance(OrderTriggerHandler.class);
    }

    public void beforeInsert(final List<Order> orders) {
        final Set<Id> quoteIds = new Set<Id>();
        for (Order order : orders) {
            quoteIds.add(order.SBQQ__Quote__c);
        }
        if (!quoteIds.isEmpty()) {
            final Map<Id, SBQQ__Quote__c> quoteByIdMap = new Map<Id, SBQQ__Quote__c>([
                    SELECT Id, QS_Bill_To__c, QS_Ship_To__c, WrikeAccountId__c, SBQQ__Opportunity2__c, OfacCheckRequired__c,
                           QuoteSubType__c
                      FROM SBQQ__Quote__c
                     WHERE Id IN :quoteIds
            ]);
            final List<Order> ordersForOfacCheck = new List<Order>();
            for (Order order : orders) {
                final SBQQ__Quote__c quote = quoteByIdMap.get(order.SBQQ__Quote__c);
                if (quote != null) {
                    order.QS_Bill_To__c = quote.QS_Bill_To__c;
                    order.QS_Ship_To__c = quote.QS_Ship_To__c;
                    order.WrikeAccountId__c = quote.WrikeAccountId__c;
                    if(quote.OfacCheckRequired__c == true) {
                        ordersForOfacCheck.add(order);
                    }
                    order.AllowNetSuiteSync__c = quote.QuoteSubType__c != 'Restart Contract (new contract - create)';
                }
            }
            OFACCheckService.getInstance().setOfacChecksForOrders(ordersForOfacCheck);
        }
    }

    public void beforeDelete(final List<Order> orders) {
        final Boolean hasPermissionToDelete = FeatureManagement.checkPermission('ActivatedOrderDeletion');
        final Boolean sandbox = OrganizationService.getInstance().isSandbox();
        for (Order order : orders) {
            if (order.Status == 'Activated' && !hasPermissionToDelete && !sandbox) {
                order.addError('Activated Order cannot be deleted. Id: ' + order.Id);
            }
        }
    }
}
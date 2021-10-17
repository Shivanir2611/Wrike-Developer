public class RestructureOrderNetSuiteSyncJob extends AbstractBatchable implements Schedulable {

    public void execute(final SchedulableContext context) {
        Database.executeBatch(this);
    }

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
                SELECT Id, SBQQ__Quote__c
                FROM Order
                WHERE SBQQ__Quote__r.QuoteSubType__c = 'Restart Contract (new contract - create)'
                AND NetSuite_Integration_ID__c = null
                AND AllowNetSuiteSync__c = false
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Order> orders) {
        final Map<Id, Id> orderIdByQuoteIdMap = new Map<Id, Id>();
        for (Order order : orders) {
            orderIdByQuoteIdMap.put(order.SBQQ__Quote__c, order.Id);
        }
        final List<Order> cancellationOrders = [
                SELECT Id, SBQQ__Quote__r.RestructureNewQuote__c, NetSuite_Integration_ID__c
                FROM Order
                WHERE SBQQ__Quote__r.RestructureNewQuote__c IN :orderIdByQuoteIdMap.keySet()
        ];
        final Map<Id, Boolean> allowSyncMap = new Map<Id, Boolean>();
        for (Order cancellationOrder : cancellationOrders) {
            final Id restructureNewOrderId = orderIdByQuoteIdMap.get(cancellationOrder.SBQQ__Quote__r.RestructureNewQuote__c);
            if (!allowSyncMap.containsKey(restructureNewOrderId)
                    || allowSyncMap.get(restructureNewOrderId)) {
                allowSyncMap.put(restructureNewOrderId, cancellationOrder.NetSuite_Integration_ID__c != null);
            }
        }
        final List<Order> ordersToUpdate = new List<Order>();
        for (Id restructureNewOrderId : allowSyncMap.keySet()) {
            final Boolean allowSync = allowSyncMap.get(restructureNewOrderId);
            if (allowSync) {
                ordersToUpdate.add(new Order(Id = restructureNewOrderId, AllowNetSuiteSync__c = allowSync));
            }
        }
        update ordersToUpdate;
    }

    public void finish(final Database.BatchableContext context) {
        sendFailedRecordsNotifications(
                context.getJobId(),
                SettingsProvider.getNetSuiteSyncOrdersNotificationEmails()
        );
    }
}
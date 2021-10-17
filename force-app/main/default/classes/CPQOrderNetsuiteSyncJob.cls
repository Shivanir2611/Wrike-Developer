public class CPQOrderNetsuiteSyncJob implements Queueable, Database.AllowsCallouts {

    private final Set<Id> orderIds;

    public CPQOrderNetsuiteSyncJob(final Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(final System.QueueableContext context) {
        final String syncUrl = CPQSettings__c.getOrgDefaults().OrderNetSuiteSyncUrl__c;
        final List<Order> orders = [
                SELECT Id, SBQQ__Quote__c
                FROM Order
                WHERE Id IN :orderIds
                AND SBQQ__Quote__r.AutoProcessStatus__c = 'Ordered'
        ];
        final List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        final List<Log__c> logs = new List<Log__c>();
        for (Order order : orders) {
            final HttpRequest request = new HttpRequest();
            request.setEndpoint(syncUrl + '?Orderid=' + order.Id);
            request.setTimeout(120000);
            request.setMethod('GET');
            final HttpResponse response = new Http().send(request);
            if (response.getStatusCode() == 200) {
                quotes.add(new SBQQ__Quote__c(
                        Id = order.SBQQ__Quote__c,
                        AutoProcessStatus__c = 'Completed'
                ));
            } else {
                quotes.add(new SBQQ__Quote__c(
                        Id = order.SBQQ__Quote__c,
                        AutoProcessStatus__c = 'Error'
                ));
                logs.add(new Log__c(
                        Name = 'Netsuite Sync Error: ' + order.Id,
                        Type__c = 'Info',
                        Message__c = 'Failed to Sync Order ' + order.Id + ' to Netsuite: ' + response.getStatus() + ' ' + response.getStatusCode(),
                        Details__c = response.getBody(),
                        Quote__c = order.SBQQ__Quote__c
                ));
            }
            update quotes;
            if (!logs.isEmpty()) {
                DatabaseService.getInstance().insertSObject(logs);
            }
        }
    }
}
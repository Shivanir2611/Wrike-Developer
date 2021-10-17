public class CPQOrderManagementJob extends AbstractBatchable implements Schedulable, Database.AllowsCallouts {
    private final CPQOrderService orderService = CPQOrderService.getInstance();
    private final CPQOrderQueryService orderQueryService = CPQOrderQueryService.getInstance();
    private final CPQRenewalService renewalService = CPQRenewalService.getInstance();
    private final CPQQuoteService quoteService = CPQQuoteService.getInstance();

    public void execute(final SchedulableContext context) {
        Database.executeBatch(this, 1);
    }

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
                SELECT Id, AutoRenewalQuote__c
                FROM Contract
                WHERE Status = 'Activated'
                  AND EndDate < TODAY
                  AND StartDate <= TODAY
                  AND Wrike_Account_ID__c > 0
                  AND AutoRenewalQuote__r.SBQQ__Status__c = :CPQQuote.DocumentGenerated
                  AND RecordType.DeveloperName = 'CPQ_Contracts'
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Contract> records) {
        System.assertEquals(1, records.size(), 'Please run the job with batch size = 1');
        final Id contractId = records[0].Id;
        final Id quoteId = records[0].AutoRenewalQuote__c;
        final CPQRenewalService.CPQRenewalData renewalData = renewalService.findRenewalData(contractId);
        if(renewalData.getRenewalStatus() == CPQRenewalService.CPQRenewalStatus.Renew.name()) {
            quoteService.createOrder(records[0].AutoRenewalQuote__c);
            final Order order = orderQueryService.findOrderByQuoteId(quoteId);
            orderService.calculateBillingSchedule(order);
            Logger.create(CPQOrderManagementJob.class).logContractAction(
                    contractId,
                    'Order Management Job: Auto-Renewal Quote ordered',
                    'Quote ' + quoteId + ' moved to Ordered status.',
                    renewalData
            );
            Eventbus.publish(new CPQContractCreation__e(
                OrderId__c = order.Id
            ));
        }
    }

    public void finish(final Database.BatchableContext context) {
        sendFailedRecordsNotifications(
                context.getJobId(),
                SettingsProvider.getCPQRenewalNotificationEmails()
        );
    }
}
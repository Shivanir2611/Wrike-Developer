public class CPQQuoteManagementJob extends AbstractBatchable implements Database.AllowsCallouts {
    private final CPQApi cpq = CPQApi.getInstance();
    private final CPQQuoteService quoteService = CPQQuoteService.getInstance();

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
                SELECT Id, AutoRenewalQuote__c
                FROM Contract
                WHERE Status = 'Activated'
                  AND EndDate < TODAY
                  AND StartDate <= TODAY
                  AND Wrike_Account_ID__c > 0
                  AND AutoRenewalQuote__r.SBQQ__Status__c = 'Draft'
                  AND RecordType.DeveloperName = 'CPQ_Contracts'
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Contract> records) {
        System.assertEquals(1, records.size(), 'Please run the job with batch size = 1');
        final Id quoteId = records[0].AutoRenewalQuote__c;
        final CPQApi.QuoteModel quoteModel = cpq.readQuote(quoteId);
        System.assertEquals(true, quoteModel.record.SBQQ__Primary__c, 'Non primary quote can not be processed.');
        if(quoteModel.record.SBQQ__Status__c == 'Draft') {
            final CPQApi.QuoteModel calculatedQuote = cpq.calculate(quoteModel);
            cpq.save(calculatedQuote);
            if(hasPremiumSupportProduct(quoteModel)) {
                return;
            }
            quoteService.calculateBillingScheduleAndUpdateQuote(quoteId);
            final CPQQuote cpqQuote = quoteService.findQuoteById(quoteId);
            System.assertNotEquals(null, cpqQuote.billToId);
            System.assertNotEquals(null, cpqQuote.shipToId);
            quoteService.initiateDocumentGeneration(cpqQuote);
        }
    }

    private Boolean hasPremiumSupportProduct(final CPQApi.QuoteModel quoteModel) {
        for(CPQApi.QuoteLineModel quoteLine : quoteModel.lineItems) {
            if(quoteLine.record.SBQQ__Product__r.ProductCode == 'r-othr-sprt-PremSupport') {
                return true;
            }
        }
        return false;
    }

    public void finish(final Database.BatchableContext context) {
        sendFailedRecordsNotifications(
                context.getJobId(),
                SettingsProvider.getCPQRenewalNotificationEmails()
        );
    }
}
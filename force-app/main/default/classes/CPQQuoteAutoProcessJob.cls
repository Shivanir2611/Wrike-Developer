public class CPQQuoteAutoProcessJob implements Queueable, Database.AllowsCallouts {
    private final List<Id> quoteIds;

    public CPQQuoteAutoProcessJob(final List<Id> quoteIds) {
        this.quoteIds = quoteIds;
    }

    public void execute(final System.QueueableContext context) {
        final CPQApi cpqApi = CPQApi.getInstance();
        final List<CPQApi.QuoteModel> calculatedQuotes = new List<CPQApi.QuoteModel>();
        for (Id quoteId : quoteIds) {
            final CPQApi.QuoteModel quoteModel = cpqApi.readQuote(quoteId);
            if (quoteModel.record.SBQQ__Status__c == 'Draft') {
                calculatedQuotes.add(cpqApi.calculate(quoteModel));
            }
        }
        if (!calculatedQuotes.isEmpty()) {
            final CPQQuoteService quoteService = CPQQuoteService.getInstance();
            final CPQOrderQueryService orderQueryService = CPQOrderQueryService.getInstance();
            final CPQOrderService orderService = CPQOrderService.getInstance();
            final List<SBQQ__Quote__c> orderedQuotes = new List<SBQQ__Quote__c>();
            for (CPQApi.QuoteModel calculatedQuote : calculatedQuotes) {
                calculatedQuote.record.AutoProcessStatus__c = 'Ordered';
                cpqApi.save(calculatedQuote);
                final Id quoteId = calculatedQuote.record.Id;
                quoteService.calculateBillingScheduleAndUpdateQuote(quoteId);
                orderedQuotes.add(new SBQQ__Quote__c(
                        Id = quoteId,
                        SBQQ__Status__c = CPQQuote.Ordered,
                        SBQQ__Ordered__c = true,
                        AutoProcessStatus__c = 'Ordered'
                ));
            }
            update orderedQuotes;
            final List<CPQContractCreation__e> contractCreationEvents = new List<CPQContractCreation__e>();
            for (SBQQ__Quote__c orderedQuote : orderedQuotes) {
                final Order order = orderQueryService.findOrderByQuoteId(orderedQuote.Id);
                orderService.calculateBillingSchedule(order);
                contractCreationEvents.add(new CPQContractCreation__e(
                        OrderId__c = order.Id
                ));
            }
            Eventbus.publish(contractCreationEvents);
        }
    }
}
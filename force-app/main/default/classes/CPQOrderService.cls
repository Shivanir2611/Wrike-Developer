public class CPQOrderService {

    public static CPQOrderService getInstance() {
        return (CPQOrderService)ServiceLocator.getInstance(CPQOrderService.class);
    }

    private CPQOrderQueryService orderQuerySrv;
    private CPQQuoteService quoteSrv;
    private CPQBillingScheduleService billingScheduleSrv;

    public CPQOrderService() {
        this.orderQuerySrv = CPQOrderQueryService.getInstance();
        this.quoteSrv = CPQQuoteService.getInstance();
        this.billingScheduleSrv = CPQBillingScheduleService.getInstance();
    }

    public void calculateBillingSchedule(final Order order) {
        final CPQQuote quote = quoteSrv.findQuoteById(order.SBQQ__Quote__c);
        final List<CPQLineItemBillingSchedule> items = billingScheduleSrv.calculateLineItemBillingSchedule(quote, order);
        deleteLineItemBillingSchedules(order.Id);
        insertLineItemBillingSchedules(items);
    }

    public void createContract(final Id orderId) {
        update new Order(
                Id = orderId,
                Status = 'Activated',
                SBQQ__Contracted__c = true
        );
    }

    private void deleteLineItemBillingSchedules(final Id orderId) {
        delete [
                SELECT Id
                  FROM Line_Item_Billing_Schedule__c
                 WHERE Order__c = :orderId
        ];
    }

    private void insertLineItemBillingSchedules(final List<CPQLineItemBillingSchedule> lineItemBillingSchedules) {
        insert CPQOrderMapper.mapToLineItemBillingSchedules(lineItemBillingSchedules);
    }
}
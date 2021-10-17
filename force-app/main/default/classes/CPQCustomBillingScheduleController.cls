public class CPQCustomBillingScheduleController {

    private final static CPQQuoteService quoteSrv = CPQQuoteService.getInstance();
    private final static CPQBillingScheduleService billingScheduleService = CPQBillingScheduleService.getInstance();

    @AuraEnabled
    public static CPQQuote getQuote(final String quoteId) {
        return quoteSrv.findQuoteById(quoteId);
    }

    @AuraEnabled
    public static void saveBillingSchedule(final Id quoteId,
                                           final List<CPQBillingSchedule> billingSchedules) {
        quoteSrv.deleteBillingScheduleByQuoteId(quoteId);
        quoteSrv.updateCustomBilling(quoteId);
        for (CPQBillingSchedule billingSchedule : billingSchedules) {
            billingSchedule.serviceStartDate = null;
            billingSchedule.serviceEndDate = null;
        }
        quoteSrv.insertBillingSchedule(billingSchedules);
    }
}
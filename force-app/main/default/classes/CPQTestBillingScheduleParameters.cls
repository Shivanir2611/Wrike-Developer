@IsTest
public class CPQTestBillingScheduleParameters {

    @IsTest
    static void testCalculateItemsParameters() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = 'Draft'
        );
        insert quote;
        final Product2 product = new Product2(Name = 'Test Product');
        insert product;
        final List<SBQQ__QuoteLine__c> items = new List<SBQQ__QuoteLine__c> {
                new SBQQ__QuoteLine__c(
                        SBQQ__StartDate__c = Date.newInstance(2020, 1, 31),
                        SBQQ__EndDate__c = Date.newInstance(2021, 1, 30),
                        SBQQ__SubscriptionType__c = 'Renewable',
                        SBQQ__ProductSubscriptionType__c = 'Renewable',
                        SBQQ__NetPrice__c = 500,
                        SBQQ__Quantity__c = 1,
                        SBQQ__Quote__c = quote.Id,
                        SBQQ__Product__c = product.Id
                ),
                new SBQQ__QuoteLine__c(
                        SBQQ__StartDate__c = Date.newInstance(2021, 1, 31),
                        SBQQ__EndDate__c = Date.newInstance(2021, 2, 27),
                        SBQQ__SubscriptionType__c = 'Renewable',
                        SBQQ__ProductSubscriptionType__c = 'Renewable',
                        SBQQ__NetPrice__c = 100,
                        SBQQ__Quantity__c = 1,
                        SBQQ__Quote__c = quote.Id,
                        SBQQ__Product__c = product.Id
                ),
                new SBQQ__QuoteLine__c(
                        SBQQ__StartDate__c = Date.newInstance(2020, 1, 31),
                        SBQQ__SubscriptionType__c = 'One-time',
                        SBQQ__ProductSubscriptionType__c = 'One-time',
                        SBQQ__NetPrice__c = 3000,
                        SBQQ__Quantity__c = 1,
                        SBQQ__Quote__c = quote.Id,
                        SBQQ__Product__c = product.Id
                )
        };
        insert items;

        final List<SBQQ__QuoteLine__c> itemsWithFormulas = [
                SELECT Id, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c, SBQQ__SubscriptionType__c,
                       SBQQ__Quantity__c, SBQQ__NetTotal__c, EffectiveLine__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quote.Id
        ];

        final CPQBillingScheduleParameters parameters = CPQBillingScheduleService.getInstance().calculateParameters(
                itemsWithFormulas,
                'Quarterly',
                'Quote'
        );

        System.assertEquals(Date.newInstance(2020, 1, 31), parameters.startDate);
        System.assertEquals(Date.newInstance(2021, 2, 27), parameters.endDate);
        System.assertEquals(13, parameters.term);
        System.assertEquals(4, parameters.numberOfInvoices);
        System.assertEquals(600, parameters.subscriptionTotal);
        System.assertEquals(46.15, parameters.subscriptionMonthlyRate.setScale(2));
        System.assertEquals(3000, parameters.oneTimeTotal);
        System.assertEquals(46.15, parameters.mrr);
    }

    @IsTest
    static void testCalculateTerm() {
        System.assertEquals(0.76, calculateTerm('1/31/2019', '2/22/2019'));
        System.assertEquals(13, calculateTerm('1/31/2020', '2/27/2021'));
        System.assertEquals(13, calculateTerm('1/30/2020', '2/27/2021'));
        System.assertEquals(13, calculateTerm('1/29/2020', '2/27/2021'));
        System.assertEquals(13, calculateTerm('1/28/2020', '2/27/2021'));
        System.assertEquals(12.92, calculateTerm('1/31/2019', '2/27/2020'));
        System.assertEquals(12.95, calculateTerm('1/30/2019', '2/27/2020'));
        System.assertEquals(12.99, calculateTerm('1/29/2019', '2/27/2020'));
        System.assertEquals(13, calculateTerm('1/28/2019', '2/27/2020'));
        System.assertEquals(13, calculateTerm('1/31/2019', '2/28/2020'));
        System.assertEquals(13, calculateTerm('1/30/2019', '2/28/2020'));
        System.assertEquals(1, calculateTerm('2/28/2020', '3/27/2020'));
        System.assertEquals(1, calculateTerm('2/28/2021', '3/27/2021'));
        System.assertEquals(1, calculateTerm('2/29/2020', '3/28/2020'));
        System.assertEquals(1, calculateTerm('1/15/2020', '2/14/2020'));
        System.assertEquals(1, calculateTerm('1/15/2021', '2/14/2021'));
        System.assertEquals(14, calculateTerm('1/1/2020', '2/28/2021'));
        System.assertEquals(13.92, calculateTerm('1/1/2019', '2/28/2020'));
        System.assertEquals(14, calculateTerm('1/1/2019', '2/29/2020'));
    }

    private static Decimal calculateTerm(final String startDate, final String endDate) {
        return CPQBillingScheduleService.getInstance().calculateTerm(Date.parse(startDate),
                Date.parse(endDate)).setScale(2);
    }

    @IsTest
    static void testCalculateNumberOfInvoices() {
        final CPQBillingScheduleService billingScheduleSrv = CPQBillingScheduleService.getInstance();
        System.assertEquals(12, billingScheduleSrv.calculateNumberOfInvoices(false, 12.00, 1));
        System.assertEquals(13, billingScheduleSrv.calculateNumberOfInvoices(false, 12.80, 1));
        System.assertEquals(12, billingScheduleSrv.calculateNumberOfInvoices(false, 12.30, 1));
        System.assertEquals(12, billingScheduleSrv.calculateNumberOfInvoices(true, 12.00, 1));
        System.assertEquals(13, billingScheduleSrv.calculateNumberOfInvoices(true, 12.30, 1));
        System.assertEquals(4, billingScheduleSrv.calculateNumberOfInvoices(false, 13.00, 3));
        System.assertEquals(5, billingScheduleSrv.calculateNumberOfInvoices(false, 13.01, 3));
        System.assertEquals(5, billingScheduleSrv.calculateNumberOfInvoices(true, 13.00, 3));
        System.assertEquals(4, billingScheduleSrv.calculateNumberOfInvoices(true, 12.00, 3));
        System.assertEquals(2, billingScheduleSrv.calculateNumberOfInvoices(false, 13.00, 6));
        System.assertEquals(3, billingScheduleSrv.calculateNumberOfInvoices(false, 13.01, 6));
        System.assertEquals(3, billingScheduleSrv.calculateNumberOfInvoices(true, 13.00, 6));
        System.assertEquals(2, billingScheduleSrv.calculateNumberOfInvoices(true, 12.00, 6));
        System.assertEquals(1, billingScheduleSrv.calculateNumberOfInvoices(false, 13.00, 12));
        System.assertEquals(2, billingScheduleSrv.calculateNumberOfInvoices(false, 13.01, 12));
        System.assertEquals(2, billingScheduleSrv.calculateNumberOfInvoices(true, 13.00, 12));
        System.assertEquals(1, billingScheduleSrv.calculateNumberOfInvoices(true, 12.00, 12));
    }
}
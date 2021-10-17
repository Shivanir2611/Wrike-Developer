@IsTest
public class CPQTestBillingSchedule {

    @IsTest
    static void testCalculateBillingSchedule() {
        final CPQQuote quote = new CPQQuote();
        quote.term = 13;
        quote.numberOfInvoices = 4;
        quote.billingFrequency = 3;
        quote.startDate = Date.newInstance(2020, 1, 31);
        quote.endDate = Date.newInstance(2021, 2, 27);
        quote.subscriptionMonthlyRate = 46.15;
        quote.subscriptionTotal = 600;
        quote.oneTimeTotal = 3000;

        final List<CPQBillingSchedule> billingSchedules =
                CPQBillingScheduleService.getInstance().calculateBillingSchedule(quote);

        System.assertEquals(4, billingSchedules.size());

        final CPQBillingSchedule billingSchedule1 = billingSchedules.get(3);
        System.assertEquals(Date.newInstance(2020, 1, 31), billingSchedule1.serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 5, 27), billingSchedule1.serviceEndDate);
        System.assertEquals(1, billingSchedule1.invoiceNumber);
        System.assertEquals(4, billingSchedule1.term);
        System.assertEquals(184.65, billingSchedule1.subscriptionAmount);
        System.assertEquals(3000, billingSchedule1.oneTimeFeeAmount);

        final CPQBillingSchedule billingSchedule2 = billingSchedules.get(2);
        System.assertEquals(Date.newInstance(2020, 5, 28), billingSchedule2.serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 8, 27), billingSchedule2.serviceEndDate);
        System.assertEquals(2, billingSchedule2.invoiceNumber);
        System.assertEquals(3, billingSchedule2.term);
        System.assertEquals(138.45, billingSchedule2.subscriptionAmount);

        final CPQBillingSchedule billingSchedule3 = billingSchedules.get(1);
        System.assertEquals(Date.newInstance(2020, 8, 28), billingSchedule3.serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 11, 27), billingSchedule3.serviceEndDate);
        System.assertEquals(3, billingSchedule3.invoiceNumber);
        System.assertEquals(3, billingSchedule3.term);
        System.assertEquals(138.45, billingSchedule3.subscriptionAmount);

        final CPQBillingSchedule billingSchedule4 = billingSchedules.get(0);
        System.assertEquals(Date.newInstance(2020, 11, 28), billingSchedule4.serviceStartDate);
        System.assertEquals(Date.newInstance(2021, 2, 27), billingSchedule4.serviceEndDate);
        System.assertEquals(4, billingSchedule4.invoiceNumber);
        System.assertEquals(3, billingSchedule4.term);
        System.assertEquals(138.45, billingSchedule4.subscriptionAmount);

        Decimal subscriptionTotal = 0;
        for (CPQBillingSchedule billingSchedule : billingSchedules) {
            subscriptionTotal = subscriptionTotal + billingSchedule.subscriptionAmount;
        }

        System.assertEquals(quote.subscriptionTotal, subscriptionTotal);
    }

    @IsTest
    static void testCalculateBillingScheduleFractional() {
        final CPQQuote quote = new CPQQuote();
        quote.term = 60;
        quote.numberOfInvoices = 5;
        quote.billingFrequency = 12;
        quote.startDate = Date.newInstance(2020, 1, 31);
        quote.endDate = Date.newInstance(2025, 1, 30);
        quote.subscriptionMonthlyRate = 53308.3333;
        quote.subscriptionTotal = 3198500;
        quote.oneTimeTotal = 0;

        final List<CPQBillingSchedule> billingSchedules =
                CPQBillingScheduleService.getInstance().calculateBillingSchedule(quote);

        System.assertEquals(5, billingSchedules.size());

        final CPQBillingSchedule billingSchedule1 = billingSchedules.get(4);
        System.assertEquals(Date.newInstance(2020, 1, 31), billingSchedule1.serviceStartDate);
        System.assertEquals(Date.newInstance(2021, 1, 30), billingSchedule1.serviceEndDate);
        System.assertEquals(1, billingSchedule1.invoiceNumber);
        System.assertEquals(12, billingSchedule1.term);
        System.assertEquals(639700, billingSchedule1.subscriptionAmount);

        final CPQBillingSchedule billingSchedule5 = billingSchedules.get(0);
        System.assertEquals(Date.newInstance(2024, 1, 31), billingSchedule5.serviceStartDate);
        System.assertEquals(Date.newInstance(2025, 1, 30), billingSchedule5.serviceEndDate);
        System.assertEquals(5, billingSchedule5.invoiceNumber);
        System.assertEquals(12, billingSchedule5.term);
        System.assertEquals(639700, billingSchedule5.subscriptionAmount);

        Decimal subscriptionTotal = 0;
        for (CPQBillingSchedule billingSchedule : billingSchedules) {
            subscriptionTotal = subscriptionTotal + billingSchedule.subscriptionAmount;
        }

        System.assertEquals(quote.subscriptionTotal, subscriptionTotal);
    }

    @IsTest
    static void testValidateBillingSchedulesTotal() {
        final CPQBillingSchedule billingSchedule = new CPQBillingSchedule();
        billingSchedule.subscriptionAmount = 500;
        billingSchedule.oneTimeFeeAmount = 3000;

        final CPQQuote quote = new CPQQuote();
        quote.billingPeriodName = 'Quarterly';
        quote.subscriptionTotal = 500;
        quote.oneTimeTotal = 3000;
        quote.billingSchedules = new List<CPQBillingSchedule> {billingSchedule};

        System.assert(CPQBillingScheduleService.getInstance().validateBillingSchedulesTotal(quote));
    }
}
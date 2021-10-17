@IsTest
public class CPQTestLineItemBillingSchedule {

    @IsTest
    static void testCalculateLineItemBillingSchedulesOneTime() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                OneTimeTotal__c = 15000
        );
        insert quote;
        insert new List<SBQQ__QuoteLine__c> {
                createQuoteItem(15000, 1, 'One-time', quote.Id)
        };
        insert new List<Billing_Schedule__c> {
                createBillingSchedule(
                        Date.newInstance(2019, 9, 27),
                        Date.newInstance(2020, 9, 26),
                        1,
                        0,
                        15000.0,
                        quote.Id
                )
        };
        final CPQQuote cpqQuote = CPQQuoteService.getInstance().findQuoteById(quote.Id);
        final List<CPQLineItemBillingSchedule> lineItemBillingSchedules =
                CPQBillingScheduleService.getInstance().calculateLineItemBillingSchedule(cpqQuote, new Order());
        System.assertEquals(1, lineItemBillingSchedules.size());
        System.assertEquals(false, lineItemBillingSchedules[0].isSubscription());
        System.assertEquals(Date.newInstance(2019, 9, 27), lineItemBillingSchedules[0].serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 9, 26), lineItemBillingSchedules[0].serviceEndDate);
        System.assertEquals(1, lineItemBillingSchedules[0].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[0].quantity);
        System.assertEquals(15000, lineItemBillingSchedules[0].effectivePrice);
        System.assertEquals(15000, lineItemBillingSchedules[0].invoiceAllocatedAmount);
    }

    @IsTest
    static void testCalculateLineItemBillingSchedulesRenewable() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SubscriptionTotal__c = 10000
        );
        insert quote;
        insert new List<SBQQ__QuoteLine__c> {
                createQuoteItem(10000, 1, 'Renewable', quote.Id)
        };
        insert new List<Billing_Schedule__c> {
                createBillingSchedule(
                        Date.newInstance(2019, 9, 27),
                        Date.newInstance(2020, 9, 26),
                        1,
                        10000,
                        0,
                        quote.Id
                )
        };
        final CPQQuote cpqQuote = CPQQuoteService.getInstance().findQuoteById(quote.Id);
        final List<CPQLineItemBillingSchedule> lineItemBillingSchedules =
                CPQBillingScheduleService.getInstance().calculateLineItemBillingSchedule(cpqQuote, new Order());
        System.assertEquals(1, lineItemBillingSchedules.size());
        System.assertEquals(true, lineItemBillingSchedules[0].isSubscription());
        System.assertEquals(Date.newInstance(2019, 9, 27), lineItemBillingSchedules[0].serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 9, 26), lineItemBillingSchedules[0].serviceEndDate);
        System.assertEquals(1, lineItemBillingSchedules[0].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[0].quantity);
        System.assertEquals(10000, lineItemBillingSchedules[0].effectivePrice);
        System.assertEquals(10000, lineItemBillingSchedules[0].invoiceAllocatedAmount);
    }

    @IsTest
    static void testCalculateLineItemBillingSchedules() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SubscriptionTotal__c = 550,
                OneTimeTotal__c = 15000
        );
        insert quote;

        insert new List<SBQQ__QuoteLine__c> {
                createQuoteItem(0, 100, 'Renewable', quote.Id),
                createQuoteItem(3.3, 100, 'Renewable', quote.Id),
                createQuoteItem(2.2, 100, 'Renewable', quote.Id),
                createQuoteItem(10000, 1, 'One-time', quote.Id),
                createQuoteItem(5000, 1, 'One-time', quote.Id)
        };

        insert new List<Billing_Schedule__c> {
                createBillingSchedule(
                        Date.newInstance(2019, 1, 31),
                        Date.newInstance(2019, 5, 4),
                        1,
                        240.6,
                        15000.0,
                        quote.Id
                ),
                createBillingSchedule(
                        Date.newInstance(2019, 5, 5),
                        Date.newInstance(2019, 8, 4),
                        2,
                        103.3,
                        0.0,
                        quote.Id
                ),
                createBillingSchedule(
                        Date.newInstance(2019, 8, 5),
                        Date.newInstance(2019, 11, 4),
                        3,
                        103.3,
                        0.0,
                        quote.Id
                ),
                createBillingSchedule(
                        Date.newInstance(2019, 11, 5),
                        Date.newInstance(2020, 2, 4),
                        4,
                        103.3,
                        0.0,
                        quote.Id
                )
        };

        final CPQQuote cpqQuote = CPQQuoteService.getInstance().findQuoteById(quote.Id);

        final List<CPQLineItemBillingSchedule> lineItemBillingSchedules =
                CPQBillingScheduleService.getInstance().calculateLineItemBillingSchedule(cpqQuote, new Order());
        System.assertEquals(20, lineItemBillingSchedules.size());

        System.assertEquals(true, lineItemBillingSchedules[0].isSubscription());
        System.assertEquals(Date.newInstance(2019, 1, 31), lineItemBillingSchedules[0].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 5, 4), lineItemBillingSchedules[0].serviceEndDate);
        System.assertEquals(1, lineItemBillingSchedules[0].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[0].quantity);
        System.assertEquals(0, lineItemBillingSchedules[0].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[0].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[1].isSubscription());
        System.assertEquals(Date.newInstance(2019, 1, 31), lineItemBillingSchedules[1].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 5, 4), lineItemBillingSchedules[1].serviceEndDate);
        System.assertEquals(1, lineItemBillingSchedules[1].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[1].quantity);
        System.assertEquals(330, lineItemBillingSchedules[1].effectivePrice);
        System.assertEquals(144.36, lineItemBillingSchedules[1].invoiceAllocatedAmount);

        System.assertEquals(false, lineItemBillingSchedules[2].isSubscription());
        System.assertEquals(Date.newInstance(2019, 1, 31), lineItemBillingSchedules[2].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 5, 4), lineItemBillingSchedules[2].serviceEndDate);
        System.assertEquals(1, lineItemBillingSchedules[2].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[2].quantity);
        System.assertEquals(5000, lineItemBillingSchedules[2].effectivePrice);
        System.assertEquals(5000, lineItemBillingSchedules[2].invoiceAllocatedAmount);

        System.assertEquals(false, lineItemBillingSchedules[3].isSubscription());
        System.assertEquals(Date.newInstance(2019, 1, 31), lineItemBillingSchedules[3].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 5, 4), lineItemBillingSchedules[3].serviceEndDate);
        System.assertEquals(1, lineItemBillingSchedules[3].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[3].quantity);
        System.assertEquals(10000, lineItemBillingSchedules[3].effectivePrice);
        System.assertEquals(10000, lineItemBillingSchedules[3].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[4].isSubscription());
        System.assertEquals(Date.newInstance(2019, 1, 31), lineItemBillingSchedules[4].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 5, 4), lineItemBillingSchedules[4].serviceEndDate);
        System.assertEquals(1, lineItemBillingSchedules[4].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[4].quantity);
        System.assertEquals(220, lineItemBillingSchedules[4].effectivePrice);
        System.assertEquals(96.24, lineItemBillingSchedules[4].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[5].isSubscription());
        System.assertEquals(Date.newInstance(2019, 5, 5), lineItemBillingSchedules[5].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 8, 4), lineItemBillingSchedules[5].serviceEndDate);
        System.assertEquals(2, lineItemBillingSchedules[5].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[5].quantity);
        System.assertEquals(0, lineItemBillingSchedules[5].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[5].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[6].isSubscription());
        System.assertEquals(Date.newInstance(2019, 5, 5), lineItemBillingSchedules[6].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 8, 4), lineItemBillingSchedules[6].serviceEndDate);
        System.assertEquals(2, lineItemBillingSchedules[6].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[6].quantity);
        System.assertEquals(330, lineItemBillingSchedules[6].effectivePrice);
        System.assertEquals(61.98, lineItemBillingSchedules[6].invoiceAllocatedAmount);

        System.assertEquals(false, lineItemBillingSchedules[7].isSubscription());
        System.assertEquals(Date.newInstance(2019, 5, 5), lineItemBillingSchedules[7].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 8, 4), lineItemBillingSchedules[7].serviceEndDate);
        System.assertEquals(2, lineItemBillingSchedules[7].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[7].quantity);
        System.assertEquals(5000, lineItemBillingSchedules[7].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[7].invoiceAllocatedAmount);

        System.assertEquals(false, lineItemBillingSchedules[8].isSubscription());
        System.assertEquals(Date.newInstance(2019, 5, 5), lineItemBillingSchedules[8].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 8, 4), lineItemBillingSchedules[8].serviceEndDate);
        System.assertEquals(2, lineItemBillingSchedules[8].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[8].quantity);
        System.assertEquals(10000, lineItemBillingSchedules[8].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[8].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[9].isSubscription());
        System.assertEquals(Date.newInstance(2019, 5, 5), lineItemBillingSchedules[9].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 8, 4), lineItemBillingSchedules[9].serviceEndDate);
        System.assertEquals(2, lineItemBillingSchedules[9].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[9].quantity);
        System.assertEquals(220, lineItemBillingSchedules[9].effectivePrice);
        System.assertEquals(41.32, lineItemBillingSchedules[9].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[10].isSubscription());
        System.assertEquals(Date.newInstance(2019, 8, 5), lineItemBillingSchedules[10].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 11, 4), lineItemBillingSchedules[10].serviceEndDate);
        System.assertEquals(3, lineItemBillingSchedules[10].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[10].quantity);
        System.assertEquals(0, lineItemBillingSchedules[10].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[10].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[11].isSubscription());
        System.assertEquals(Date.newInstance(2019, 8, 5), lineItemBillingSchedules[11].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 11, 4), lineItemBillingSchedules[11].serviceEndDate);
        System.assertEquals(3, lineItemBillingSchedules[11].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[11].quantity);
        System.assertEquals(330, lineItemBillingSchedules[11].effectivePrice);
        System.assertEquals(61.98, lineItemBillingSchedules[11].invoiceAllocatedAmount);

        System.assertEquals(false, lineItemBillingSchedules[12].isSubscription());
        System.assertEquals(Date.newInstance(2019, 8, 5), lineItemBillingSchedules[12].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 11, 4), lineItemBillingSchedules[12].serviceEndDate);
        System.assertEquals(3, lineItemBillingSchedules[12].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[12].quantity);
        System.assertEquals(5000, lineItemBillingSchedules[12].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[12].invoiceAllocatedAmount);

        System.assertEquals(false, lineItemBillingSchedules[13].isSubscription());
        System.assertEquals(Date.newInstance(2019, 8, 5), lineItemBillingSchedules[13].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 11, 4), lineItemBillingSchedules[13].serviceEndDate);
        System.assertEquals(3, lineItemBillingSchedules[13].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[13].quantity);
        System.assertEquals(10000, lineItemBillingSchedules[13].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[13].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[14].isSubscription());
        System.assertEquals(Date.newInstance(2019, 8, 5), lineItemBillingSchedules[14].serviceStartDate);
        System.assertEquals(Date.newInstance(2019, 11, 4), lineItemBillingSchedules[14].serviceEndDate);
        System.assertEquals(3, lineItemBillingSchedules[14].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[14].quantity);
        System.assertEquals(220, lineItemBillingSchedules[14].effectivePrice);
        System.assertEquals(41.32, lineItemBillingSchedules[14].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[15].isSubscription());
        System.assertEquals(Date.newInstance(2019, 11, 5), lineItemBillingSchedules[15].serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 2, 4), lineItemBillingSchedules[15].serviceEndDate);
        System.assertEquals(4, lineItemBillingSchedules[15].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[15].quantity);
        System.assertEquals(0, lineItemBillingSchedules[15].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[15].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[16].isSubscription());
        System.assertEquals(Date.newInstance(2019, 11, 5), lineItemBillingSchedules[16].serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 2, 4), lineItemBillingSchedules[16].serviceEndDate);
        System.assertEquals(4, lineItemBillingSchedules[16].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[16].quantity);
        System.assertEquals(330, lineItemBillingSchedules[16].effectivePrice);
        System.assertEquals(61.98, lineItemBillingSchedules[16].invoiceAllocatedAmount);

        System.assertEquals(false, lineItemBillingSchedules[17].isSubscription());
        System.assertEquals(Date.newInstance(2019, 11, 5), lineItemBillingSchedules[17].serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 2, 4), lineItemBillingSchedules[17].serviceEndDate);
        System.assertEquals(4, lineItemBillingSchedules[17].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[17].quantity);
        System.assertEquals(5000, lineItemBillingSchedules[17].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[17].invoiceAllocatedAmount);

        System.assertEquals(false, lineItemBillingSchedules[18].isSubscription());
        System.assertEquals(Date.newInstance(2019, 11, 5), lineItemBillingSchedules[18].serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 2, 4), lineItemBillingSchedules[18].serviceEndDate);
        System.assertEquals(4, lineItemBillingSchedules[18].invoiceNumber);
        System.assertEquals(1, lineItemBillingSchedules[18].quantity);
        System.assertEquals(10000, lineItemBillingSchedules[18].effectivePrice);
        System.assertEquals(0, lineItemBillingSchedules[18].invoiceAllocatedAmount);

        System.assertEquals(true, lineItemBillingSchedules[19].isSubscription());
        System.assertEquals(Date.newInstance(2019, 11, 5), lineItemBillingSchedules[19].serviceStartDate);
        System.assertEquals(Date.newInstance(2020, 2, 4), lineItemBillingSchedules[19].serviceEndDate);
        System.assertEquals(4, lineItemBillingSchedules[19].invoiceNumber);
        System.assertEquals(100, lineItemBillingSchedules[19].quantity);
        System.assertEquals(220, lineItemBillingSchedules[19].effectivePrice);
        System.assertEquals(41.32, lineItemBillingSchedules[19].invoiceAllocatedAmount);
    }

    private static SBQQ__QuoteLine__c createQuoteItem(final Decimal price,
                                                      final Integer quantity,
                                                      final String type,
                                                      final Id quoteId) {
        final Product2 product = new Product2(
                Name = 'Test Product'
        );
        insert product;
        return new SBQQ__QuoteLine__c(
                SBQQ__NetPrice__c = price,
                SBQQ__Quantity__c = quantity,
                SBQQ__ProductSubscriptionType__c = type,
                SBQQ__SubscriptionType__c = type,
                SBQQ__Quote__c = quoteId,
                SBQQ__Product__c = product.Id
        );
    }

    private static Billing_Schedule__c createBillingSchedule(final Date startDate,
                                                             final Date endDate,
                                                             final Integer invoiceNumber,
                                                             final Decimal subscriptionAmount,
                                                             final Decimal oneTimeAmount,
                                                             final Id quoteId) {
        return new Billing_Schedule__c(
                Service_Start_Date__c = startDate,
                Service_End_Date__c = endDate,
                Invoice_Number__c = invoiceNumber,
                Subscription_Amount__c = subscriptionAmount,
                One_Time_Fee_Amount__c = oneTimeAmount,
                Quote__c = quoteId
        );
    }
}
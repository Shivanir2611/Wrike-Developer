public class CPQBillingScheduleService {

    public static CPQBillingScheduleService getInstance() {
        return (CPQBillingScheduleService)ServiceLocator.getInstance(CPQBillingScheduleService.class);
    }

    private static final Map<String, Integer> BillingPeriodNameToNumber = new Map<String, Integer> {
        'Monthly' => 1,
        'Quarterly' => 3,
        'Semi-Annually' => 6,
        'Annually' => 12
    };

    public List<CPQBillingSchedule> calculateBillingSchedule(final CPQQuote quote) {
        final List<CPQBillingSchedule> billingSchedules = new List<CPQBillingSchedule>();
        for (Integer i = quote.numberOfInvoices; i > 0; i--) {
            final CPQBillingSchedule billingSchedule = new CPQBillingSchedule();
            final Decimal subscriptionAmount = getSubscriptionAmount(quote.subscriptionMonthlyRate, quote.billingFrequency);
            if (i == 1) {
                billingSchedule.term =
                        quote.term - quote.billingFrequency * (quote.numberOfInvoices - 1);
                billingSchedule.serviceStartDate = quote.startDate;
                billingSchedule.oneTimeFeeAmount = quote.oneTimeTotal;
                billingSchedule.subscriptionAmount = quote.subscriptionTotal
                        - subscriptionAmount * (quote.numberOfInvoices - 1);
            } else {
                billingSchedule.term = quote.billingFrequency;
                billingSchedule.serviceStartDate = quote.endDate.addDays(1).addMonths(
                        -quote.billingFrequency.intValue() * (quote.numberOfInvoices - i + 1));
                billingSchedule.subscriptionAmount = subscriptionAmount;
            }
            billingSchedule.invoiceNumber = i;
            billingSchedule.serviceEndDate = quote.endDate.addMonths(
                    -quote.billingFrequency.intValue() * (quote.numberOfInvoices - i));
            billingSchedule.invoiceDate = billingSchedule.serviceStartDate;
            billingSchedule.currencyCode = quote.currencyCode;
            billingSchedule.quoteId = quote.Id;
            billingSchedules.add(billingSchedule);
        }
        return billingSchedules;
    }

    private Decimal getSubscriptionAmount(final Decimal subscriptionMonthlyRate, final Decimal term) {
        final Decimal subscriptionAmount = subscriptionMonthlyRate * term;
        final Decimal fractionalPart = subscriptionAmount - subscriptionAmount.round(RoundingMode.DOWN);
        return fractionalPart >= 0.9
               ? subscriptionAmount.round(RoundingMode.UP)
               : subscriptionAmount;
    }

    public List<CPQLineItemBillingSchedule> calculateLineItemBillingSchedule(final CPQQuote quote,
                                                                             final Order order) {
        final Map<Id, Id> orderItemByQuoteItem = new Map<Id, Id>();
        for (OrderItem orderItem : order.OrderItems) {
            orderItemByQuoteItem.put(orderItem.SBQQ__QuoteLine__c, orderItem.Id);
        }
        final List<CPQLineItemBillingSchedule> items = new List<CPQLineItemBillingSchedule>();
        for (CPQBillingSchedule billingSchedule : quote.billingSchedules) {
            Decimal invoiceSubscriptionTotal = 0;
            Decimal invoiceOneTimeTotal = 0;
            CPQLineItemBillingSchedule firstInvoiceSubscriptionItem = null;
            CPQLineItemBillingSchedule firstInvoiceOneTimeItem = null;
            for (CPQQuoteLineItem quoteItem : quote.items) {
                final CPQLineItemBillingSchedule item = new CPQLineItemBillingSchedule();
                item.orderId = order.Id;
                item.currencyCode = quoteItem.currencyCode;
                item.orderItemId = orderItemByQuoteItem.get(quoteItem.id);
                item.quoteItemId = quoteItem.id;
                item.chargeType = quoteItem.isRenewable() ? 'Subscription' : 'One-time';
                item.netSuiteInternalId = quoteItem.product.NetsuiteIntegrationId__c;
                item.productId = quoteItem.product.Id;
                item.quantity = quoteItem.quantity;
                item.effectivePrice = quoteItem.price;
                item.invoiceNumber = billingSchedule.invoiceNumber;
                item.invoiceDate = billingSchedule.invoiceDate;
                if (!quote.getIsCustomBilling()) {
                    item.serviceStartDate = billingSchedule.serviceStartDate;
                    item.serviceEndDate = billingSchedule.serviceEndDate;
                }
                final Decimal invoiceAllocatedAmount = calculateInvoiceAllocatedAmount(
                        quoteItem.price,
                        quoteItem.isRenewable() ? quote.subscriptionTotal : quote.oneTimeTotal,
                        quoteItem.isRenewable() ? billingSchedule.subscriptionAmount : billingSchedule.oneTimeFeeAmount,
                        quote.getIsUpfrontBilling()
                );
                item.invoiceAllocatedAmount = invoiceAllocatedAmount;
                if (quoteItem.isRenewable()) {
                    invoiceSubscriptionTotal = invoiceSubscriptionTotal + invoiceAllocatedAmount;
                    if (firstInvoiceSubscriptionItem == null && invoiceAllocatedAmount != 0) {
                        firstInvoiceSubscriptionItem = item;
                    }
                } else {
                    invoiceOneTimeTotal = invoiceOneTimeTotal + invoiceAllocatedAmount;
                    if (firstInvoiceOneTimeItem == null && invoiceAllocatedAmount != 0) {
                        firstInvoiceOneTimeItem = item;
                    }
                }
                items.add(item);
            }
            if (firstInvoiceSubscriptionItem != null) {
                firstInvoiceSubscriptionItem.invoiceAllocatedAmount =
                firstInvoiceSubscriptionItem.invoiceAllocatedAmount + billingSchedule.subscriptionAmount - invoiceSubscriptionTotal;
            }
            if (firstInvoiceOneTimeItem != null) {
                firstInvoiceOneTimeItem.invoiceAllocatedAmount =
                firstInvoiceOneTimeItem.invoiceAllocatedAmount + billingSchedule.oneTimeFeeAmount - invoiceOneTimeTotal;
            }
        }
        return items;
    }

    private Decimal calculateInvoiceAllocatedAmount(final Decimal price,
                                                    final Decimal quoteTotal,
                                                    final Decimal invoiceAmount,
                                                    final Boolean upfrontBilling) {
        return quoteTotal != 0
               ? (price * invoiceAmount / quoteTotal).setScale(2)
               : (upfrontBilling ? price : 0);
    }

    private Decimal calculateInvoiceTotal(final List<CPQLineItemBillingSchedule> items) {
        Decimal totalAmount = 0;
        for (CPQLineItemBillingSchedule item : items) {
            if (item.isSubscription()) {
                totalAmount = totalAmount + item.invoiceAllocatedAmount;
            }
        }
        return totalAmount;
    }

    private CPQLineItemBillingSchedule findFirstWithNonZeroAmount(final List<CPQLineItemBillingSchedule> items) {
        for (CPQLineItemBillingSchedule item : items) {
            if (item.invoiceAllocatedAmount != 0 && item.isSubscription()) {
                return item;
            }
        }
        return null;
    }

    public CPQBillingScheduleParameters calculateParameters(final List<SBQQ__QuoteLine__c> quoteLines,
                                                            final String billingPeriodName,
                                                            final String quoteType) {
        Boolean hasEffectiveRecurringLines = false;
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if ('Renewable'.equals(quoteLine.SBQQ__SubscriptionType__c) && quoteLine.EffectiveLine__c) {
                hasEffectiveRecurringLines = true;
            }
        }
        final CPQBillingScheduleParameters parameters = new CPQBillingScheduleParameters();
        parameters.subscriptionTotal = 0;
        parameters.oneTimeTotal = 0;
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            final Boolean recurring = 'Renewable'.equals(quoteLine.SBQQ__SubscriptionType__c);
            if (recurring || !hasEffectiveRecurringLines) {
                if (parameters.startDate == null || parameters.startDate > quoteLine.SBQQ__EffectiveStartDate__c) {
                    parameters.startDate = quoteLine.SBQQ__EffectiveStartDate__c;
                }
                if (parameters.endDate == null || parameters.endDate < quoteLine.SBQQ__EffectiveEndDate__c) {
                    parameters.endDate = quoteLine.SBQQ__EffectiveEndDate__c;
                }
            }
            if (recurring) {
                parameters.subscriptionTotal = parameters.subscriptionTotal + quoteLine.SBQQ__NetTotal__c;
            } else {
                parameters.oneTimeTotal = parameters.oneTimeTotal + quoteLine.SBQQ__NetTotal__c;
            }
        }
        if (parameters.startDate != null
                && parameters.endDate != null
                && parameters.startDate < parameters.endDate) {
            parameters.term = calculateTerm(parameters.startDate, parameters.endDate);
            parameters.subscriptionMonthlyRate = (parameters.subscriptionTotal / parameters.term).setScale(2);
            if (!'Custom schedule'.equals(billingPeriodName)) {
                parameters.billingFrequency = 'Upfront'.equals(billingPeriodName)
                                              ? parameters.term
                                              : BillingPeriodNameToNumber.get(billingPeriodName);
                parameters.numberOfInvoices = calculateNumberOfInvoices(
                        'Renewal'.equals(quoteType) || 'Amendment'.equals(quoteType),
                        parameters.term,
                        parameters.billingFrequency
                );
            }
            parameters.mrr = (parameters.subscriptionTotal / parameters.term).setScale(2, System.RoundingMode.HALF_UP);
        }
        return parameters;
    }

    public Boolean validateBillingSchedulesTotal(final CPQQuote quote) {
        Decimal subscriptionTotal = 0;
        Decimal oneTimeTotal = 0;
        for (CPQBillingSchedule billingSchedule : quote.billingSchedules) {
            subscriptionTotal = subscriptionTotal + billingSchedule.subscriptionAmount;
            oneTimeTotal = oneTimeTotal + billingSchedule.oneTimeFeeAmount;
        }
        return quote.subscriptionTotal == subscriptionTotal && quote.oneTimeTotal == oneTimeTotal;
    }

    @TestVisible
    private Integer calculateNumberOfInvoices(final Boolean isAmendment,
                                              final Decimal term,
                                              final Decimal billingFrequency) {
        final Integer evenNumberOfInvoices = Math.floor(term / billingFrequency).intValue();
        final Decimal remainingInvoicePart = term - evenNumberOfInvoices * billingFrequency;
        final Boolean extraInvoice = (isAmendment == true
                && remainingInvoicePart > 0)
                || (isAmendment != true
                        && (billingFrequency == 1
                                && remainingInvoicePart > 0.5
                                || billingFrequency != 1
                                        && remainingInvoicePart > 1))
                || evenNumberOfInvoices == 0;
        return extraInvoice ? evenNumberOfInvoices + 1 : evenNumberOfInvoices;
    }

    @TestVisible
    private Decimal calculateTerm(final Date startDate, final Date endDate) {
        final Integer wholeMonths = getMonthsBetweenDates(startDate, endDate);
        final Integer remainingDays = startDate.addMonths(wholeMonths).addDays(-1).daysBetween(endDate);
        return wholeMonths + (Decimal)remainingDays * 12 / 365;
    }

    private Integer getMonthsBetweenDates(final Date startDate, final Date endDate) {
        Integer wholeMonths = 0;
        while (startDate.addMonths(wholeMonths + 1).addDays(-1) <= endDate) {
            wholeMonths = wholeMonths + 1;
        }
        return wholeMonths;
    }
}
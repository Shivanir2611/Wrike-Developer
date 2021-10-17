public class CPQQuoteMapper {

    public static CPQQuote mapToCPQQuoteWithLineItems(final SBQQ__Quote__c quote) {
        if (quote == null) {
            return null;
        }
        final CPQQuote cpqQuote = new CPQQuote();
        cpqQuote.id = quote.Id;
        cpqQuote.name = quote.Name;
        cpqQuote.billingPeriodName = quote.SBQQ__BillingFrequency__c;
        cpqQuote.startDate = quote.SBQQ__StartDate__c;
        cpqQuote.endDate = quote.SBQQ__EndDate__c;
        cpqQuote.subscriptionTotal = quote.SubscriptionTotal__c;
        cpqQuote.oneTimeTotal = quote.OneTimeTotal__c;
        cpqQuote.status = quote.SBQQ__Status__c;
        cpqQuote.currencyCode = quote.CurrencyIsoCode;
        cpqQuote.deltaMrr = quote.Delta_MRR__c;
        cpqQuote.legacyBasePlansAllowed = quote.AllowLegacyBasePlans__c;
        cpqQuote.shipToId = quote.QS_Ship_To__c;
        cpqQuote.endCustomerId = quote.EndCustomer__c;
        cpqQuote.wrikeAccountId = quote.WrikeAccountId__c;
        cpqQuote.primary = quote.SBQQ__Primary__c;
        cpqQuote.type = quote.SBQQ__Type__c;
        cpqQuote.preSignDocument = quote.PreSignDocument__c;
        cpqQuote.term = quote.Term_in_Months__c;
        cpqQuote.governingTerms = quote.Governing_Terms__c;
        cpqQuote.agreementDate = quote.Date_of_Agreement__c;
        cpqQuote.approvalStatus = quote.ApprovalStatus__c;
        cpqQuote.numberOfTeams = quote.NumberOfTeams__c == null ? null : Integer.valueOf(quote.NumberOfTeams__c);
        cpqQuote.approvalRequired = quote.ApprovalRequired__c;
        cpqQuote.documentHasDraftWatermark = quote.DocumentHasDraftWatermark__c;
        cpqQuote.purchasingByPO = quote.PurchasingByPO__c;
        cpqQuote.quoteType = quote.QuoteType__c;
        cpqQuote.quoteSubType = quote.QuoteSubType__c;
        cpqQuote.cancelledContractId = quote.CancelledContract__c;
        cpqQuote.expirationDate = quote.SBQQ__ExpirationDate__c;
        cpqQuote.paymentTerms = quote.SBQQ__PaymentTerms__c;
        cpqQuote.numberOfInvoices = quote.Number_of_Invoices__c == null ? null : Integer.valueOf(quote.Number_of_Invoices__c);
        cpqQuote.subscriptionMonthlyRate = quote.Subscription_Monthly_Rate__c;
        cpqQuote.billingFrequency = quote.BillingFrequencyMonths__c;
        cpqQuote.customGoverningTerms = quote.CustomGoverningTerms__c;
        cpqQuote.resellerAccountId = quote.ResellerAccount__c;
        cpqQuote.restructureNewQuoteId = quote.RestructureNewQuote__c;
        cpqQuote.items = mapToCPQQuoteLineItems(quote.SBQQ__LineItems__r);
        cpqQuote.billingSchedules = mapToCPQBillingSchedules(quote.Billing_Schedules__r);

        mapAccountFields(cpqQuote, quote.SBQQ__Account__r);
        mapOpportunityFields(cpqQuote, quote.SBQQ__Opportunity2__r);
        mapDocumentFields(cpqQuote, quote.Document__r);

        final Order relatedOrder = quote.SBQQ__Orders__r == null || quote.SBQQ__Orders__r.isEmpty()
                                   ? null
                                   : quote.SBQQ__Orders__r.get(0);
        if (relatedOrder != null) {
            cpqQuote.orderId = relatedOrder.Id;
            cpqQuote.orderNumber = relatedOrder.OrderNumber;
        }

        final dsfs__DocuSign_Envelope__c relatedDocuSignEnvelope = quote.DocuSignEnvelope__r;
        if (relatedDocuSignEnvelope != null) {
            cpqQuote.docuSignEnvelopeExternalId = relatedDocuSignEnvelope.dsfs__DocuSign_Envelope_ID__c;
        }
        final QS_Bill_To_Ship_To__c billTo = quote.QS_Bill_To__r;
        if (billTo != null) {
            cpqQuote.billToId = billTo.Id;
            cpqQuote.billToCountryCode = billTo.QS_Country_Code__c;
            cpqQuote.billToStateCode = billTo.QS_State_Code__c;
            cpqQuote.billToZip = billTo.QS_Zip_Postal_Code__c;
            cpqQuote.vatNumber = billTo.VATNumber__c;
        }
        return cpqQuote;
    }

    public static CPQQuote mapToCPQQuoteForCalculations(final SBQQ__Quote__c quote) {
        if (quote == null) {
            return null;
        }
        final CPQQuote cpqQuote = new CPQQuote();
        cpqQuote.id = quote.Id;
        cpqQuote.billingPeriodName = quote.SBQQ__BillingFrequency__c;
        cpqQuote.subscriptionTotal = quote.SubscriptionTotal__c;
        cpqQuote.items = mapToCPQQuoteLineItems(quote.SBQQ__LineItems__r);
        if (quote.Billing_Schedules__r != null) {
            cpqQuote.billingSchedules = mapToCPQBillingSchedules(quote.Billing_Schedules__r);
        }

        mapOpportunityFields(cpqQuote, quote.SBQQ__Opportunity2__r);
        return cpqQuote;
    }

    private static void mapOpportunityFields(final CPQQuote quote, final Opportunity opportunity) {
        if (opportunity != null) {
            quote.opportunityId = opportunity.Id;
            quote.opportunityName = opportunity.Name;
            quote.opportunityRecordTypeId = opportunity.RecordTypeId;
            quote.opportunityWrikeAccountId = opportunity.Wrike_Account_Id__c;
            quote.amendedContractId = opportunity.SBQQ__AmendedContract__c;
            quote.renewedContractId = opportunity.SBQQ__RenewedContract__c;
            if (opportunity.SBQQ__RenewedContract__c != null
                    && opportunity.SBQQ__RenewedContract__r.ActivatedRenewalQuote__c != null) {
                quote.existingRenewalQuoteId = opportunity.SBQQ__RenewedContract__r.ActivatedRenewalQuote__c;
                quote.existingRenewalQuoteOpportunityId =
                        opportunity.SBQQ__RenewedContract__r.ActivatedRenewalQuote__r.SBQQ__Opportunity2__c;
            }
        }
    }

    private static void mapAccountFields(final CPQQuote quote, final Account account) {
        if (account != null) {
            quote.accountId = account.Id;
            quote.accountName = account.Name;
        }
    }

    private static void mapDocumentFields(final CPQQuote quote, final SBQQ__QuoteDocument__c document) {
        if (document != null) {
            quote.pdfId = document.SBQQ__DocumentId__c;
        }
    }

    public static List<CPQQuoteLineItem> mapToCPQQuoteLineItems(final List<SBQQ__QuoteLine__c> items) {
        final List<CPQQuoteLineItem> cpqItems = new List<CPQQuoteLineItem>();
        for (SBQQ__QuoteLine__c item : items) {
            cpqItems.add(mapToCPQQuoteLineItem(item));
        }
        return cpqItems;
    }

    public static CPQQuoteLineItem mapToCPQQuoteLineItem(final SBQQ__QuoteLine__c item) {
        final CPQQuoteLineItem cpqItem = new CPQQuoteLineItem();
        cpqItem.id = item.Id;
        cpqItem.name = item.Name;
        cpqItem.price = item.SBQQ__NetTotal__c;
        cpqItem.effectivePricePerUserPerMonth = item.Effective_Price__c;
        cpqItem.nonRenewableDiscount = item.NonRenewableDiscount__c;
        cpqItem.quantity = Integer.valueOf(item.SBQQ__EffectiveQuantity__c);
        cpqItem.effectiveStartDate = item.SBQQ__EffectiveStartDate__c;
        cpqItem.effectiveEndDate = item.SBQQ__EffectiveEndDate__c;
        cpqItem.subscriptionType = item.SBQQ__SubscriptionType__c;
        cpqItem.bundled = item.SBQQ__Bundled__c;
        cpqItem.product = item.SBQQ__Product__r;
        cpqItem.quoteId = item.SBQQ__Quote__c;
        cpqItem.currencyCode = item.CurrencyIsoCode;
        return cpqItem;
    }

    public static List<CPQBillingSchedule> mapToCPQBillingSchedules(final List<Billing_Schedule__c> billingSchedules) {
        final List<CPQBillingSchedule> cpqBillingSchedules = new List<CPQBillingSchedule>();
        for (Billing_Schedule__c billingSchedule : billingSchedules) {
            cpqBillingSchedules.add(mapToCPQBillingSchedule(billingSchedule));
        }
        return cpqBillingSchedules;
    }

    public static CPQBillingSchedule mapToCPQBillingSchedule(final Billing_Schedule__c billingSchedule) {
        final CPQBillingSchedule cpqBillingSchedule = new CPQBillingSchedule();
        cpqBillingSchedule.id = billingSchedule.Id;
        cpqBillingSchedule.name = billingSchedule.Name;
        cpqBillingSchedule.serviceStartDate = billingSchedule.Service_Start_Date__c;
        cpqBillingSchedule.serviceEndDate = billingSchedule.Service_End_Date__c;
        cpqBillingSchedule.invoiceDate = billingSchedule.Invoice_Date__c;
        cpqBillingSchedule.subscriptionAmount = billingSchedule.Subscription_Amount__c;
        cpqBillingSchedule.oneTimeFeeAmount = billingSchedule.One_Time_Fee_Amount__c;
        cpqBillingSchedule.term = billingSchedule.Service_Term_In_Months__c;
        cpqBillingSchedule.invoiceNumber = Integer.valueOf(billingSchedule.Invoice_Number__c);
        cpqBillingSchedule.quoteId = billingSchedule.Quote__c;
        return cpqBillingSchedule;
    }

    public static List<Billing_Schedule__c> mapToBillingSchedules(final List<CPQBillingSchedule> cpqBillingSchedules) {
        final List<Billing_Schedule__c> billingSchedules = new List<Billing_Schedule__c>();
        for (CPQBillingSchedule cpqBillingSchedule : cpqBillingSchedules) {
            billingSchedules.add(mapToBillingSchedule(cpqBillingSchedule));
        }
        return billingSchedules;
    }

    public static Billing_Schedule__c mapToBillingSchedule(final CPQBillingSchedule cpqBillingSchedule) {
        final Billing_Schedule__c billingSchedule = new Billing_Schedule__c();
        billingSchedule.Id = cpqBillingSchedule.id;
        billingSchedule.Name = cpqBillingSchedule.name;
        billingSchedule.Invoice_Number__c = cpqBillingSchedule.invoiceNumber;
        billingSchedule.Service_Start_Date__c = cpqBillingSchedule.serviceStartDate;
        billingSchedule.Service_End_Date__c = cpqBillingSchedule.serviceEndDate;
        billingSchedule.Invoice_Date__c = cpqBillingSchedule.invoiceDate;
        billingSchedule.Subscription_Amount__c = cpqBillingSchedule.subscriptionAmount;
        billingSchedule.One_Time_Fee_Amount__c = cpqBillingSchedule.oneTimeFeeAmount;
        billingSchedule.Service_Term_In_Months__c = cpqBillingSchedule.term;
        billingSchedule.Quote__c = cpqBillingSchedule.quoteId;
        billingSchedule.CurrencyIsoCode = cpqBillingSchedule.currencyCode;
        return billingSchedule;
    }
}
public class CPQQuoteTriggerHandler {

    public static CPQQuoteTriggerHandler getInstance() {
        return (CPQQuoteTriggerHandler)ServiceLocator.getInstance(CPQQuoteTriggerHandler.class);
    }

    public void beforeInsert(final List<SBQQ__Quote__c> quotes) {
        final Set<Id> opportunityIds = new Set<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            opportunityIds.add(quote.SBQQ__Opportunity2__c);
            if (quote.Governing_Terms__c == 'POC with Online T&amp;C' || quote.Governing_Terms__c == 'Custom Pilot') {
                quote.Automatic_Renewal__c = 'No';
            }
            if (quote.SBQQ__Status__c == 'Draft') {
                quote.Document__c = null;
            }
        }
        if (!opportunityIds.isEmpty()) {
            final Map<Id, Opportunity> opportunityByIdMap = new Map<Id, Opportunity>([
                    SELECT Id,
                           Type,
                           SBQQ__AmendedContract__r.QS_Bill_To__c,
                           SBQQ__AmendedContract__r.QS_Ship_To__c,
                           SBQQ__AmendedContract__r.BillingFrequency__c,
                           SBQQ__AmendedContract__r.PaymentTerms__c,
                           SBQQ__AmendedContract__r.Auto_Renew__c,
                           SBQQ__AmendedContract__r.GoverningTerms__c,
                           SBQQ__AmendedContract__r.QuoteGoverningLaw__c,
                           SBQQ__AmendedContract__r.AgreementDate__c,
                           SBQQ__AmendedContract__r.TaxExempt__c,
                           SBQQ__AmendedContract__r.AdditionalUsersPrice__c,
                           SBQQ__AmendedContract__r.AdditionalUsersIncrements__c,
                           SBQQ__AmendedContract__r.AdditionalCollaboratorsPrice__c,
                           SBQQ__AmendedContract__r.AdditionalCollaboratorsIncrements__c,
                           SBQQ__AmendedContract__r.RenewalPriceProtection__c,
                           SBQQ__AmendedContract__r.PublicityLogoRightsRemoval__c,
                           SBQQ__AmendedContract__r.CoMarketingAddition__c,
                           SBQQ__AmendedContract__r.DataCenter__c,
                           SBQQ__AmendedContract__r.InternalNotes__c,
                           SBQQ__AmendedContract__r.CustomGoverningTerms__c,
                           SBQQ__AmendedContract__r.OtherGoverningLaw__c,
                           SBQQ__AmendedContract__r.AdjustPartnerCommission__c,
                           SBQQ__AmendedContract__r.PurchasingByPO__c,
                           SBQQ__AmendedContract__r.IgnoreQuantityValidation__c,
                           SBQQ__AmendedContract__r.SBQQ__RenewalTerm__c,
                           SBQQ__RenewedContract__r.QS_Bill_To__c,
                           SBQQ__RenewedContract__r.QS_Ship_To__c,
                           SBQQ__RenewedContract__r.BillingFrequency__c,
                           SBQQ__RenewedContract__r.PaymentTerms__c,
                           SBQQ__RenewedContract__r.Auto_Renew__c,
                           SBQQ__RenewedContract__r.GoverningTerms__c,
                           SBQQ__RenewedContract__r.QuoteGoverningLaw__c,
                           SBQQ__RenewedContract__r.AgreementDate__c,
                           SBQQ__RenewedContract__r.TaxExempt__c,
                           SBQQ__RenewedContract__r.AdditionalUsersPrice__c,
                           SBQQ__RenewedContract__r.AdditionalUsersIncrements__c,
                           SBQQ__RenewedContract__r.AdditionalCollaboratorsPrice__c,
                           SBQQ__RenewedContract__r.AdditionalCollaboratorsIncrements__c,
                           SBQQ__RenewedContract__r.RenewalPriceProtection__c,
                           SBQQ__RenewedContract__r.PublicityLogoRightsRemoval__c,
                           SBQQ__RenewedContract__r.CoMarketingAddition__c,
                           SBQQ__RenewedContract__r.DataCenter__c,
                           SBQQ__RenewedContract__r.InternalNotes__c,
                           SBQQ__RenewedContract__r.CustomGoverningTerms__c,
                           SBQQ__RenewedContract__r.OtherGoverningLaw__c,
                           SBQQ__RenewedContract__r.AdjustPartnerCommission__c,
                           SBQQ__RenewedContract__r.PurchasingByPO__c,
                           SBQQ__RenewedContract__r.IgnoreQuantityValidation__c,
                           SBQQ__RenewedContract__r.SBQQ__RenewalTerm__c,
                           Wrike_Account_Id__c
                    FROM Opportunity
                    WHERE Id IN :opportunityIds
            ]);
            for (SBQQ__Quote__c quote : quotes) {
                final Opportunity opportunity = opportunityByIdMap.get(quote.SBQQ__Opportunity2__c);
                if (opportunity != null) {
                    if ('Renewal'.equals(opportunity.Type)) {
                        quote.BypassValidationRules__c = true;
                    }
                    quote.WrikeAccountId__c = opportunity.Wrike_Account_Id__c;
                    final Contract contract = opportunity.SBQQ__RenewedContract__r != null
                                              ? opportunity.SBQQ__RenewedContract__r
                                              : opportunity.SBQQ__AmendedContract__r;
                    if (contract != null) {
                        quote.QS_Bill_To__c = contract.QS_Bill_To__c;
                        quote.QS_Ship_To__c = contract.QS_Ship_To__c;
                        quote.SBQQ__BillingFrequency__c = contract.BillingFrequency__c;
                        quote.SBQQ__PaymentTerms__c = contract.PaymentTerms__c;
                        quote.Automatic_Renewal__c = contract.Auto_Renew__c;
                        quote.Governing_Terms__c = contract.GoverningTerms__c;
                        quote.Governing_Law__c = contract.QuoteGoverningLaw__c;
                        quote.Date_of_Agreement__c = contract.AgreementDate__c;
                        quote.Tax_Exempt__c = contract.TaxExempt__c;
                        quote.Additional_users_price_mo__c = contract.AdditionalUsersPrice__c;
                        quote.Additional_users_increments__c = contract.AdditionalUsersIncrements__c;
                        quote.Additional_Collaborators_price_mo__c = contract.AdditionalCollaboratorsPrice__c;
                        quote.Additional_Collaborators_increments__c = contract.AdditionalCollaboratorsIncrements__c;
                        quote.Price_Protection_at_Renewal__c = contract.RenewalPriceProtection__c;
                        quote.Removal_of_Publicity_Logo_Rights__c = contract.PublicityLogoRightsRemoval__c;
                        quote.Addition_of_Co_Marketing__c = contract.CoMarketingAddition__c;
                        quote.DataCenter__c = contract.DataCenter__c;
                        quote.Internal_Notes__c = contract.InternalNotes__c;
                        quote.CustomGoverningTerms__c = contract.CustomGoverningTerms__c;
                        quote.Other_Governing_Law__c = contract.OtherGoverningLaw__c;
                        quote.AdjustPartnerCommission__c = contract.AdjustPartnerCommission__c;
                        quote.PurchasingByPO__c = contract.PurchasingByPO__c;
                        quote.IgnoreQuantityValidation__c = contract.IgnoreQuantityValidation__c;
                        quote.SBQQ__RenewalTerm__c = contract.SBQQ__RenewalTerm__c;
                    } else if(quote.SBQQ__RenewalTerm__c == null) {
                        quote.SBQQ__RenewalTerm__c = 12;
                    }
                }
            }
        }
    }

    public void beforeUpdate(final Map<Id, SBQQ__Quote__c> oldMap, final Map<Id, SBQQ__Quote__c> newMap) {
        final List<SBQQ__Quote__c> quotes = newMap.values();
        final Map<Id, SBQQ__Quote__c> updatedQuoteMap = new Map<Id, SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : quotes) {
            final SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);
            if (quote.SBQQ__Source__c != null && oldQuote.SBQQ__Source__c == null) {
                quote.ApprovalRequired__c = true;
            }
            if (quote.CustomRenewalTerm__c != oldQuote.CustomRenewalTerm__c) {
                quote.SBQQ__RenewalTerm__c = Decimal.valueOf(quote.CustomRenewalTerm__c);
            }
            if (quote.Governing_Terms__c != oldQuote.Governing_Terms__c
                    && (quote.Governing_Terms__c == 'POC with Online T&amp;C'
                            || quote.Governing_Terms__c == 'Custom Pilot')) {
                quote.Automatic_Renewal__c = 'No';
            }
            if (oldQuote.ApprovalStatus__c != quote.ApprovalStatus__c
                    && (quote.ApprovalStatus__c == 'Approved'
                            || quote.ApprovalStatus__c == 'Rejected')) {
                quote.SBQQ__Status__c = quote.ApprovalStatus__c;
                quote.ApprovalRequired__c = false;
            }
            if (quote.SBQQ__LastSavedOn__c != oldQuote.SBQQ__LastSavedOn__c) {
                updatedQuoteMap.put(quote.Id, quote);
            }
        }
        if (!updatedQuoteMap.isEmpty()) {
            updateQuotesParameters(updatedQuoteMap);
        }
    }

    private void updateQuotesParameters(final Map<Id, SBQQ__Quote__c> quoteMap) {
        final List<SBQQ__QuoteLine__c> lines = [
                SELECT Id, SBQQ__SubscriptionType__c, SBQQ__NetTotal__c, EffectiveLine__c,
                       SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c, SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteMap.keySet()
                AND EffectiveLine__c = true
                AND SBQQ__NetTotal__c != null
        ];
        final Map<Id, List<SBQQ__QuoteLine__c>> quoteLineMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c line : lines) {
            if (quoteLineMap.containsKey(line.SBQQ__Quote__c)) {
                quoteLineMap.get(line.SBQQ__Quote__c).add(line);
            } else {
                quoteLineMap.put(line.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>{line});
            }
        }
        for (SBQQ__Quote__c quote : quoteMap.values()) {
            final List<SBQQ__QuoteLine__c> quoteLines = quoteLineMap.get(quote.Id);
            if (quoteLines != null) {
                final CPQBillingScheduleParameters parameters =
                        CPQBillingScheduleService.getInstance().calculateParameters(
                                quoteLines,
                                quote.SBQQ__BillingFrequency__c,
                                quote.SBQQ__Type__c
                        );
                mapParametersToQuote(quote, parameters);
            }
        }
    }

    private void mapParametersToQuote(final SBQQ__Quote__c quote, final CPQBillingScheduleParameters parameters) {
        quote.SBQQ__StartDate__c = parameters.startDate;
        quote.SBQQ__EndDate__c = parameters.endDate;
        quote.Term_in_Months__c = parameters.term;
        quote.Number_of_Invoices__c = parameters.numberOfInvoices;
        quote.SubscriptionTotal__c = parameters.subscriptionTotal;
        quote.OneTimeTotal__c = parameters.oneTimeTotal;
        quote.Subscription_Monthly_Rate__c = parameters.subscriptionMonthlyRate;
        quote.MRR__c = parameters.mrr;
        quote.BillingFrequencyMonths__c = parameters.billingFrequency;
    }

    public void afterUpdate(final Map<Id, SBQQ__Quote__c> oldMap, final Map<Id, SBQQ__Quote__c> newMap) {
        final List<SBQQ__Quote__c> quotes = newMap.values();
        final Map<Id, Decimal> opportunityMap = new Map<Id, Decimal>();
        final Map<Id, SBQQ__Quote__c> updateQuoteMap = new Map<Id, SBQQ__Quote__c>();
        final Boolean hasBypassValidationPermission = FeatureManagement.checkPermission('ProductValidationBypass');
        final Set<Id> restructureNewQuoteToUpdateIds = new Set<Id>();
        final List<Id> autoProcessQuoteIds = new List<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            final SBQQ__Quote__c oldQuote = oldMap.get(quote.Id);
            if (quote.SBQQ__Primary__c
                    && quote.WrikeAccountId__c != null
                    && quote.WrikeAccountId__c != oldQuote.WrikeAccountId__c) {
                opportunityMap.put(quote.SBQQ__Opportunity2__c, quote.WrikeAccountId__c);
            }
            if (quote.SBQQ__LastSavedOn__c != oldQuote.SBQQ__LastSavedOn__c) {
                updateQuoteMap.put(quote.Id, quote);
            }
            if (String.isNotBlank(quote.ProductsValidationMessage__c)
                    && quote.SBQQ__Status__c == 'Draft'
                    && quote.eCommerce__c != true
                    && !hasBypassValidationPermission) {
                quote.addError(quote.ProductsValidationMessage__c);
            }
            if (quote.RestructureNewQuote__c != oldQuote.RestructureNewQuote__c
                    || quote.SubscriptionTotal__c != oldQuote.SubscriptionTotal__c
                    || quote.MRR__c != oldQuote.MRR__c) {
                if (quote.RestructureNewQuote__c != null) {
                    restructureNewQuoteToUpdateIds.add(quote.RestructureNewQuote__c);
                }
                if (quote.RestructureNewQuote__c != oldQuote.RestructureNewQuote__c
                        && oldQuote.RestructureNewQuote__c != null) {
                    restructureNewQuoteToUpdateIds.add(oldQuote.RestructureNewQuote__c);
                }
            }
            if (quote.AutoProcessStatus__c == 'Pending' && oldQuote.AutoProcessStatus__c != 'Pending') {
                autoProcessQuoteIds.add(quote.Id);
            }
        }
        final List<Opportunity> opportunities = [
                SELECT Id, Wrike_Account_Id__c
                FROM Opportunity
                WHERE Id IN :opportunityMap.keySet()
        ];
        final List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Opportunity opportunity : opportunities) {
            final Decimal quoteWrikeAccountId = opportunityMap.get(opportunity.Id);
            if (opportunity.Wrike_Account_Id__c != quoteWrikeAccountId) {
                opportunitiesToUpdate.add(new Opportunity(
                        Id = opportunity.Id,
                        Wrike_Account_Id__c = quoteWrikeAccountId
                ));
            }
        }
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
        if (!updateQuoteMap.isEmpty()) {
            updateOneTimeGroupDates(updateQuoteMap.keySet());
        }
        if (!restructureNewQuoteToUpdateIds.isEmpty()) {
            updateRestructureNewQuotes(restructureNewQuoteToUpdateIds);
        }
        if (!autoProcessQuoteIds.isEmpty()) {
            System.enqueueJob(new CPQQuoteAutoProcessJob(autoProcessQuoteIds));
        }
    }

    private void updateRestructureNewQuotes(final Set<Id> restructureNewQuoteIds) {
        final List<SBQQ__Quote__c> restructureCancellationQuotes = [
                SELECT Id, SubscriptionTotal__c, MRR__c, RestructureNewQuote__c
                FROM SBQQ__Quote__c
                WHERE RestructureNewQuote__c IN :restructureNewQuoteIds
                AND SubscriptionTotal__c != null
        ];
        final Map<Id, Decimal> prorationCreditMap = new Map<Id, Decimal>();
        final Map<Id, Decimal> mrrCreditMap = new Map<Id, Decimal>();
        for (SBQQ__Quote__c quote : restructureCancellationQuotes) {
            final Decimal prevProrationCredit = prorationCreditMap.containsKey(quote.RestructureNewQuote__c)
                                                ? prorationCreditMap.get(quote.RestructureNewQuote__c)
                                                : 0;
            prorationCreditMap.put(quote.RestructureNewQuote__c, prevProrationCredit + quote.SubscriptionTotal__c);
            final Decimal prevMRRCredit = mrrCreditMap.containsKey(quote.RestructureNewQuote__c)
                                          ? mrrCreditMap.get(quote.RestructureNewQuote__c)
                                          : 0;
            mrrCreditMap.put(quote.RestructureNewQuote__c, prevMRRCredit + quote.MRR__c);
        }
        final List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        for (Id quoteId : restructureNewQuoteIds) {
            quotesToUpdate.add(new SBQQ__Quote__c(
                    Id = quoteId,
                    ProrationCredit__c = prorationCreditMap.get(quoteId),
                    MRRCredit__c = mrrCreditMap.get(quoteId)
            ));
        }
        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }

    private void updateOneTimeGroupDates(final Set<Id> quoteIds) {
        final List<SBQQ__QuoteLineGroup__c> oneTimeGroups = [
                SELECT Id, SBQQ__Quote__c, SBQQ__StartDate__c, SBQQ__EndDate__c
                FROM SBQQ__QuoteLineGroup__c
                WHERE SBQQ__Quote__c IN :quoteIds
                  AND OneTime__c = true
        ];
        final Map<Id, AggregateResult> minRecurrentStartDateMap = new Map<Id, AggregateResult>([
                SELECT SBQQ__Quote__c Id, MIN(SBQQ__EffectiveStartDate__c) minStartDate
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIds
                  AND EffectiveLine__c = true
                  AND SBQQ__Group__r.OneTime__c = false
                  AND SBQQ__EffectiveStartDate__c != null
                GROUP BY SBQQ__Quote__c
        ]);
        final List<SBQQ__QuoteLineGroup__c> groupsToUpdate = new List<SBQQ__QuoteLineGroup__c>();
        for (SBQQ__QuoteLineGroup__c oneTimeGroup : oneTimeGroups) {
            final Date minRecurringStartDate =
                    (Date)(minRecurrentStartDateMap.get(oneTimeGroup.SBQQ__Quote__c)?.get('minStartDate'));
            if (minRecurringStartDate != null
                    && (oneTimeGroup.SBQQ__StartDate__c != minRecurringStartDate
                            || oneTimeGroup.SBQQ__EndDate__c != minRecurringStartDate)) {
                groupsToUpdate.add(new SBQQ__QuoteLineGroup__c(
                        Id = oneTimeGroup.Id,
                        SBQQ__StartDate__c = minRecurringStartDate,
                        SBQQ__EndDate__c = minRecurringStartDate
                ));
            } else if (oneTimeGroup.SBQQ__EndDate__c != oneTimeGroup.SBQQ__StartDate__c) {
                groupsToUpdate.add(new SBQQ__QuoteLineGroup__c(
                        Id = oneTimeGroup.Id,
                        SBQQ__EndDate__c = oneTimeGroup.SBQQ__StartDate__c
                ));
            }
        }
        if (!groupsToUpdate.isEmpty()) {
            update groupsToUpdate;
        }
    }

    public void beforeDelete(final List<SBQQ__Quote__c> quotes) {
        final Boolean hasPermissionToDelete = FeatureManagement.checkPermission('CPQQuoteDeletion');
        final Boolean sandbox = OrganizationService.getInstance().isSandbox();
        for (SBQQ__Quote__c quote : quotes) {
            if (!'Draft'.equals(quote.SBQQ__Status__c)
                    && !hasPermissionToDelete
                    && !sandbox
                    && !Test.isRunningTest()) {
                quote.addError('CPQ Quote cannot be deleted. Id: ' + quote.Id);
            }
        }
    }
}
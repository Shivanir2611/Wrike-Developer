public with sharing class OpportunityValidationController {

    private static NamedCredentialService namedCredentialSrv = NamedCredentialService.getInstance();
    private static OpportunityValidationService opportunityValidationSrv = OpportunityValidationService.getInstance();
    private static OpportunityQueryService opportunityQuerySrv = OpportunityQueryService.getInstance();
    private static ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();

    @AuraEnabled
    public static OpportunityValidationResult validate(final String opportunityId) {
        final OpportunityValidationResult result = new OpportunityValidationResult();
        result.wrikeUrl = SettingsProvider.getWrikeSupportappURL();

        final List<Opportunity> opportunities = opportunityQuerySrv.findWithSentWrikeQuotes(opportunityId);
        final Opportunity opportunity = opportunities.get(0);

        final Map<String, Object> wrikeAccountInfo = opportunity.Wrike_Account_Id__c > 0
                           ? WrikeUtil.findAccountInfo(opportunity.Wrike_Account_Id__c)
                           : null;
        final String validationMessage = opportunityValidationSrv.validate(opportunities, wrikeAccountInfo);
        if (validationMessage != null) {
            if (validationMessage.equals(OpportunityValidationService.OPPORTUNITY_HAS_SENT_QUOTE)) {
                result.isSent = true;
            } else {
                result.message = validationMessage;
            }
            return result;
        }
        if(!CPQQuoteCreationService.getInstance().hasNoExistingQuotes(opportunityId)) {
            result.message = 'When a CPQ Quote already exists on an Opportunity, please reach out to Sales Ops to create an old Wrike Quote.';
            return result;
        }
        if (opportunity.Wrike_Account_Id__c == null) {
            result.isOutbound = true;
            return result;
        }
        result.wrikeAccountInfo = wrikeAccountInfo;
        try {
            namedCredentialSrv.checkZuoraInstance();
        } catch (NamedCredentialService.NamedCredentialException e) {
            result.message = e.getMessage();
            return result;
        }

        final ZuoraObject.ZuoraAccount zuoraAccount = zuoraRestQuerySrv.findZuoraAccountByWrikeAccountId(opportunities[0].Wrike_Account_Id__c);
        if (zuoraAccount == null) {
            result.isNewSubscription = true;
            return result;
        }

        if (zuoraAccount.status == 'Active' && zuoraAccount.currencyCode != opportunity.CurrencyIsoCode) {
            result.message = StringUtils.format(
                            'Currency of the Opportunity ({0}) doesn`t match the existing Zuora Account ({1}). ' +
                            'Please change the Opportunity currency accordingly.',
                    opportunity.CurrencyIsoCode, zuoraAccount.currencyCode);
            return result;
        }
        final List<ZuoraObject.ZuoraSubscriptionWithRatePlans> allSubscriptions =
                zuoraRestQuerySrv.findAllSubscriptionsByZuoraAccountId(zuoraAccount.id);
        final List<ZuoraObject.ZuoraSubscriptionWithRatePlans> activeSubscriptions = new List<ZuoraObject.ZuoraSubscriptionWithRatePlans>();
        final List<ZuoraObject.ZuoraSubscription> cancelledSubscriptions = new List<ZuoraObject.ZuoraSubscription>();
        for (ZuoraObject.ZuoraSubscriptionWithRatePlans subscription : allSubscriptions) {
            if (subscription.status == 'Active') {
                activeSubscriptions.add(subscription);
            } else if (subscription.status == 'Cancelled') {
                cancelledSubscriptions.add(subscription);
            }
        }
        if (!activeSubscriptions.isEmpty()) {
            if (activeSubscriptions.size() > 1) {
                result.message = StringUtils.format('Account with Id = {0} has more than one subscription in Zuora', zuoraAccount.id);
                return result;
            }
            if (activeSubscriptions[0].termStartDate > Date.today()) {
                result.message = 'Subscription`s term start date is set to future. New quotes are not available.';
                return result;
            }
            if (activeSubscriptions[0].isEvergreen()) {
                result.message =
                        'Zuora Subscription is set to Evergreen. That type is not supported. Please contact the billing team.';
                return result;
            }
            if (activeSubscriptions.size() == 1) {
                result.isAmendment = true;
                result.zuoraAccount = zuoraAccount;
                final ZuoraObject.ZuoraSubscriptionWithRatePlans subscription = activeSubscriptions.get(0);
                result.zuoraSubscription = subscription;
                result.zuoraSubscriptionProducts = OpportunityValidationUtils.listSubscriptionProducts(subscription);
                if (!result.zuoraSubscriptionProducts.isEmpty()) {
                    result.billingPeriod = result.zuoraSubscriptionProducts.get(0).billingPeriod;
                }
                result.isRenewalQuotesAvailable = SettingsProvider.isRenewalQuotesAvailable();
                return result;
            }
        } else {
            ZuoraObject.ZuoraAmendment cancelledAmendment = null;
            if (!cancelledSubscriptions.isEmpty()) {
                cancelledAmendment = zuoraRestQuerySrv.findAmendmentChangedSubscriptionTo(cancelledSubscriptions.get(0).id);
                result.cancelledAmendment = cancelledAmendment;
            }
            if (cancelledAmendment == null || cancelledAmendment.effectiveDate <= DateUtils.getPacificLocalDate()) {
                result.isNewSubscription = true;
            }
            return result;
        }
        return null;
    }
}
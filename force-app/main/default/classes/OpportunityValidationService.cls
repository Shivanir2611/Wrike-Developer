public class OpportunityValidationService {

    public static final String OPPORTUNITY_HAS_SENT_QUOTE = 'The Opportunity Quote has been successfully sent to Z-Billing.' +
    ' Please create a new Opportunity and Quote if you need to change the corresponding Zuora subscription.';

    public static OpportunityValidationService getInstance() {
        return (OpportunityValidationService)ServiceLocator.getInstance(OpportunityValidationService.class);
    }

    private OpportunityQueryService opportunityQuerySrv;
    private UserRecordAccessService userRecordAccessSrv;

    public OpportunityValidationService() {
        this.opportunityQuerySrv = OpportunityQueryService.getInstance();
        this.userRecordAccessSrv = UserRecordAccessService.getInstance();
    }

    public OpportunityDto findByIdAndValidate(final String opportunityId) {
        final List<Opportunity> opportunities = opportunityQuerySrv.findWithSentWrikeQuotes(opportunityId);
        final String opportuinityValidationError = validate(opportunities);
        if (String.isNotBlank(opportuinityValidationError)) {
            throw new LogicException(opportuinityValidationError);
        }
        final Opportunity foundOpportunity = opportunities.get(0);
        return new OpportunityDto(foundOpportunity.Id,
                foundOpportunity.Name,
                foundOpportunity.CurrencyIsoCode,
                foundOpportunity.Wrike_Account_Id__c,
                foundOpportunity.AccountId,
                foundOpportunity.Account.Name,
                foundOpportunity.Vertical_Segment__c,
                foundOpportunity.Billing_Contact__c,
                foundOpportunity.Competitor_Lost_To__c,
                foundOpportunity.Reasons_Lost__c,
                foundOpportunity.Sub_Reason__c,
                foundOpportunity.Lost_Reason_Detail__c,
                foundOpportunity.Other_Competitors_Won_Lost_To__c,
                foundOpportunity.Other_Won_Lost_Reasons__c);
    }

    public String validate(final List<Opportunity> opportunities) {
        if (opportunities == null || opportunities.isEmpty()) {
            return 'Opportunity do not exist.';
        }
        final Map<String, Object> accountInfo = WrikeUtil.findAccountInfo(opportunities.get(0).Wrike_Account_Id__c);
        return validate(opportunities, accountInfo);
    }

    public String validate(final List<Opportunity> opportunities, final Map<String, Object> accountInfo) {
        if (opportunities == null || opportunities.isEmpty()) {
            return 'Opportunity do not exist.';
        }

        final Opportunity currentOpportunity = opportunities[0];

        if (!currentOpportunity.Quotes__r.isEmpty()) {
            return OPPORTUNITY_HAS_SENT_QUOTE;
        }

        Boolean isCurrentUserHasAccessToOpportunity =
            this.userRecordAccessSrv.hasEditAndDeleteAccess(UserInfo.getUserId(), currentOpportunity.Id);
        if (!isCurrentUserHasAccessToOpportunity) {
            return 'Insufficient permissions for the Opportunity record.';
        }

        if (String.isBlank(currentOpportunity.AccountId)) {
            return 'Salesforce Account is not set for the Opportunity.';
        }
        final Boolean outboundAvailable = FeatureManagement.checkPermission('No_Wrike_Account_ID_Quoting');
        if (currentOpportunity.Wrike_Account_Id__c == null || currentOpportunity.Wrike_Account_Id__c <= 0) {
            if(!outboundAvailable) {
                return 'Wrike Account Id is required to create a Quote. Please contact Sales Ops if you need assistance on creating a quote for a prospect without a Wrike Account.';
            }
        } else {
            if (!currentOpportunity.SkipWrikeAccountValidation__c) {
                if (accountInfo.isEmpty()) {
                    return StringUtils.format('No Wrike Account for Id = {0}. Please check the Wrike Account Id field.', currentOpportunity.Wrike_Account_Id__c);
                }
                if (accountInfo.get('deleted') == true) {
                    return StringUtils.format('Deleted Account: {0} - {1}supportapp/?account={2}', accountInfo.get('name'), SettingsProvider.getWrikeSupportappURL(), currentOpportunity.Wrike_Account_Id__c);
                }
                if(!outboundAvailable && accountInfo.get('confirmed') == false) {
                    return 'The account is not confirmed.';
                }
                if (String.isBlank((String)accountInfo.get('owner'))) {
                    return 'The account has not completed the confirmation process.';
                }
            }
            final List<Opportunity> opportunitiesWithAccount = opportunityQuerySrv.findWithAccount(
                    currentOpportunity.AccountId,
                    currentOpportunity.Wrike_Account_Id__c);
            if (!opportunitiesWithAccount.isEmpty()) {
                List<String> acoountNameAndId = new List<String>();
                for (Opportunity opportunityWithAccount : opportunitiesWithAccount) {
                    acoountNameAndId.add(StringUtils.format('{0} ({1})', opportunityWithAccount.Account.Name, opportunityWithAccount.AccountId));
                }
                return StringUtils.format('There are other Salesforce Accounts related to the same Wrike Account: {0}}', String.join(acoountNameAndId, ', ').removeEnd(', '));
            }
        }

        return null;
    }
}
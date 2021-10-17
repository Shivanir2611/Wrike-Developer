public class OpportunityZuoraValidationController {

    public static final String RECURRING = 'Recurring';

    public Id opportunityId {get; set;}
    public ZuoraObject.ZuoraAmendment cancellationAmendment {get; set;}

    private List<ZuoraObject.ZuoraSubscriptionWithRatePlans> subscriptions = new List<ZuoraObject.ZuoraSubscriptionWithRatePlans>();
    private List<OpportunityValidationUtils.SubscriptionProduct> products = new List<OpportunityValidationUtils.SubscriptionProduct>();
    private ZuoraObject.ZuoraAccount zuoraAccount;
    private String errorMessage;
    private Boolean isAmendment;
    private Boolean isSent;
    private Map<String, Object> accountInfo;
    private Boolean outbound;
    private Opportunity currentOpportunity;
    private String billingPeriod;

    private NamedCredentialService namedCredentialSrv = NamedCredentialService.getInstance();
    private OpportunityValidationService opportunityValidationSrv = OpportunityValidationService.getInstance();
    private OpportunityQueryService opportunityQueries = OpportunityQueryService.getInstance();
    private ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();

    public OpportunityZuoraValidationController(final ApexPages.StandardController controller) {
        initData(controller.getId());
    }

    private void initData(final String opportunityId) {
        this.isAmendment = true;
        this.isSent = false;

        final List<Opportunity> opportunities = opportunityQueries.findWithSentWrikeQuotes(opportunityId);
        if (opportunities.isEmpty()) {
            this.errorMessage = 'Opportunity do not exist.';
            return;
        }
        this.currentOpportunity = opportunities.get(0);
        this.outbound = this.currentOpportunity.Wrike_Account_Id__c == null;
        this.accountInfo = this.currentOpportunity.Wrike_Account_Id__c > 0
                           ? WrikeUtil.findAccountInfo(this.currentOpportunity.Wrike_Account_Id__c)
                           : null;
        this.errorMessage = opportunityValidationSrv.validate(opportunities, accountInfo);
        if (this.errorMessage == OpportunityValidationService.OPPORTUNITY_HAS_SENT_QUOTE) {
            this.isSent = true;
            return;
        }
        try {
            namedCredentialSrv.checkZuoraInstance();
        } catch (NamedCredentialService.NamedCredentialException e) {
            this.errorMessage = e.getMessage();
        }
        if (String.isNotBlank(errorMessage)) {
            return;
        }

        this.zuoraAccount = zuoraRestQuerySrv.findZuoraAccountByWrikeAccountId(opportunities[0].Wrike_Account_Id__c);
        if(zuoraAccount == null) {
            this.isAmendment = false;
            this.errorMessage = StringUtils.format('Zuora Account do not exist with AccountNumber = {0}',
                opportunities[0].Wrike_Account_Id__c);
            return;
        }
        this.opportunityId = opportunities[0].Id;
        if(zuoraAccount.status == 'Active' && zuoraAccount.currencyCode != currentOpportunity.CurrencyIsoCode) {
            this.errorMessage = StringUtils.format(
                            'Currency of the Opportunity ({0}) doesn`t match the existing Zuora Account ({1}). ' +
                            'Please change the Opportunity currency accordingly.',
                    currentOpportunity.CurrencyIsoCode, zuoraAccount.currencyCode);
            return;
        }
        final List<ZuoraObject.ZuoraSubscriptionWithRatePlans> allSubscriptions =
                zuoraRestQuerySrv.findAllSubscriptionsByZuoraAccountId(this.zuoraAccount.id);

        final List<ZuoraObject.ZuoraSubscriptionWithRatePlans> activeSubscriptions =
                new List<ZuoraObject.ZuoraSubscriptionWithRatePlans>();
        final List<ZuoraObject.ZuoraSubscription> cancelledSubscriptions = new List<ZuoraObject.ZuoraSubscription>();
        for (ZuoraObject.ZuoraSubscriptionWithRatePlans sub : allSubscriptions) {
            if (sub.status == 'Active') {
                activeSubscriptions.add(sub);
            } else if (sub.status == 'Cancelled') {
                cancelledSubscriptions.add(sub);
            }
        }

        this.subscriptions = activeSubscriptions;

        if (this.subscriptions.size() == 0) {
            if (cancelledSubscriptions.size() > 0) {
                this.cancellationAmendment = zuoraRestQuerySrv.findAmendmentChangedSubscriptionTo(cancelledSubscriptions.get(0).id);
            }
            this.isAmendment = false;
            this.errorMessage = StringUtils.format('Account with Id = {0} do not has any subscription in Zuora',
                this.zuoraAccount.id);
            return;
        } else if(this.subscriptions.size() != 1) {
            this.errorMessage = StringUtils.format('Account with Id = {0} has more than one subscription in Zuora',
                this.zuoraAccount.id);
            return;
        } else if(this.subscriptions[0].termStartDate > Date.today()) {
            this.errorMessage = 'Subscription`s term start date is set to future. New quotes are not available.';
            return;
        }
        if (this.subscriptions[0].isEvergreen()) {
            this.errorMessage = 'Zuora Subscription is set to Evergreen. That type is not supported. Please contact the billing team.';
            return;
        }
        this.products = OpportunityValidationUtils.listSubscriptionProducts(this.subscriptions[0]);
        if (!this.products.isEmpty()) {
            this.billingPeriod = products.get(0).billingPeriod;
        }
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public ZuoraObject.ZuoraSubscription getSubscription() {
        return this.subscriptions.size() == 1 ? this.subscriptions[0] : null;
    }

    public List<OpportunityValidationUtils.SubscriptionProduct> getSubscriptionProducts() {
        return this.products;
    }

    public ZuoraObject.ZuoraAccount getZuoraAccount() {
        return this.zuoraAccount;
    }

    public Boolean getIsAmendment() {
        return this.isAmendment;
    }

    public Boolean getIsSent() {
        return this.isSent;
    }

    public Map<String, Object> getAccountInfo() {
        return this.accountInfo;
    }

    public Boolean getOutbound() {
        return this.outbound;
    }

    public String getSubscriptionQuoteLink() {
        if (isLightningEnabled()) {
            return '/one/one.app#/alohaRedirect/apex/SubscriptionQuote?opportunityId=' + this.currentOpportunity.Id;
        } else {
            PageReference newSubscriptionQuotePage = Page.SubscriptionQuote;
            newSubscriptionQuotePage.getParameters().put(RequestParam.OPPORTUNITY_ID, this.currentOpportunity.Id);
            return newSubscriptionQuotePage.getUrl();
        }
    }

    public Boolean isLightningEnabled() {
        return UserInfo.getUiThemeDisplayed() == 'Theme4d';
    }

    public String getSupportAppLink() {
        return SettingsProvider.getWrikeSupportappURL() + 'supportapp/?account=' + this.currentOpportunity.Wrike_Account_Id__c;
    }

    public Boolean getIsRenewalQuotesAvailable() {
        return SettingsProvider.isRenewalQuotesAvailable();
    }

    public String getCurrencyCode() {
        return this.currentOpportunity.CurrencyIsoCode;
    }

    public String getBillingPeriod() {
        return this.billingPeriod;
    }
}
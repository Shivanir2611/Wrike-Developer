public class AccountService {

    private final SubscriptionQueryService subscriptionQuerySrv = SubscriptionQueryService.getInstance();
    private final DatabaseService databaseSrv = DatabaseService.getInstance();
    private final AccountQueryService accountQuerySrv = AccountQueryService.getInstance();
    private final Logger log = Logger.create(AccountService.class);

    public static AccountService getInstance() {
        return (AccountService)ServiceLocator.getInstance(AccountService.class);
    }
    
    public void updateAccountSubscriptionData(final Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }
        final List<Subscription__c> subscriptions = subscriptionQuerySrv.listActiveSubscriptionsByAccountIds(accountIds);
        final List<Account> accounts = accountQuerySrv.listByIds(accountIds);
        final Map<Id, List<WrikeData__c>> accountWrikeDataMap = new Map<Id, List<WrikeData__c>>();
        for (Subscription__c subscription : subscriptions) {
            final Id accountId = subscription.Account__c;
            if(!accountWrikeDataMap.containsKey(accountId)) {
                accountWrikeDataMap.put(accountId, new List<WrikeData__c>());
            }
            accountWrikeDataMap.get(accountId).add(subscription.Wrike_Data__r);
        }
        final List<Account> accountsToUpdate = new List<Account>();
        for (Account account : accounts) {
            if(accountWrikeDataMap.containsKey(account.Id)) {
                final List<WrikeData__c> wrikeDataList = accountWrikeDataMap.get(account.Id);
                final AccountSubscriptionSummary summary = new AccountSubscriptionSummary(wrikeDataList);
                if(accountWrikeDataMap.containsKey(account.Id)) {
                    account.Type = 'Customer';
                }
                account.Wrike_Subscription_Terms__c = (summary.isAnnual() ? 'Annual' : 'Monthly');
                account.Subscription_MRR_Sum__c = summary.getMrr();
                account.Subscription_License_Users_Sum__c = summary.getLicenseUsers();
                account.Subscription_Users_Sum__c = summary.getUsers();
                account.Subscription_Collaborators_Sum__c = summary.getCollaborators();
                updateAccountBillingInfoFields(account, wrikeDataList[0]);
                accountsToUpdate.add(account);
            }
        }
        final DatabaseService.Result result = databaseSrv.updateAndGetResult(accountsToUpdate, true);
        if(!result.isSuccess()) {
            log.errorToLog('Failed to update account subscription data', result.getErrorMessage());
            log.saveLog();
        }
    }

    private class AccountSubscriptionSummary {
        private final Boolean annual;
        private final Decimal mrr;
        private final Decimal licenseUsers;
        private final Decimal users;
        private final Decimal collaborators;

        private AccountSubscriptionSummary(final List<WrikeData__c> wrikeDataList) {
            Boolean annualSubscriptionExists = false;
            Decimal mrrSum = 0;
            Decimal licenseUsersSum = 0;
            Decimal usersSum = 0;
            Decimal collaboratorsSum = 0;
            for(WrikeData__c wrikeData : wrikeDataList) {
                mrrSum = mrrSum + valueOrZero(wrikeData.MRR__c);
                licenseUsersSum = licenseUsersSum + valueOrZero(wrikeData.License_Users__c);
                usersSum = usersSum + valueOrZero(wrikeData.Users__c);
                collaboratorsSum = collaboratorsSum + valueOrZero(wrikeData.Collaborators__c);
                if(wrikeData.Annual__c == true) {
                    annualSubscriptionExists = true;
                }
            }
            this.annual = annualSubscriptionExists;
            this.mrr = mrrSum;
            this.licenseUsers = licenseUsersSum;
            this.users = usersSum;
            this.collaborators = collaboratorsSum;
        }

        public Boolean isAnnual() {
            return annual;
        }

        public Decimal getMrr() {
            return mrr;
        }

        public Decimal getLicenseUsers() {
            return licenseUsers;
        }

        public Decimal getUsers() {
            return users;
        }

        public Decimal getCollaborators() {
            return collaborators;
        }

        private Decimal valueOrZero(final Decimal value) {
            return value != null ? value : 0;
        }
    }

    private void updateAccountBillingInfoFields(final Account accountToUpdate, final WrikeData__c wrikeData) {
        if (wrikeData != null && String.isBlank(accountToUpdate.BillingCountryCode)) {
            accountToUpdate.BillingCountryCode = wrikeData.CountryCode__c;
            accountToUpdate.BillingStateCode = CountryUtil.isValidCanadaUsState(wrikeData.CountryCode__c, wrikeData.StateCode__c)
                                               ? wrikeData.StateCode__c : null;
            accountToUpdate.BillingCity = wrikeData.City__c != null ? wrikeData.City__c.left(40) : null;
            accountToUpdate.BillingStreet = wrikeData.Address__c;
            accountToUpdate.BillingPostalCode = wrikeData.PostalCode__c != null
                                                ? wrikeData.PostalCode__c.left(20) : null;
        }
    }
}
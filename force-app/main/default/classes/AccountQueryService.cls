public with sharing class AccountQueryService {

    public static AccountQueryService getInstance() {
        return (AccountQueryService)ServiceLocator.getInstance(AccountQueryService.class);
    }

    public List<Account> listByIds(final Set<Id> accountIds) {
        return [
            SELECT Id, Owner.Id, Owner.IsActive, Type, T2T_Account__c,
                   BillingCountryCode, BillingStateCode, BillingCity, BillingStreet, BillingPostalCode
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    public Account findAccountById(final Id accountId) {
        final List<Account> accounts = [
                SELECT Id, Name
                FROM Account
                WHERE Id = :accountId
        ];
        return accounts.isEmpty() ? null : accounts.get(0);
    }

    public List<Account> listAccountsWithEmptyEmailDomainByIds(final Set<String> accountIds) {
        return [
            SELECT Id, Email_Domain__c
            FROM Account
            WHERE Id IN :accountIds
                AND Email_Domain__c = null
        ];
    }

    public List<Account> listByIdsWithActivityData(final List<Id> ids) {
        return [
            SELECT Id, ActivityData__c
            FROM Account
            WHERE Id IN :ids
                AND ActivityData__c != null
        ];
    }

    public Account findResellerAccountById(final Id accountId) {
        return [
                SELECT Id, AgreementType__c, TaxExempt__c,
                       GoverningTerms__c, GoverningTermsDate__c,
                       PaymentTerms__c, NewSubscriptionCommission__c,
                       RenewalSubscriptionCommission__c, OnetimeFeesCommission__c
                FROM Account
                WHERE Id = :accountId
        ];
    }
}
public with sharing class SubscriptionQueryService {

    public static SubscriptionQueryService getInstance() {
        return (SubscriptionQueryService)ServiceLocator.getInstance(SubscriptionQueryService.class);
    }
    
    public List<Subscription__c> listActiveSubscriptionsByAccountIds(final Set<Id> accountIds) {
        return [
            SELECT Id, Account__c, Status__c, Wrike_Data__r.Annual__c,
                   Wrike_Data__r.MRR__c, Wrike_Data__r.License_Users__c,
                   Wrike_Data__r.Users__c, Wrike_Data__r.Collaborators__c,
                   Wrike_Data__r.CountryCode__c, Wrike_Data__r.StateCode__c, 
                   Wrike_Data__r.City__c, Wrike_Data__r.Address__c, Wrike_Data__r.PostalCode__c
            FROM Subscription__c
            WHERE Account__c IN :accountIds 
              AND Status__c = 'Active'
              AND Wrike_Data__c != null
            ORDER By Account__c, CreatedDate
        ];
    }

    public List<Subscription__c> listActiveSubscriptionsByWrikeAccountIds(final Set<Decimal> wrikeAccountIds) {
        return [
            SELECT Id, Name, Wrike_Account_Id__c, Account__c, Status__c
            FROM Subscription__c
            WHERE Wrike_Account_Id__c IN :wrikeAccountIds
              AND Status__c = 'Active'
        ];
    }

    public Subscription__c findSubscriptionById(final Id subscriptionId) {
        return [
            SELECT Id, Account__c, Wrike_Account_Id__c
            FROM Subscription__c
            WHERE Id = :subscriptionId
        ];
    }
}
public with sharing class OpportunityQueryService {

    public static OpportunityQueryService getInstance() {
        return (OpportunityQueryService)ServiceLocator.getInstance(OpportunityQueryService.class);
    }
    
    public Id findOwnerIdById(final String opportunityId) {
        final List<Opportunity> opps = [
            SELECT OwnerId 
            FROM Opportunity 
            WHERE Id = :opportunityId
        ];
        return opps.isEmpty() ? null : opps[0].OwnerId;
    }

    public List<Opportunity> findWithContactsById(String opportunityId) {
        return [
            SELECT Id, VAT__c, BillingCountryCode__c, Billing_Contact__c, Billing_Contact__r.Id,
                Billing_Contact__r.FirstName, Billing_Contact__r.LastName, Billing_Contact__r.Email,
                Billing_Contact__r.MailingCountry, Billing_Contact__r.MailingCountryCode,
                Billing_Contact__r.MailingStateCode, Billing_Contact__r.MailingCity, Billing_Contact__r.MailingStreet,
                Billing_Contact__r.MailingPostalCode
            FROM Opportunity
            WHERE Id = :opportunityId
        ];
    }

    public List<Opportunity> findWithSentWrikeQuotes(String opportunityId) {
        return [
            SELECT Id, Name, Type, CurrencyIsoCode, AccountId, Wrike_Account_Id__c, Account.Name,
                   RecordType.DeveloperName, SkipWrikeAccountValidation__c,
                   Vertical_Segment__c, Billing_Contact__c, Competitor_Lost_To__c, Reasons_Lost__c,
                   Sub_Reason__c, Lost_Reason_Detail__c, Other_Competitors_Won_Lost_To__c, Other_Won_Lost_Reasons__c,
                   (
                       SELECT Id, Status__c
                       FROM Quotes__r
                       WHERE Status__c = 'SENT'
                   )
            FROM Opportunity
            WHERE Id = :opportunityId
        ];
    }

    public List<Opportunity> findWithAccount(String accountId, Decimal wrikeAccountId) {
        return [
            SELECT AccountId, Account.Name
            FROM Opportunity
            WHERE Wrike_Account_Id__c = :wrikeAccountId
                AND AccountId != NULL
                AND AccountId != :accountId
        ];
    }

    public Id findAmendedContractId(final Id opportunityId) {
        return [
                SELECT Id, SBQQ__AmendedContract__c
                  FROM Opportunity
                 WHERE Id = :opportunityId
        ]?.SBQQ__AmendedContract__c;
    }

    public Decimal findWrikeAccountId(final Id opportunityId) {
        return [
                SELECT Id, Wrike_Account_Id__c, CurrencyIsoCode
                  FROM Opportunity
                 WHERE Id = :opportunityId
        ]?.Wrike_Account_Id__c;
    }

    public List<Partner__c> findOpportunityResellerPartners(final Id opportunityId) {
       return [
                SELECT Id, Partner__c
                FROM Partner__c
                WHERE Opportunity__c = :opportunityId
                AND (Engagement_Level__c = 'Reseller'
                OR Engagement_Level__c = 'Local Agent')
        ];
    }

    public Opportunity findOpportunityById(final Id opportunityId) {
        final List<Opportunity> opportunities = [
                SELECT Id, AccountId, CloseDate, OwnerId
                FROM Opportunity
                WHERE Id = :opportunityId
        ];
        return opportunities.isEmpty() ? null : opportunities.get(0);
    }
}
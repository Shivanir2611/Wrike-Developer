public with sharing class LeadQueryService {

    public static LeadQueryService getInstance() {
        return (LeadQueryService)ServiceLocator.getInstance(LeadQueryService.class);
    }

    public List<Lead> findByEmails(final Set<String> emails) {
        return [
            SELECT Id, OwnerId, LeadSource, FirstName, LastName, Email, Phone, Company, NumberOfEmployees,
                   Title, Industry, PostalCode, Website, CountryCode, StateCode, Street, City,
                   HasOptedOutOfEmail, Lead_Sub_Source__c, Referral_Code__c
            FROM Lead
            WHERE Email IN :emails
              AND IsConverted = false
        ];
    }

    public Lead findLeadById(final Id leadId) {
        final List<Lead> leads = [
                SELECT Id, Email, OwnerId, Status, Recycle_Reasons__c
                FROM Lead
                WHERE Id = :leadId
        ];
        if(leads.isEmpty()) {
            return null;
        }
        return leads[0];
    }

    public List<Lead> listByIdsWithActivityData(final List<Id> ids) {
        return [
            SELECT Id, Activity_Data__c
            FROM Lead
            WHERE Id IN :ids
                AND Activity_Data__c != null
        ];
    }
}
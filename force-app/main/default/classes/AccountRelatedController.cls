public class AccountRelatedController {
    
    @AuraEnabled
    public static List<Opportunity> getOpportunities(Id recordId){
        return [
            SELECT Id, Name, Customer_Goals__c, Reasons_Lost__c, Billing_Contact__c, StageName, Billing_Contact__r.Name
            FROM Opportunity
            WHERE AccountId =: recordId
            	AND StageName = 'Closed Won'
            	AND RecordType.DeveloperName != :RecordTypeQueryService.OPPORTUNITY_RENEWAL
            ORDER BY CloseDate DESC
         ];
    }
    
    @AuraEnabled
    public static List<Contract> getContracts(Id recordId){
        return [
            SELECT Id, ContractNumber, ContractTerm, Agreement_Type__c, Status, Catch_All_Notes__c
            FROM Contract
            WHERE AccountId =: recordId
            ORDER BY CreatedDate DESC
         ];
    }
}
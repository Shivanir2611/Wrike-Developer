public class OpportunityDeploymentsController {
    
    @AuraEnabled
    public static List<Deployment__c> getDeployments(Id recordId){
        Id opportunityId = [SELECT Id, Opportunity__c FROM Deployment__c WHERE Id =: recordId AND Opportunity__c != null].Opportunity__c;
        return [
            SELECT Id, Name, Deployment_Package2__c, Status__c, Owner.Name,
                   Consultant_Selected__c, AddOns__c, Master_Delivery_Deadline__c
            FROM Deployment__c
            WHERE Opportunity__c =: opportunityId
            AND Id != : recordId
         ];
    }
}
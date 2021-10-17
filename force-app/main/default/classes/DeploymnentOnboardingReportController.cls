public class DeploymnentOnboardingReportController {
    private final Deployment__c deployment;
    
    public DeploymnentOnboardingReportController(ApexPages.StandardController sc) {     
        deployment = [SELECT Id, Wrike_Account_Id__c
                        FROM Deployment__c 
                        WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }
    
    public Deployment__c getDeployment() {
        return this.deployment;
    }  
}
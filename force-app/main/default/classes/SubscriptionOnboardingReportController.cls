public class SubscriptionOnboardingReportController {
    private final Subscription__c subscription;
    
    public SubscriptionOnboardingReportController(ApexPages.StandardController sc) {     
        subscription = [SELECT Id, Wrike_Account_Id__c
                        FROM Subscription__c 
                        WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }
    
    public Subscription__c getSubscription() {
        return this.subscription;
    }  
}
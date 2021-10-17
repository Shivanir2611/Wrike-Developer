public class ActivitySubscriptionController extends AbstractWrikeAccountIdEncrypt {
    private final Subscription__c subscription;
    
    public ActivitySubscriptionController(ApexPages.StandardController sc) {     
        subscription = [SELECT Id, Wrike_Account_Id__c
                        FROM Subscription__c 
                        WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }
    
    public override Decimal getWrikeAccountId() {
        return subscription.Wrike_Account_Id__c;
    }  
}
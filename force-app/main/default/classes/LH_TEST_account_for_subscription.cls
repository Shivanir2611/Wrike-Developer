@isTest(SeeAllData=true)
public class LH_TEST_account_for_subscription {
   static testMethod void LH_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
           FROM account LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new account()
            );
        }
       Database.upsert(sourceList);
    }
}
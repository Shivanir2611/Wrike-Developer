@isTest(SeeAllData=true)
public class LH_TEST_user_for_opportunity {
   static testMethod void LH_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
           FROM user LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new user()
            );
        }
       Database.upsert(sourceList);
    }
}
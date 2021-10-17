@IsTest
public class WrikePageCleanUpJobTest {
    
    @IsTest
    static void testWrikePagesDeleted(){
        final UserData__c userData = new UserData__c(
            Wrike_User_Id__c = 123
        );
        insert userData;
        
        final Wrike_Page__c wrikePage = new Wrike_Page__c(
            User_Data__c = userData.Id
        );
        insert wrikePage;
        
        Test.startTest();
        Database.executeBatch(new WrikePageCleanUpJob());
        Test.stopTest();
        
        final List<Wrike_Page__c> updatedWrikePage = [
            SELECT Id
            FROM Wrike_Page__c
            WHERE Id =: wrikePage.Id 
        ];
        
        System.assertEquals(0, updatedWrikePage.size());
    }
}
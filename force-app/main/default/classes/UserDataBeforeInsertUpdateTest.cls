@IsTest
private class UserDataBeforeInsertUpdateTest {

      @IsTest
      public static void testUserDataInsert() {
          final UserData__c userData = new UserData__c(
              Wrike_User_Id__c = 123,
              Online__c = true
          );
          
          test.startTest();
          insert userData;
          test.stopTest();
          
          final UserData__c insertedData = [SELECT Id, Online_Date__c, First_Active_Date__c FROM UserData__c WHERE Id = :userData.Id][0];
          System.assert(insertedData.Online_Date__c != NULL, 'Online Date was not set.');
          System.assert(insertedData.First_Active_Date__c == Date.today(), 'First Active date was not set.');
      }
      
      @IsTest
      public static void testUserDataUpdate() {
          final UserData__c userData = new UserData__c(
              Wrike_User_Id__c = 123,
              Online__c = false
          );
          test.startTest();
          insert userData;
          System.assert([SELECT Id, Online_Date__c FROM UserData__c WHERE Id = :userData.Id].Online_Date__c == NULL, 'Online Date should be null.');
          update new UserData__c(
              Id = userData.Id,
              Online__c = true
          );
          test.stopTest();
          System.assert([SELECT Id, Online_Date__c FROM UserData__c WHERE Id = :userData.Id].Online_Date__c != NULL, 'Online Date was not set.'); 
      }
      
      @IsTest
      public static void testUserDataSecondLoginDate() {
          final UserData__c userData = new UserData__c(
              Wrike_User_Id__c = 123,
              First_Active_Date__c = Date.today().addDays(-1)
          );
          insert userData;
          
          test.startTest();
          userData.Online__c = true;
          update userData;
          test.stopTest();
          
          final UserData__c insertedData = [SELECT Id, Second_Active_Date__c, Two_Login_Dates__c
                                            FROM UserData__c 
                                            WHERE Id = :userData.Id][0];
          System.assert(insertedData.Second_Active_Date__c == Date.today(), 'Second Active date was not set.');
          System.assert(insertedData.Two_Login_Dates__c == true, 'Two login dates checkbox was not set.');
      }
      
      @IsTest
      public static void testUserDataNoSecondLoginDate() {
          final UserData__c userData = new UserData__c(
              Wrike_User_Id__c = 123,
              First_Active_Date__c = Date.today()
          );
          insert userData;
          
          test.startTest();
          userData.Online__c = true;
          update userData;
          test.stopTest();
          
          final UserData__c insertedData = [SELECT Id, Second_Active_Date__c
                                            FROM UserData__c 
                                            WHERE Id = :userData.Id][0];
          System.assert(insertedData.Second_Active_Date__c == null, 'Second Active should not be set.');
      }
}
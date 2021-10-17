@IsTest
private class UserDataAfterCreateTriggerTest {

      @IsTest
      public static void testUserDataCreate() {
          final Lead lead = new Lead(
              FirstName = 'Test',
              LastName = 'Lead',
              Company = 'Test Company',
              LeadSource = 'Web',
              Lead_Sub_Source__c = 'Request',
              Wrike_User_Id__c = 123
          );
          insert lead;
          
          final UserData__c userData = new UserData__c(
              Wrike_User_Id__c = 123
          );
          
          test.startTest();
          insert userData;
          test.stopTest();
          
          System.assert([SELECT Id, Wrike_User_Data__c FROM Lead WHERE Id = :lead.Id].Wrike_User_Data__c == userData.Id, 'User Data was not set.');
      }
      
      @IsTest
      public static void testUserDataInsertLoginMQL() {
          final Lead lead = new Lead(
              FirstName = 'Test',
              LastName = 'Lead',
              Email = 'corporate.email@team.wrike.com',
              Company = 'Test Company',
              LeadSource = 'Web',
              Lead_Sub_Source__c = 'Request',
              Wrike_User_Id__c = 123
          );
          insert lead;
          
          final UserData__c userData = new UserData__c(
              Wrike_User_Id__c = 123,
              First_Active_Date__c = Date.today().addDays(-7)
          );
          
          test.startTest();
          insert userData;
          userData.Online__c = true;
          update userData;
          test.stopTest();
          
          final Lead updatedLead = [SELECT Id, MQL__c FROM Lead WHERE Id = :lead.Id][0];
          System.assert(updatedLead.MQL__c == true, 'MQL was not set.');
      }
      
      @IsTest
      public static void testUserDataInsertLoginGenericEmail() {
          final Lead lead = new Lead(
              FirstName = 'Test',
              LastName = 'Lead',
              Email = 'generic.email@gmail.com',
              Company = 'Test Company',
              LeadSource = 'Web',
              Lead_Sub_Source__c = 'Request',
              Wrike_User_Id__c = 123
          );
          insert lead;
          
          final UserData__c userData = new UserData__c(
              Wrike_User_Id__c = 123,
              First_Active_Date__c = Date.today().addDays(-7)
          );
          
          test.startTest();
          insert userData;
          userData.Online__c = true;
          update userData;
          test.stopTest();
          
          final Lead updatedLead = [SELECT Id, MQL__c FROM Lead WHERE Id = :lead.Id][0];
          System.assert(updatedLead.MQL__c == false, 'MQL was not set.');
      }
      
      @IsTest
      public static void testUserDataInsertNoSecondLogin() {
          final Lead lead = new Lead(
              FirstName = 'Test',
              LastName = 'Lead',
              Email = 'corporate.email@team.wrike.com',
              Company = 'Test Company',
              LeadSource = 'Web',
              Lead_Sub_Source__c = 'Request',
              Wrike_User_Id__c = 123
          );
          insert lead;
          
          final UserData__c userData = new UserData__c(
              Wrike_User_Id__c = 123,
              First_Active_Date__c = Date.today()
          );
          
          test.startTest();
          insert userData;
          test.stopTest();
          
          final Lead updatedLead = [SELECT Id, MQL__c FROM Lead WHERE Id = :lead.Id][0];
          System.assert(updatedLead.MQL__c == false, 'MQL was not set.');
      }
}
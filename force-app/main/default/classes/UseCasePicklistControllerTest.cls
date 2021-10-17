@isTest
public class UseCasePicklistControllerTest {
    
    public static final String VERTICAL = 'General / Organization Wide';
    public static final String B_AREA = 'General';
    public static final String P_USE_CASE = 'Agile';
    public static final String S_USE_CASE = 'Sprint Planning';
    
    @testSetup static void makeData(){
        //inserting a use case record
        Use_Case__c uc = new Use_Case__c(Team_Type__c  = 'Team (single team in a department)');
        insert uc;
    }
    
    @isTest static void getVBPSPicklistTest(){
        //testing the actual logic here
        Test.startTest();
        VBPSForm form = UseCasePicklistController.getVBPSPicklist();
        Test.stopTest();
        
        //Checking for asserts.
        System.assert(form != null);
    }
    
    @isTest static void saveUseCaseRecord(){
        //Querying the inserted use case record
        Use_Case__c uc = [SELECT Id FROM Use_Case__c LIMIT 1];
        
        //testing the actual logic here
        Test.startTest();
        UseCasePicklistController.saveUseCaseRecord(uc.Id, VERTICAL, B_AREA, P_USE_CASE, S_USE_CASE);
        Test.stopTest();
        
        //Querying the update use case record
        Use_Case__c updatedUC = [SELECT Id, Vertical2__c, Business_Area__c, Primary_Use_Case__c, Secondary_Use_Case__c 
                                 FROM Use_Case__c 
                               	 LIMIT 1
                                ];
        
        //Checking for asserts.
        System.assert(updatedUC.Vertical2__c == VERTICAL);
        System.assert(updatedUC.Business_Area__c == B_AREA);
        System.assert(updatedUC.Primary_Use_Case__c == P_USE_CASE);
        System.assert(updatedUC.Secondary_Use_Case__c == S_USE_CASE);
    }
}
@isTest
public class FieldSetControllerTest {
    public static String typeName = 'Opportunity';
    public static String fsName = 'lightningOppQualificationNotes';
	
    @testSetUp
    public static void dataSetUp(){
        Account newAccount = new Account(
            Name = 'Test Account'
        );
        insert newAccount;
        
        Contact newContact = new Contact(
            LastName = 'Test Contact',
            AccountId = newAccount.Id
        );
        insert newContact;
        
        Opportunity newOpp = new Opportunity(
            Name = 'Test Opp',
            AccountId = newAccount.Id,
            StageName = '0-MQL',
            CloseDate = System.today()
        );
        insert newOpp;
    }
    
    @isTest
    public static void testFieldSetForm(){
        List<Opportunity> oppList = [
            SELECT Id 
            FROM Opportunity 
            WHERE Name = 'Test Opp'
        ];
        
        Test.startTest();
        List<FieldSetMember> fieldSetMemeberList = FieldSetController.getFields(typeName, fsName);
        List<String> fieldSetControllerList = FieldSetController.getFieldSetNames(typeName);
        Boolean recordAccess = FieldSetController.getAccess(oppList[0].Id);
        Boolean fieldSet = FieldSetController.hasFieldSets(typeName);
        Test.stopTest();
        
        System.assertEquals(fieldSetMemeberList.size() > 0, true);
        System.assertEquals(fieldSetControllerList.size() > 0, true);
        System.assertEquals(recordAccess, true);
        System.assertEquals(fieldSet, true);
    }
}
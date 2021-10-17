@IsTest
public class AccountRelatedListControllerTest {
    
    private static final String ACCOUNT_NAME = 'AccountTest';
    
    @TestSetup
    public static void setup() {
        Account testAccount = TestDataFactory.createAccount(ACCOUNT_NAME);
        TestUtils.insertAndAssert(testAccount);
    }
    
    @IsTest
    static void testAccountRelatedNoteList(){
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(contact);
        
        Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        TestUtils.insertAndAssert(opportunity);
        
        Note testOppNote = new Note(
            Title = 'Test Opportunity Note',
            Body = 'Test Opportunity Note Body.',
            ParentId = opportunity.Id
        );
        insert testOppNote;
        
        Note testContactNote = new Note(
            Title = 'Test Contact Note',
            Body = 'Test Contact Note Body.',
            ParentId = contact.Id
        );
        insert testContactNote;
        
        Test.startTest();
        List<AccountRelatedListController.WrappedFile> relatedNoteList = AccountRelatedListController.getRelatedNotes(account.Id);
        Test.stopTest();
        
        System.assertEquals(false, relatedNoteList.isEmpty());
    }
    
    @IsTest
    static void testAccountRelatedFileList(){
        final Account account = TestUtils.findAccountByName(ACCOUNT_NAME);
        
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', 'testcontact@address.com');
        TestUtils.insertAndAssert(contact);
        
        final Id documentId = TestDataFactory.createFile(contact.Id, contact.Name + '.pdf');
        
        Test.startTest();
        List<AccountRelatedListController.WrappedFile> relatedFileList = AccountRelatedListController.getRelatedFiles(account.Id);
        Test.stopTest();
        
        System.assertEquals(false, relatedFileList.isEmpty());
    }
}
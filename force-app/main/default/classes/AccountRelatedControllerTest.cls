@IsTest
public class AccountRelatedControllerTest {
    
    @IsTest
    static void testAccountRelatedContracts(){
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        
        final Contract contract = new Contract(
            AccountId = account.Id
        );
        insert contract;
        
        Test.startTest();
        List<Contract> relatedContractList = AccountRelatedController.getContracts(account.Id);
        Test.stopTest();
        
        System.assertEquals(false, relatedContractList.isEmpty());
    }
    
    @IsTest
    static void testAccountRelatedOpportunities(){
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        
        final Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = account.Id
        );
        insert opportunity;
        
        Test.startTest();
        List<Opportunity> relatedOpportunityList = AccountRelatedController.getOpportunities(account.Id);
        Test.stopTest();
        
        System.assertEquals(false, relatedOpportunityList.isEmpty());
    }
}
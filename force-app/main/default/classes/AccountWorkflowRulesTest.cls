@IsTest
public class AccountWorkflowRulesTest {
    
    @IsTest
    public static void testCustomerAccountAssignment() {
        final User testUser = new User(
            Alias = 'testwfr', 
            Email='test.account.wfr@team.wrike.com', 
            EmailEncodingKey='UTF-8', 
            FirstName = 'Test',
            LastName='User', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='test.account.wfr@team.wrike.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id);
        insert testUser;  
    
        final Account account = new Account(
            OwnerId = testUser.Id,
            Name = StringUtils.generateRandomString(10),
            BillingCountryCode = 'US',
            Enterprise_Strategic_Acts__c = false);
        insert account;
        
        final Account entAccount = new Account(
            OwnerId = testUser.Id,
            Name = StringUtils.generateRandomString(10),
            BillingCountryCode = 'US',
            Enterprise_Strategic_Acts__c = true);
        insert entAccount;
            
        update new List<Account> {
            new Account(Id = account.Id, Type = 'Customer'), 
            new Account(Id = entAccount.Id, Type = 'Customer')};
            
        final Account updatedAccount = [SELECT OwnerId FROM Account WHERE Id = :account.Id];
        final Account updatedEntAccount = [SELECT OwnerId FROM Account WHERE Id = :entAccount.Id];
        System.assert(updatedAccount.OwnerId == WrikeConstants.SF_ADMIN_ID, 'Account was not reassigned to SFDC admin');
        System.assert(updatedEntAccount.OwnerId == testUser.Id, 'EAE Account should not be reassigned to SFDC admin');   
    }
}
@IsTest
public class CPQWrikeAccountGenerationControllerTest {

    @TestSetup
    static void setup() {
        TestDataFactory.insertSettings();
    }

    @IsTest
    static void testRegisterNewAccount() {
        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        final SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        Test.startTest();
        CPQWrikeAccountGenerationController.registerNewAccount(quote.Id, 'test@email.com');
        Test.stopTest();
        final SBQQ__Quote__c updatedQuote = [
                SELECT Id, WrikeAccountId__c
                FROM SBQQ__Quote__c
                WHERE Id = :quote.Id
        ];
        System.assertEquals(123, updatedQuote.WrikeAccountId__c);
    }

    @IsTest
    static void testFindAccounts() {
        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        Test.startTest();
        final CPQWrikeAccountGenerationController.FindAccountsResponse response =
                CPQWrikeAccountGenerationController.findAccounts('test@email.com');
        Test.stopTest();
        System.assert(response.wrikeAccounts != null);
        System.assert(response.wrikeAccounts.size() == 1);
        System.assertEquals(123, response.wrikeAccounts.get(0).id);
    }
}
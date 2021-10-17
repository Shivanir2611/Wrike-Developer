@IsTest
public class CPQOrderManagementJobTest {

    @IsTest
    static void testOrderCreation() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity renewalOpportunity = TestDataFactory.createOpportunity(account.Id, 123);
        renewalOpportunity.Type = 'Renewal';
        insert renewalOpportunity;
        final Id quoteId = TestDataFactory.createCPQQuote(123, 'Renewal');
        final Contract contract = TestDataFactory.createCPQContract(account.Id, 123);
        contract.AutoRenewalQuote__c = quoteId;
        contract.Auto_Renew__c = 'Yes';
        contract.SBQQ__RenewalOpportunity__c = renewalOpportunity.Id;
        contract.StartDate = Date.today().addMonths(-12);
        contract.EndDate = Date.today().addDays(-1);
        insert contract;
        contract.Status = 'Activated';
        update contract;
        update new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__Status__c = CPQQuote.DocumentGenerated
        );
        Test.startTest();
        Database.executeBatch(new CPQOrderManagementJob());
        Test.stopTest();
        final CPQQuote orderedQuote = CPQQuoteService.getInstance().findQuoteById(quoteId);
        System.assertEquals(CPQQuote.Ordered, orderedQuote.status);
        final Order order = CPQOrderQueryService.getInstance().findOrderByQuoteId(quoteId);
        System.assertNotEquals(null, order);
    }
}
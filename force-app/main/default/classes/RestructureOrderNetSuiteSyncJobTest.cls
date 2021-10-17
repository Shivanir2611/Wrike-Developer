@IsTest
public class RestructureOrderNetSuiteSyncJobTest {

    @IsTest
    static void testAllowOrderSync() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final SBQQ__Quote__c restructureNewQuote = createRestructureNewQuote(account.Id, opportunity.Id);
        insert restructureNewQuote;
        final Order restructureNewOrder = createOrder(account.Id, opportunity.Id, restructureNewQuote.Id, null);
        insert restructureNewOrder;
        createCancellationOrder(restructureNewQuote.Id, '123');
        createCancellationOrder(restructureNewQuote.Id, '456');

        Test.startTest();
        Database.executeBatch(new RestructureOrderNetSuiteSyncJob());
        Test.stopTest();

        System.assert(isOrderAllowedToSync(restructureNewOrder.Id));
    }

    @IsTest
    static void testDisallowOrderSync() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final SBQQ__Quote__c restructureNewQuote = createRestructureNewQuote(account.Id, opportunity.Id);
        insert restructureNewQuote;
        final Order restructureNewOrder = createOrder(account.Id, opportunity.Id, restructureNewQuote.Id, null);
        insert restructureNewOrder;
        createCancellationOrder(restructureNewQuote.Id, '123');
        createCancellationOrder(restructureNewQuote.Id, null);

        Test.startTest();
        Database.executeBatch(new RestructureOrderNetSuiteSyncJob());
        Test.stopTest();

        System.assert(!isOrderAllowedToSync(restructureNewOrder.Id));
    }

    private static void createCancellationOrder(final Id restructureNewQuoteId, final String netSuiteIntegrationId) {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = account.Id,
                SBQQ__Opportunity2__c = opportunity.Id,
                RestructureNewQuote__c = restructureNewQuoteId,
                SBQQ__Primary__c = true
        );
        insert quote;
        final Order order = createOrder(
                account.Id,
                opportunity.Id,
                quote.Id,
                netSuiteIntegrationId
        );
        insert order;
    }

    private static Boolean isOrderAllowedToSync(final Id orderId) {
        return [SELECT AllowNetSuiteSync__c FROM Order WHERE Id = :orderId].AllowNetSuiteSync__c;
    }

    private static SBQQ__Quote__c createRestructureNewQuote(final Id accountId, final Id opportunityId) {
        return new SBQQ__Quote__c(
                SBQQ__Account__c = accountId,
                SBQQ__Opportunity2__c = opportunityId,
                QuoteSubType__c = 'Restart Contract (new contract - create)',
                SBQQ__Primary__c = true
        );
    }

    private static Order createOrder(final Id accountId,
                                     final Id opportunityId,
                                     final Id quoteId,
                                     final String netSuiteIntegrationId) {
        return new Order(
                AccountId = accountId,
                SBQQ__Quote__c = quoteId,
                OpportunityId = opportunityId,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                NetSuite_Integration_ID__c = netSuiteIntegrationId
        );
    }
}
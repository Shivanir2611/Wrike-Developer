@IsTest
private class WrikeQuoteTriggerTest {

    @IsTest
    static void testSendQuoteInWrike() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity1 = TestDataFactory.createOpportunity(testAccount.Id, 123);
        TestUtils.insertAndAssert(testOpportunity1);
        Opportunity testOpportunity2 = TestDataFactory.createOpportunity(testAccount.Id, 123);
        TestUtils.insertAndAssert(testOpportunity2);

        Quote__c quote1 = TestDataFactory.createQuote(testOpportunity1.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(quote1);

        Quote__c quote2 = TestDataFactory.createQuote(testOpportunity1.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        quote2.Status__c = WrikeQuote.Status.TRIAL.name();
        TestUtils.insertAndAssert(quote2);

        Quote__c quote3 = TestDataFactory.createQuote(testOpportunity1.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        quote3.Status__c = WrikeQuote.Status.PROPOSAL.name();
        TestUtils.insertAndAssert(quote3);

        Quote__c quote4 = TestDataFactory.createQuote(testOpportunity2.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(quote4);

        Quote__c quote5 = TestDataFactory.createQuote(testOpportunity2.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        quote5.Status__c = WrikeQuote.Status.PROPOSAL.name();
        TestUtils.insertAndAssert(quote5);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        quote3.Status__c = WrikeQuote.Status.SENT.name();
        TestUtils.updateAndAssert(quote3);

        Test.stopTest();

        WrikeHttpMock.assertNumberOfActionInvocation('accepted_quote', 1);
    }
}
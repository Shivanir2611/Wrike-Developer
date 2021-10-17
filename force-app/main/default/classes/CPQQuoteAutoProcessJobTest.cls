@IsTest
public class CPQQuoteAutoProcessJobTest {

    @IsTest
    static void testQuoteOrderGeneration() {
        final Id quoteId = TestDataFactory.createCPQQuote(123, 'Quote');
        final CPQApi.QuoteModel quoteModel = CPQApi.getInstance().readQuote(quoteId);
        final CPQApi cpqApiMock = (CPQApi)MockApi.mock(CPQApi.class);
        MockApi.setup()
                .mockStrict(cpqApiMock.readQuote(quoteId), quoteModel)
                .mock(cpqApiMock.calculate(null), quoteModel)
                .build();
        Test.startTest();
        System.enqueueJob(new CPQQuoteAutoProcessJob(new List<Id> { quoteId }));
        Test.stopTest();
        final CPQQuote orderedQuote = CPQQuoteService.getInstance().findQuoteById(quoteId);
        System.assertEquals(CPQQuote.Ordered, orderedQuote.status);
    }
}
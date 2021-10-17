@IsTest
public class CPQQuoteLineTriggerTest {

    @IsTest
    static void testSetIsChangedOrAdded() {
        final Product2 product = new Product2(Name = 'Test Product');
        product.PG1__c = 'License';
        insert product;

        final SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;

        final SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                SBQQ__Quantity__c = 5,
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id
        );
        insert quoteLine;

        final SBQQ__QuoteLine__c updatedQuoteLine1 = findQuoteLineById(quoteLine.Id);
        System.assertEquals(true, updatedQuoteLine1.IsChangedOrAdded__c);
        System.assertEquals('License', updatedQuoteLine1.PG1__c);

        quoteLine.IsChangedOrAdded__c = false;
        update quoteLine;

        final SBQQ__QuoteLine__c updatedQuoteLine2 = findQuoteLineById(quoteLine.Id);
        System.assertEquals(false, updatedQuoteLine2.IsChangedOrAdded__c);

        quoteLine.SBQQ__Quantity__c = 10;
        update quoteLine;

        final SBQQ__QuoteLine__c updatedQuoteLine3 = findQuoteLineById(quoteLine.Id);
        System.assertEquals(true, updatedQuoteLine3.IsChangedOrAdded__c);
    }

    private static SBQQ__QuoteLine__c findQuoteLineById(final Id quoteLineId) {
        return [
                SELECT IsChangedOrAdded__c, PG1__c
                FROM SBQQ__QuoteLine__c
                WHERE Id = :quoteLineId
        ];
    }
}
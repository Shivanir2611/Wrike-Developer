@IsTest
public class CPQIntegrationTestDataServiceTest {

    @IsTest
    static void testInvalidAccount() {
        setRequest('unknownAction', '{}');
        final CPQIntegrationTestDataService.CPQTestResponse response = CPQIntegrationTestDataService.processRequest();
        System.assertEquals(false, response.getSuccess());
        System.assertNotEquals(null, response.getError());
        System.assert(response.getError().startsWith('Unknown action:'));
    }

    @IsTest
    static void testInvalidCreateQuoteRequest() {
        setRequest('createQuote', '{}');
        final CPQIntegrationTestDataService.CPQTestResponse response = CPQIntegrationTestDataService.processRequest();
        System.assertEquals(false, response.getSuccess());
        System.assertEquals('Invalid Wrike Account Id', response.getError());
    }

    @IsTest
    static void testCreateQuoteRequest() {
        setRequest('createQuote', '{' +
            '"wrikeAccountId": 12345,' +
            '"quoteStartDate": "' + String.valueOf(Date.today()) + '",' +
            '"quoteEndDate": "' + String.valueOf(Date.today().addYears(1).addDays(-1)) + '"' +
        '}');
        final CPQIntegrationTestDataService.CPQTestResponse response = CPQIntegrationTestDataService.processRequest();
        System.assertEquals(true, response.getSuccess());
        System.assertEquals(null, response.getError());
        System.assertNotEquals(null, response.getData());
        final Id quoteId = response.getData().get('quoteId');
        System.assertNotEquals(null, quoteId);
        final SBQQ__Quote__c quote = findQuoteById(quoteId);
        System.assertNotEquals(null, quote);
        System.assertNotEquals(null, quote.SBQQ__Account__r);
        System.assert(quote.SBQQ__Account__r.Name.startsWith('eComm Test'));
        System.assertNotEquals(null, quote.QS_Bill_To__c);
        System.assertNotEquals(null, quote.QS_Ship_To__c);
        System.assertEquals('Draft', quote.SBQQ__Status__c);
        System.assertEquals(true, quote.SBQQ__Primary__c);
    }

    @IsTest
    static void testAddProductsRequest() {
        final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
        insert pricebook;
        insert new CPQSettings__c(PriceBookName__c = 'Test Price Book');
        final Product2 product = new Product2(
                Name = 'Test Product',
                ZuoraServiceType__c = 'BusinessSeats',
                ProductCode = 'r-lic-base-Biz'
        );
        insert product;
        TestUtils.createPricebookEntry(product.Id, pricebook.Id, 10.10);
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft',
                CurrencyIsoCode = 'USD'
        );
        insert quote;
        insert new SBQQ__QuoteLineGroup__c(
                Name = 'Test Group',
                SBQQ__Number__c = 2,
                SBQQ__Quote__c = quote.Id
        );
        setRequest('addProducts', '{' +
            '"quoteId": "' + quote.Id + '",' +
            '"products": [{' +
                '"serviceType": "BusinessSeats", ' +
                '"quantity": 5' +
            '}]' +
        '}');
        final CPQIntegrationTestDataService.CPQTestResponse response = CPQIntegrationTestDataService.processRequest();
        System.assertEquals(true, response.getSuccess());
        System.assertEquals(null, response.getError());
        System.assertNotEquals(null, response.getData());
        final Id quoteId = response.getData().get('quoteId');
        System.assertNotEquals(null, quoteId);
        final List<SBQQ__QuoteLine__c> quoteLines = findQuoteLinesByQuoteId(quoteId);
        System.assert(!quoteLines.isEmpty());
        System.assertEquals(5, quoteLines.get(0).SBQQ__Quantity__c);
    }

    private static void setRequest(final String action, final String body) {
        final RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/cpqtest/' + action;
        request.httpMethod = 'POST';
        if(String.isNotBlank(body)) {
            request.requestBody = Blob.valueOf(body);
        }
        RestContext.request = request;
    }

    private static SBQQ__Quote__c findQuoteById(final Id quoteId) {
        final List<SBQQ__Quote__c> quotes = [
                SELECT SBQQ__Account__c, SBQQ__Account__r.Name, QS_Bill_To__c, QS_Ship_To__c,
                        SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__Status__c, SBQQ__Primary__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
        if(quotes.isEmpty()) {
            return null;
        }
        return quotes.get(0);
    }

    private static List<SBQQ__QuoteLine__c> findQuoteLinesByQuoteId(final Id quoteId) {
        return [
                SELECT SBQQ__Quantity__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
        ];
    }
}
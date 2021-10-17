@IsTest
public class QuoteUtilTest {

    @IsTest
    public static void testQuoteWrapper() {
        TestDataFactory.insertSettings();
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 100);
        TestUtils.insertAndAssert(opportunity);
        final Quote__c subscriptionQuote = TestDataFactory.createQuote(opportunity.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(subscriptionQuote);
        final Quote_Product__c quoteProduct = TestDataFactory.createQuoteProduct(100, 10, 5, 'PremiumSeats', 12, 'Annual');
        TestUtils.insertAndAssert(quoteProduct);
        final Quote_Item__c quoteItem = TestDataFactory.createQuoteItem(subscriptionQuote.Id, quoteProduct.Id, WrikeQuoteItem.State.ADDED);
        TestUtils.insertAndAssert(quoteItem);
        final WrikeQuote quote = QuoteService.getInstance().findWithItemsById(subscriptionQuote.Id);
        final QuoteUtil.QuoteWrapper quoteWrapper = new QuoteUtil.QuoteWrapper(quote);
        System.assert(quoteWrapper.products != null);
        System.assertEquals(1, quoteWrapper.products.size());
        final Map<String, Object> details = (Map<String, Object>)quoteWrapper.details;
        System.assert(details != null);
        System.assertEquals(2, details.get('version'));
        System.assertEquals(Date.today(), details.get('effectiveDate'));
        final String encryptedId = (String)details.get('encryptedId');
        System.assert(String.isNotBlank(encryptedId), 'Encrypted id is blank.');
        System.assertEquals(quote.id, WrikeUtil.decrypt(EncodingUtil.urlDecode(encryptedId, 'UTF-8')));
    }
}
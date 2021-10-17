@IsTest
public class QuoteBundleTest {

    @IsTest(SeeAllData = true) // SeeAllData is required for Zuora API objects
    static void testQuoteBundle() {
        final Id quoteId = createNewSubscriptionQuote();
        final WrikeQuote quote = QuoteService.getInstance().findWithItemsById(quoteId);
        final WrikeQuoteZuoraService.SubscriptionPreview subscriptionPreview = TestDataFactory.generateSubscriptionPreview(quoteId);
        final QuoteBundle quoteBundle = new QuoteBundle.Builder(
                quote,
                subscriptionPreview.getInvoicePreview().items
        ).build();
        System.assertEquals(3600.0, quoteBundle.getRecurrentListRateAdded());
        System.assertEquals(3330.0, quoteBundle.getRecurrentEffectiveRateAdded());
        System.assertEquals(0.0, quoteBundle.getRecurrentEffectiveRateRemoved());
        System.assertEquals(3330.0, quoteBundle.getRecurrentTotalPrice());
        System.assertEquals(2500.0, quoteBundle.getOneTimeListPrice());
        System.assertEquals(2000.0, quoteBundle.getOneTimeEffectivePrice());
        System.assertEquals(5330.0, quoteBundle.getInitialPaymentTotal());
        System.assertEquals(1, quoteBundle.getRecurrentItems().size());
        System.assertEquals(0, quoteBundle.getRecurrentItemsRemoved());
        System.assertEquals(1, quoteBundle.getRecurrentItemsAdded());
        System.assertEquals(true, quoteBundle.getRenewalItems().isEmpty());
        System.assertEquals(0.0, quoteBundle.getRenewalEffectiveRate());
        System.assertEquals(0.0, quoteBundle.getRenewalListRate());
        System.assertEquals(0.0, quoteBundle.getRenewalTotalPrice());
        System.assertEquals(null, quoteBundle.getPartnerCommissionItem());
        final QuoteBundleLineItem recurrentItem = quoteBundle.getRecurrentItems()[0];
        System.assertEquals(3600.0, recurrentItem.getBillingPeriodListPrice());
        System.assertEquals(3330.0, recurrentItem.getChargeAmount());
        System.assertEquals(5, recurrentItem.getQuantity());
        System.assertEquals(12, recurrentItem.getBillingPeriodMonths());
        System.assertEquals(2, recurrentItem.getItems().size());
        System.assertEquals(1, quoteBundle.getOneTimeItems().size());
        final QuoteBundleLineItem oneTimeItem = quoteBundle.getOneTimeItems()[0];
        System.assertEquals(2000.0, oneTimeItem.getChargeAmount());
        System.assertEquals(1, oneTimeItem.getItems().size());
    }

    private static Id createNewSubscriptionQuote() {
        final Account account = TestDataFactory.createAccount('Test Bundle Account ');
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 12345);
        insert opportunity;
        final Quote__c quoteRecord = TestDataFactory.createQuote(opportunity.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        insert quoteRecord;
        return quoteRecord.Id;
    }
}
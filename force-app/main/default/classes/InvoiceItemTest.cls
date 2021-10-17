@IsTest
public class InvoiceItemTest {

    @IsTest
    public static void testCompareTo() {
        final WrikeQuoteProduct product = new WrikeQuoteProduct();
        product.zuoraProductId = '2c92c0f94b4e2e1b014b56830eb27ea9';
        product.chargeType = ZuoraRestQueryService.RECURRING;
        product.name = 'Enterprise Subscription Licenses';
        final WrikeQuoteItem productItem = new WrikeQuoteItem();
        productItem.product = product;
        productItem.state = WrikeQuoteItem.State.ADDED;
        final InvoiceItem one = new InvoiceItem(
            productItem,
            15,
            Date.today().addDays(-10),
            Date.today(),
            100.0,
            new WrikeQuote());
        final InvoiceItem two = (InvoiceItem) one.clone();
        two.serviceStartDate = Date.today();
        two.serviceEndDate = Date.today().addDays(10);
        System.assert(one.compareTo(two) < 0, 'CompareTo result is not valid.');
        System.assert(two.compareTo(one) > 0, 'CompareTo result is not valid.');
    }
    
    @IsTest
    public static void testProrationCreditChargeType() {
        final WrikeQuoteProduct product = new WrikeQuoteProduct();
        product.zuoraProductId = '2c92c0f94b4e2e1b014b56830eb27ea9';
        product.chargeType = ZuoraRestQueryService.RECURRING;
        product.name = 'Enterprise Subscription Licenses';
        final WrikeQuoteItem productItem = new WrikeQuoteItem();
        productItem.product = product;
        productItem.state = WrikeQuoteItem.State.REMOVED;
        final InvoiceItem invoiceItem = new InvoiceItem(
            productItem,
            15,
            Date.today().addDays(-30),
            Date.today(),
            -100.0,
            new WrikeQuote());
        System.assertEquals('Proration Credit', invoiceItem.getChargeType());
    }
    
    @IsTest
    public static void testProrationChargeType() {
        final WrikeQuoteProduct product = new WrikeQuoteProduct();
        product.zuoraProductId = '2c92c0f94b4e2e1b014b56830eb27ea9';
        product.chargeType = ZuoraRestQueryService.RECURRING;
        product.name = 'Enterprise Subscription Licenses';
        final WrikeQuoteItem productItem = new WrikeQuoteItem();
        productItem.product = product;
        productItem.state = WrikeQuoteItem.State.ADDED;
        final WrikeQuote quote = new WrikeQuote();
        quote.amendmentType = WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL;
        quote.subscriptionEndDate = Date.today();
        final InvoiceItem invoiceItem = new InvoiceItem(
            productItem,
            15,
            Date.today().addDays(-30),
            Date.today(),
            100.0,
            quote);
        System.assertEquals('Proration', invoiceItem.getChargeType());
    }
}
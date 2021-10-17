@IsTest
public class InvoicePreviewTest {

    private static final Invoice invoiceDateYesterday = new Invoice(Date.today().addDays(-1));
    private static final Invoice invoiceDateTomorrow = new Invoice(Date.today().addDays(1));

    @IsTest
    static void testInvoicePeviewInit() {
        final Invoice invoice = new Invoice(Date.today());
        final InvoicePreview ip = new InvoicePreview(Date.today(), new List<Invoice> {invoice});

        final List<Invoice> invoices = ip.getInvoices();
        System.assert(invoices.size() == 1);
        System.assert(invoices[0].getInvoiceDate() == invoice.getInvoiceDate());

        //just coverage
        final Decimal tca = ip.totalChargeAmount;
        final Decimal dm = ip.deltaMrr;
    }

    @IsTest
    static void testGetFirstInvoiceDate() {

        final InvoicePreview ip1 = new InvoicePreview(Date.today(), new List<Invoice>());
        final InvoicePreview ip2 = new InvoicePreview(null, new List<Invoice> { invoiceDateYesterday });
        final InvoicePreview ip3 = new InvoicePreview(null, new List<Invoice> { invoiceDateYesterday, invoiceDateTomorrow });
        final InvoicePreview ip4 = new InvoicePreview(Date.today().addDays(11), new List<Invoice> { invoiceDateYesterday, invoiceDateTomorrow });
        final InvoicePreview ip5 = new InvoicePreview(null, new List<Invoice> { invoiceDateTomorrow, invoiceDateYesterday });

        final Date fiDate1 = ip1.getFirstInvoiceDate();
        final Date fiDate2 = ip2.getFirstInvoiceDate();
        final Date fiDate3 = ip3.getFirstInvoiceDate();
        final Date fiDate4 = ip4.getFirstInvoiceDate();
        final Date fiDate5 = ip5.getFirstInvoiceDate();

        System.assert(fiDate1.isSameDay(Date.today()));
        System.assert(fiDate2.isSameDay(invoiceDateYesterday.getInvoiceDate()));
        System.assert(fiDate3.isSameDay(invoiceDateYesterday.getInvoiceDate()));
        System.assert(fiDate4.isSameDay(Date.today().addDays(11)));
        System.assert(fiDate5.isSameDay(Date.today()));
    }

    @IsTest
    static void testGetTargetInvoiceDate() {

        final InvoicePreview ip1 = new InvoicePreview(null, new List<Invoice>());
        final InvoicePreview ip2 = new InvoicePreview(Date.today(), new List<Invoice>());
        final InvoicePreview ip3 = new InvoicePreview(null, new List<Invoice> { invoiceDateYesterday });
        final InvoicePreview ip4 = new InvoicePreview(Date.today().addDays(11), new List<Invoice> { invoiceDateYesterday, invoiceDateTomorrow });

        final Date targetDate1 = ip1.getTargetInvoiceDate();
        final Date targetDate2 = ip2.getTargetInvoiceDate();
        final Date targetDate3 = ip3.getTargetInvoiceDate();
        final Date targetDate4 = ip4.getTargetInvoiceDate();

        System.assert(targetDate1 == null);
        System.assert(targetDate2 == null);
        System.assert(targetDate3.isSameDay(invoiceDateYesterday.getInvoiceDate()));
        System.assert(targetDate4.isSameDay(invoiceDateYesterday.getInvoiceDate()));
    }
}
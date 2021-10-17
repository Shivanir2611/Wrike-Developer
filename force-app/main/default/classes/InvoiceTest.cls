@IsTest
public class InvoiceTest {

    @IsTest
    public static void testAddItem() {
        final Invoice invoice = new Invoice(Date.today());
        invoice.addItem(TestDataFactory.createInvoiceItem(Date.today().addDays(-30), Date.today(), -100));
        invoice.addItem(TestDataFactory.createInvoiceItem(Date.today(), Date.today().addDays(30), 75));
        invoice.addItem(TestDataFactory.createInvoiceItem(Date.today().addDays(30), Date.today().addDays(60), 75));
        System.assertEquals(3, invoice.getItems().size());
        System.assertEquals(50, invoice.getChargeAmount());
        System.assertEquals(Date.today(), invoice.getTargetInvoiceDate());
    }

    @IsTest
    public static void testMergeInvoice() {
        final Invoice invoice1 = new Invoice(Date.today());
        invoice1.addItem(TestDataFactory.createInvoiceItem(Date.today(), Date.today(), 100));
        final Invoice invoice2 = new Invoice(Date.today().addDays(30));
        invoice2.addItem(TestDataFactory.createInvoiceItem(Date.today().addDays(30), Date.today().addDays(60), 200));
        invoice1.mergeInvoice(invoice2);
        System.assertEquals(2, invoice1.getItems().size());
        System.assertEquals(Date.today().addDays(30), invoice1.getTargetInvoiceDate());
    }
}
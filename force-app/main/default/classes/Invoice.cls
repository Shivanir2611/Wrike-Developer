public class Invoice {
    private Date invoiceDate;
    private Date targetInvoiceDate;
    private Decimal chargeAmount = 0;
    private List<InvoiceItem> items = new List<InvoiceItem>();
    
    public Invoice(final Date invoiceDate) {
        this.invoiceDate = invoiceDate;
        this.targetInvoiceDate = invoiceDate;
    }
    
    public void addItem(final InvoiceItem invoiceItem) {
        items.add(invoiceItem);
        this.chargeAmount = this.chargeAmount + invoiceItem.chargeAmount;
    }
    
    public void mergeInvoice(final Invoice invoice) {
        this.targetInvoiceDate = invoice.invoiceDate;
        for(InvoiceItem invoiceItem : invoice.getItems()) {
            this.addItem(invoiceItem);
        }
    }
    
    public List<InvoiceItem> getItems() {
        return this.items;
    }
    
    public Date getInvoiceDate() {
        return this.invoiceDate;
    }
    
    public Date getTargetInvoiceDate() {
        return this.targetInvoiceDate;
    }

    public Decimal getChargeAmount() {
        return this.chargeAmount;
    }
}
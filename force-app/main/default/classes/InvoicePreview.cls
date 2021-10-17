public class InvoicePreview {
    private List<Invoice> invoices;
    public List<ProductItem> items {get; set;}
    public Decimal totalChargeAmount {get; set;}
    public Decimal deltaMrr {get; set;}
    private Date invoiceDate;
    private Date targetInvoiceDate;
    
    public InvoicePreview(final Date invoiceDate, final List<Invoice> invoices) {
        this.invoices = invoices;
        this.invoiceDate = invoiceDate;
        if(!invoices.isEmpty()) {
            this.targetInvoiceDate = invoices[0].getTargetInvoiceDate();
        }
    }

    public void setProductItems(final List<ProductItem> items) {
        this.items = items;
    }

    public void setInvoices(final List<Invoice> invoices) {
        this.invoices = invoices;
    }

    public List<Invoice> getInvoices() {
        return this.invoices;
    }
    
    public Date getFirstInvoiceDate() {
        if(this.invoiceDate != null) {
            return this.invoiceDate;
        } else if(!invoices.isEmpty() && Date.today() > invoices[0].getInvoiceDate()) {
            return invoices[0].getInvoiceDate();
        }
        return Date.today();
    }
    
    public Date getTargetInvoiceDate() {
        return this.targetInvoiceDate;
    }

    public Boolean getContainsWrikeAnalyze() {
        final ZuoraProductValidationService zuoraProductValidationSrv = ZuoraProductValidationService.getInstance();
        if(items != null) {
            for(ProductItem item : items) {
                if(item.getType() == 'Added' && (
                        zuoraProductValidationSrv.isWrikeAnalyzeAddon(item.productServiceType)
                        || zuoraProductValidationSrv.isPerformancePackage(item.productServiceType))) {
                    return true;
                }
            }
        }
        return false;
    }

    public Boolean getContainsWrikeIntegrate() {
        final ZuoraProductValidationService zuoraProductValidationSrv = ZuoraProductValidationService.getInstance();
        if(items != null) {
            for(ProductItem item : items) {
                if(item.getType() == 'Added' && (
                    zuoraProductValidationSrv.isWrikeIntegrate(item.productName)
                        || zuoraProductValidationSrv.isPerformancePackage(item.productServiceType))) {
                    return true;
                }
            }
        }
        return false;
    }

    public Boolean getContainsWrikeIntegrateStandardOrEnhanced() {
        final ZuoraProductValidationService zuoraProductValidationSrv = ZuoraProductValidationService.getInstance();
        if(items != null) {
            for(ProductItem item : items) {
                if(item.getType() == 'Added'
                        && (zuoraProductValidationSrv.isWrikeIntegrateStandard(item.productName)
                                || zuoraProductValidationSrv.isWrikeIntegrateEnhanced(item.productServiceType))) {
                    return true;
                }
            }
        }
        return false;
    }

    public Boolean getContainsWrikePerformancePackage() {
        final ZuoraProductValidationService zuoraProductValidationSrv = ZuoraProductValidationService.getInstance();
        if(items != null) {
            for(ProductItem item : items) {
                if(item.getType() == 'Added' && zuoraProductValidationSrv.isPerformancePackage(item.productServiceType)) {
                    return true;
                }
            }
        }
        return false;
    }

    public Boolean getContainsWrikeMarketingInsightsStandard() {
        final ZuoraProductValidationService zuoraProductValidationSrv = ZuoraProductValidationService.getInstance();
        if(items != null) {
            for(ProductItem item : items) {
                if(item.getType() == 'Added' && zuoraProductValidationSrv.isMarketingInsightsStandard(item.productServiceType)) {
                    return true;
                }
            }
        }
        return false;
    }

    public Boolean getContainsWrikeMarketingInsightsEnhanced() {
        final ZuoraProductValidationService zuoraProductValidationSrv = ZuoraProductValidationService.getInstance();
        if(items != null) {
            for(ProductItem item : items) {
                if(item.getType() == 'Added' && zuoraProductValidationSrv.isMarketingInsightsEnhanced(item.productServiceType)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    public Boolean getContainsWrikeLock() {
        final ZuoraProductValidationService zuoraProductValidationSrv = ZuoraProductValidationService.getInstance();
        if(items != null) {
            for(ProductItem item : items) {
                if(item.getType() == 'Added' && zuoraProductValidationSrv.isWrikeLockAddon(item.productServiceType)) {
                    return true;
                }
            }
        }
        return false;
    }
}
public class WrikeQuotePdfTemplateController {
    private WrikeQuote quote;
    private DeploymentLanguageData deploymentLanguageData;
    private InvoicePreview invoicePreview;
    private Boolean noListPrice;
    
    public WrikeQuotePdfTemplateController() {
        final QuoteService quoteSrv = QuoteService.getInstance();
        final String encryptedQuoteId = ApexPages.currentPage().getParameters().get('quoteId');
        final Id quoteId = WrikeUtil.getDecryptedId(encryptedQuoteId);
        if(quoteId != null) {
            try {
                this.quote = quoteSrv.findWithItemsAndOpportunityAndContactById(quoteId, false).wQuote;
                this.deploymentLanguageData = new DeploymentLanguageData(this.quote.items);
                this.invoicePreview = quoteSrv.getSavedSubscriptionPreview(quoteId).getInvoicePreview();
                this.noListPrice = ApexPages.currentPage().getParameters().get('noListPrice') == 'true';
            } catch (LogicException e) {
                System.debug(Logginglevel.ERROR, e.getMessage());        
            }
        }
    }
    
    public WrikeQuote getQuote() {
        return quote;
    }
    
    public InvoicePreview getInvoicePreview() {
        return this.invoicePreview;
    }

    public QuoteBundle getQuoteBundle() {
        return new QuoteBundle.Builder(
                this.quote,
                this.invoicePreview.items
        ).build();
    }

    public Boolean getNoListPrice() {
        return noListPrice;
    }

    public WrikeQuotePdfTemplateController getController() {
        return this;
    }

    public DeploymentLanguageData getDeploymentLanguageData() {
        return this.deploymentLanguageData;
    }

    public Boolean getRenderAdditionalTerms() {
        return this.quote.publicityRightsRemoval || this.quote.coMarketingAddition || this.quote.governingLaw != null;
    }

    public class DeploymentLanguageData {
        private final Set<String> exhibitSet = new Set<String>();
        private Boolean custom = false;
        private Boolean pilot = false;
        private Boolean display = false;

        private DeploymentLanguageData(final List<WrikeQuoteItem> quoteItems) {
            final ProductService productService = ProductService.getInstance();
            final ZuoraProductService zuoraProductService = ZuoraProductService.getInstance();
            for(WrikeQuoteItem item : quoteItems) {
                if(!item.getIsRemoved() && zuoraProductService.isImplementation(item.product.serviceType)) {
                    final String ratePlanName = StringUtils.defaultIfBlank(item.product.zuoraProductRatePlanChargeName, '');
                    this.display = true;
                    this.custom = this.custom || ratePlanName.contains('Custom');
                    if(ratePlanName.contains('Standard Pilot')) {
                        this.pilot = true;
                        exhibitSet.addAll(new List<String> { 'B', 'C', 'D' });
                    }
                    final WrikeProduct product = productService.findProductById(item.product.product2Id);
                    if(String.isNotBlank(product.deploymentExhibit)) {
                        exhibitSet.add(product.deploymentExhibit);
                    }
                }
            }
        }

        public String getExhibits() {
            return String.join(new List<String> (exhibitSet), ',');
        }

        public Boolean getCustom() {
            return custom;
        }

        public Boolean getPilot() {
            return pilot;
        }

        public Boolean getDisplay() {
            return display;
        }
    }
}
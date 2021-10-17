global virtual class WrikeQuoteZuoraService {

    private final Zuora.zApi zuorApi = ZuoraApi.getInstance().getZApiAndLogin();
    private WrikeQuoteRequestService wrikeQuoteRequestSrv = WrikeQuoteRequestService.getInstance();
    private QuoteService quoteSrv = QuoteService.getInstance();
    private OpportunityDataService opportunityDataSrv = OpportunityDataService.getInstance();
    private final ZuoraService zuoraSrv = ZuoraService.getInstance();
    private final ZuoraRestUpdateService zuoraRestUpdateSrv = ZuoraRestUpdateService.getInstance();
    private static final Logger log = Logger.create(WrikeQuoteZuoraService.class);

    public static WrikeQuoteZuoraService getInstance() {
        return (WrikeQuoteZuoraService)ServiceLocator.getInstance(WrikeQuoteZuoraService.class);
    }

    public virtual List<Zuora.zApi.SubscribeResult> zSubscribe(List<Zuora.zApi.SubscribeRequest> subscribeRequests) {
        return (List<Zuora.zApi.SubscribeResult>)zuorApi.zsubscribe(subscribeRequests);
    }

    public virtual Zuora.zApi.AmendResult zamend(List<Zuora.zApi.AmendRequest> amendRequest) {
        return zuorApi.zamend(amendRequest);
    }

    public SubscriptionPreview createSubscriptionPreview(final QuoteService.StatusLock statusLock) {
        final WrikeQuote quote = quoteSrv.findWithItemsById(statusLock.getQuoteId());
        final WrikeQuoteRequestService.SubscriptionRequest request = wrikeQuoteRequestSrv.createSubscriptionRequest(quote, null, true);
        final SubscriptionPreviewBuilder previewBuilder = new SubscriptionPreviewBuilder(quote);
        if(request.getAmendRequest() != null) {
            final Zuora.zApi.AmendResult result = zamend(new List<Zuora.zApi.AmendRequest> {
                request.getAmendRequest()
            });
            previewBuilder.setSuccess(result.Success)
                .addInvoiceData(result.invoiceDatas)
                .addErrors(result.errors)
                .addDeltaMrr(result.totalDeltaMrr);
        }
        if(request.getSubscribeRequest() != null) {
            final List<Zuora.zApi.SubscribeResult> results = zSubscribe(new List<Zuora.zApi.SubscribeRequest> {
                request.getSubscribeRequest()
            });
            previewBuilder.setSuccess(results[0].Success)
                .addInvoiceData(results[0].invoiceDatas)
                .addErrors(results[0].errors)
                .addDeltaMrr(results[0].totalMrr);
        }
        return previewBuilder.build();
    }
    
    public SubscriptionResult sendQuote(final SendQuoteRequest request) {
        final QuoteService.StatusLock statusLock = quoteSrv.getStatusLock(request.getQuoteId());
        System.assertEquals(WrikeQuote.Status.PROPOSAL.name(), statusLock.getStatus());
        final WrikeQuote quote = quoteSrv.findWithItemsById(statusLock.getQuoteId());
        log.infoToLog('sendQuote... quote: ' + quote.quoteNumber, JSON.serialize(quote));
        log.infoToLog('sendQuote... request: ' + quote.quoteNumber, JSON.serialize(request));
        final SubscriptionResultBuilder resultBuilder = new SubscriptionResultBuilder();
        final WrikeQuoteZuoraService.SubscriptionPreview preview = createSubscriptionPreview(statusLock);
        if(!preview.isSuccess()) {
            resultBuilder.setSuccess(false).setError(preview.getError());
        } else {
            if(quote.total != preview.getInvoicePreview().totalChargeAmount ||
               quote.deltaMrr != preview.getInvoicePreview().deltaMrr ||
               quote.targetInvoiceDate != preview.getInvoicePreview().getTargetInvoiceDate()) {
               resultBuilder.setSuccess(false).setError(new Error('Saved invoice preview does not match the current quote.'));
            } else {
                final ZuoraObject.ZuoraAccount zuoraAccount = ZuoraRestQueryService.getInstance().findZuoraAccountByWrikeAccountId(quote.wrikeAccountId);
                if(zuoraAccount != null
                        && zuoraAccount.status == 'Draft'
                        && zuoraAccount.currencyCode != quote.quoteCurrency.name()) {
                    final QuoteService.ZuoraAccountResult zuoraAccountResult = this.quoteSrv.sendNewQuoteToWrike(quote);
                    System.assertEquals(quote.zuoraAccountId, zuoraAccountResult.getZuoraAccountId(), 'Zuora Account id mismatch.');
                }
                zuoraSrv.updatePaymentInfo(
                    quote.zuoraAccountId,
                    true,
                    request.getBillingInfo(), 
                    request.getCreditCardId(), 
                    request.getVatNumber(), 
                    quote.paymentTerm, 
                    quote.companyName);
                if (!quote.getIsSubscription() && !quote.isNewBillingCycle()) {
                    zuoraRestUpdateSrv.updateSubscriptionPurchaseOrderNumber(quote.zuoraSubscriptionId, request.getPurchaseOrderNumber());
                }
                sendQuote(quote, request, resultBuilder);
            }
        }
        final SubscriptionResult result = resultBuilder.build();
        log.infoToLog(quote.quoteNumber + ' subscription result: ' + result.isSuccess(), JSON.serialize(result));
        if(result.isSuccess()) {
            if(quote.getIsAmendment() || quote.getIsRenewal()) {
                zuoraSrv.generateInvoice(quote.zuoraAccountId,
                        preview.getInvoicePreview().getFirstInvoiceDate(),
                        preview.getInvoicePreview().getTargetInvoiceDate());
            }
            quoteSrv.markQuoteSentToZuora(statusLock);
            final WrikeQuoteProduct implementationProduct = quote.getImplementationProduct();
            if (implementationProduct != null) {
                opportunityDataSrv.setDeploymentPrice(quote.opportunity.opportunityDataId, implementationProduct);
            }

        }
        log.saveLog();
        return result;
    }
    
    private void sendQuote(final WrikeQuote quote,
                           final SendQuoteRequest request,
                           final SubscriptionResultBuilder resultBuilder) {
        final WrikeQuoteRequestService.SubscriptionRequest subscriptionRequest = wrikeQuoteRequestSrv.createSubscriptionRequest(quote, request, false);
        if(subscriptionRequest.getSubscribeRequest() == null && subscriptionRequest.getAmendRequest() == null) {
            resultBuilder.setSuccess(false).setError(new Error('No subscription or amendment request to send to Zuora.'));    
        }
        if(subscriptionRequest.getAmendRequest() != null) {
            final Zuora.zApi.AmendResult result = zamend(new List<Zuora.zApi.AmendRequest> {
                subscriptionRequest.getAmendRequest()
            });
            resultBuilder.setSuccess(result.Success).setError(result.errors);
            if(subscriptionRequest.getSubscribeRequest() == null) {
                resultBuilder.setSubscriptionId(result.SubscriptionId);
            }
        }
        if(subscriptionRequest.getSubscribeRequest() != null) {
            final List<Zuora.zApi.SubscribeResult> results = zsubscribe(new List<Zuora.zApi.SubscribeRequest> {
                subscriptionRequest.getSubscribeRequest()
            });
            resultBuilder.setSuccess(results[0].Success)
                .setError(results[0].errors)
                .setSubscriptionId(results[0].SubscriptionId);
        }
    }
    
    public class SubscriptionPreviewBuilder {
        private final WrikeQuote quote;
        private Boolean success = true;
        private Decimal deltaMrr = 0;
        private List<Zuora.zObject> invoiceDataList = new List<Zuora.zObject>();
        private List<Zuora.zObject> errors = new List<Zuora.zObject>();

        public SubscriptionPreviewBuilder(final WrikeQuote quote) {
            this.quote = quote;
        }

        public SubscriptionPreviewBuilder setSuccess(final Boolean success) {
            this.success = this.success && success;
            return this;
        }
        
        public SubscriptionPreviewBuilder addDeltaMrr(final Decimal deltaMrr) {
            if(deltaMrr != null) {
                this.deltaMrr = this.deltaMrr + deltaMrr;
            }
            return this; 
        }
        
        public SubscriptionPreviewBuilder addInvoiceData(final List<Zuora.zObject> invoiceData) {
            if(invoiceData != null) {
                this.invoiceDataList.addAll(invoiceData);
            }
            return this;
        }

        public SubscriptionPreviewBuilder addErrors(final List<Zuora.zObject> errors) {
            if(errors != null) {
                this.errors.addAll(errors);
            }
            return this;
        }
        
        public SubscriptionPreview build() {
            if(!this.success) {
                return new SubscriptionPreview(false, null, this.errors.isEmpty() ? null : new Error(this.errors[0]));
            }
            final List<InvoiceItem> invoiceItems = getSortedInvoiceItems();
            final Map<Date, Invoice> invoiceMap = getInvoiceMap(invoiceItems);
            final List<Invoice> invoices = getInvoices(invoiceMap);
            final List<ProductItem> productItems = getProductItems(invoiceItems);
            final InvoicePreview invoicePreview = new InvoicePreview(quote.invoiceDate, invoices);
            invoicePreview.setProductItems(productItems);
            invoicePreview.deltaMrr = deltaMrr;
            invoicePreview.totalChargeAmount = 0;
            for(InvoiceItem invoiceItem : invoiceItems) {
                invoicePreview.totalChargeAmount = invoicePreview.totalChargeAmount + invoiceItem.chargeAmount;
            }
            return new SubscriptionPreview(true, invoicePreview, null);
        }

        private WrikeQuoteItem findProductItem(final Zuora.zObject invoiceItem) {
            final String chargeNumber = (String)invoiceItem.getValue('ChargeNumber');
            final String chargeDescription = (String)invoiceItem.getValue('ChargeDescription');
            for(WrikeQuoteItem quoteItem : quote.items) {
                if((chargeNumber != null && chargeNumber == quoteItem.product.chargeNumber)
                        || (chargeDescription == String.valueOf(quoteItem.id))) {
                    return quoteItem;
                }
            }
            return null;
        }

        private List<InvoiceItem> getSortedInvoiceItems() {
            final List<InvoiceItem> invoiceItems = new List<InvoiceItem>();
            if(invoiceDataList != null) {
                for(Zuora.zObject invoiceData : invoiceDataList) {
                    final List<Object> items = invoiceData.getArrayValue('InvoiceItem');
                    if(items != null) {
                        for(Object obj : items) {
                            final Zuora.zObject item = (Zuora.zObject) obj;
                            final Date serviceStartDate = Date.valueOf((String)item.getValue('ServiceStartDate'));
                            final Date serviceEndDate = Date.valueOf((String)item.getValue('ServiceEndDate'));
                            if(serviceStartDate >= quote.effectiveDate) {
                                final WrikeQuoteItem productItem = findProductItem(item);
                                if(productItem != null && (!productItem.getIsExisting() || serviceStartDate >= quote.subscriptionEndDate)) {
                                    invoiceItems.add(new InvoiceItem(
                                        productItem,
                                        (Decimal)item.getValue('Quantity'),
                                        serviceStartDate,
                                        serviceEndDate,
                                        (Decimal)item.getValue('ChargeAmount'),
                                        quote
                                    ));
                                }
                            }
                        }
                    }
                }
            }
            invoiceItems.sort();
            return invoiceItems;
        }
        
        private List<Invoice> getInvoices(final Map<Date, Invoice> invoiceMap) {
            final List<Invoice> invoices = new List<Invoice>();
            final List<Date> invoiceDates = new List<Date> (invoiceMap.keySet());
            invoiceDates.sort();
            for(Date invoiceDate : invoiceDates) {
                final Invoice invoice = invoiceMap.get(invoiceDate);
                if(invoices.size() == 1 && invoices[0].getChargeAmount() <= 0) {
                    invoices[0].mergeInvoice(invoice);
                } else {
                    invoices.add(invoice);
                }
            }
            for(Invoice invoice : invoices) {
                invoice.getItems().sort();
            }
            return invoices;
        }
        
        private Map<Date, Invoice> getInvoiceMap(final List<InvoiceItem> invoiceItems) {
            final Map<Date, Invoice> itemMap = new Map<Date, Invoice>();
            for(InvoiceItem invoiceItem : invoiceItems) {
                final Date invoiceItemDate = invoiceItem.prorationCredit ? quote.effectiveDate : invoiceItem.serviceStartDate;
                if(!itemMap.containsKey(invoiceItemDate)) {
                    itemMap.put(invoiceItemDate, new Invoice(invoiceItemDate));
                }
                itemMap.get(invoiceItemDate).addItem(invoiceItem);
            }
            return itemMap;
        }
        
        private List<ProductItem> getProductItems(final List<InvoiceItem> invoiceItems) {
            final List<ProductItem> productItems = new List<ProductItem>();
            for(InvoiceItem invoiceItem : invoiceItems) {
                productItems.add(new ProductItem(invoiceItem, quote));
            }
            return productItems;
        }
    }
    
    public class SubscriptionPreview {
        private final Boolean success;
        private final InvoicePreview invoicePreview;
        private final Error error;
        
        public SubscriptionPreview(final Boolean success,
                                   final InvoicePreview invoicePreview,
                                   final Error error) {
            this.success = success;
            this.invoicePreview = invoicePreview; 
            this.error = error;    
        }
        
        public Boolean isSuccess() {
            return this.success;
        }
        
        public InvoicePreview getInvoicePreview() {
            return this.invoicePreview;
        }
        
        public Error getError() {
            return this.error;
        }
        
        public String getErrorMessage() {
            return this.error != null ? this.error.getMessage() : null;
        }
    }
    
    public class SubscriptionResultBuilder {
        private Boolean success = true;
        private String subscriptionId;
        private Error error;
        
        public SubscriptionResultBuilder setSuccess(final Boolean success) {
            this.success = this.success && success;
            return this;
        }
        
        public SubscriptionResultBuilder setSubscriptionId(final String subscriptionId) {
            this.subscriptionId = subscriptionId;
            return this;
        }
        
        public SubscriptionResultBuilder setError(final Error error) {
            if(error != null) {
                this.error = error;
            }
            return this;
        }
        
        public SubscriptionResultBuilder setError(final List<Zuora.zObject> errors) {
            if(errors != null && errors[0] != null) {
                this.error = new Error(errors[0]);
            }
            return this;
        }
        
        public SubscriptionResult build() {
            return new SubscriptionResult(this.success, this.subscriptionId, this.error);
        }
    }
    
    public class SubscriptionResult {
        private final Boolean success;
        private final String subscriptionId;
        private final Error error;
        
        private SubscriptionResult(final Boolean success, final String subscriptionId, final Error error) {
            this.success = success;
            this.subscriptionId = subscriptionId;
            this.error = error;
        }
        
        public Boolean isSuccess() {
            return this.success;
        }
        
        public Error getError() {
            return this.error;
        }
        
        public String getSubscriptionId() {
            return this.subscriptionId;
        }
        
        public String getErrorMessage() {
            return this.error != null ? this.error.getMessage() : null;
        }
    }
    
    public class Error {
        private final String code;
        private final String field;
        private final String message;
        
        public Error(final String message) {
            this.message = message;
        }

        public Error(final String code, final String field, final String message) {
            this.code = code;
            this.field = field;
            this.message = message;
        }
        
        private Error(final Zuora.zObject error) {
            this.code = (String)error.getValue('Code');
            this.field = (String)error.getValue('Field');
            this.message = (String)error.getValue('Message');
        }
        
        public String getCode() {
            return this.code;
        }
        
        public String getField() {
            return this.field;
        }
        
        public String getMessage() {
            return this.message;
        }
    }
}
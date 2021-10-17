public class ZuoraQuoteSubscriptionService {
    private final QuoteService quoteSrv = QuoteService.getInstance();
    private final OpportunityDataService opportunityDataSrv = OpportunityDataService.getInstance();
    private final ZuoraRestApi zApi = ZuoraRestApi.getInstance();
    private final ZuoraService zuoraSrv = ZuoraService.getInstance();
    private final ZuoraRestUpdateService zuoraRestUpdateSrv = ZuoraRestUpdateService.getInstance();
    private static final Logger log = Logger.create(ZuoraQuoteSubscriptionService.class);

    public static ZuoraQuoteSubscriptionService getInstance() {
        return (ZuoraQuoteSubscriptionService)ServiceLocator.getInstance(ZuoraQuoteSubscriptionService.class);
    }

    public WrikeQuoteZuoraService.SubscriptionPreview createSubscriptionPreview(final QuoteService.StatusLock statusLock) {
        final WrikeQuote quote = quoteSrv.findWithItemsById(statusLock.getQuoteId());
        final ZuoraQuoteRequest request = new ZuoraQuoteRequest(quote, null, true);
        final QuoteZuoraPreviewBuilder previewBuilder = new QuoteZuoraPreviewBuilder(quote);
        if(request.getAmendmentRequest() != null) {
            final List<AmendmentResponse> amendResponse = (List<AmendmentResponse>)
                    zApi.createPostRequest('/v1/action/amend')
                            .setRequestBody(request.getAmendmentRequest().getRequestJson())
                            .setResponseParser(JsonApi.parseField('results', List<AmendmentResponse>.class)
                            .required()
                            .parser())
                            .execute();
            previewBuilder.addPreviewResponse(amendResponse[0]);
        }
        if(request.getSubscribeRequest() != null) {
            final List<SubscribeResponse> subscribeResponse = (List<SubscribeResponse>)
                    zApi.createPostRequest('/v1/action/subscribe')
                            .setRequestBody(request.getSubscribeRequest().getRequestJson())
                            .setResponseParser(JsonApi.typeParser(List<SubscribeResponse>.class))
                            .execute();
            previewBuilder.addPreviewResponse(subscribeResponse[0]);
        }
        return previewBuilder.build();
    }

    public WrikeQuoteZuoraService.SubscriptionResult sendQuote(final SendQuoteRequest request) {
        final QuoteService.StatusLock statusLock = quoteSrv.getStatusLock(request.getQuoteId());
        System.assertEquals(WrikeQuote.Status.PROPOSAL.name(), statusLock.getStatus());
        final WrikeQuote quote = quoteSrv.findWithItemsById(statusLock.getQuoteId());
        log.infoToLog('sendQuote... quote: ' + quote.quoteNumber, JSON.serialize(quote));
        log.infoToLog('sendQuote... request: ' + quote.quoteNumber, JSON.serialize(request));
        final WrikeQuoteZuoraService.SubscriptionResultBuilder resultBuilder = new WrikeQuoteZuoraService.SubscriptionResultBuilder();
        final WrikeQuoteZuoraService.SubscriptionPreview preview = createSubscriptionPreview(statusLock);
        if(!preview.isSuccess()) {
            resultBuilder.setSuccess(false).setError(preview.getError());
        } else {
            if(quote.total != preview.getInvoicePreview().totalChargeAmount ||
                            quote.deltaMrr != preview.getInvoicePreview().deltaMrr ||
                            quote.targetInvoiceDate != preview.getInvoicePreview().getTargetInvoiceDate()) {
                resultBuilder.setSuccess(false).setError(new WrikeQuoteZuoraService.Error('Saved invoice preview does not match the current quote.'));
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
        final WrikeQuoteZuoraService.SubscriptionResult result = resultBuilder.build();
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
                           final WrikeQuoteZuoraService.SubscriptionResultBuilder resultBuilder) {
        final ZuoraQuoteRequest quoteRequest = new ZuoraQuoteRequest(quote, request, false);
        if(quoteRequest.getSubscribeRequest() == null && quoteRequest.getAmendmentRequest() == null) {
            resultBuilder.setSuccess(false).setError(new WrikeQuoteZuoraService.Error('No subscription or amendment request to send to Zuora.'));
        }
        if(quoteRequest.getAmendmentRequest() != null) {
            final List<AmendmentResponse> amendResponse = (List<AmendmentResponse>)
                    zApi.createPostRequest('/v1/action/amend')
                            .setRequestBody(quoteRequest.getAmendmentRequest().getRequestJson())
                            .setResponseParser(JsonApi.parseField('results', List<AmendmentResponse>.class)
                            .required()
                            .parser())
                            .execute();
            final String errorMessage = amendResponse[0].getError()?.getMessage();
            resultBuilder.setSuccess(amendResponse[0].Success)
                         .setError(errorMessage != null ? new WrikeQuoteZuoraService.Error(errorMessage) : null);
            if(quoteRequest.getSubscribeRequest() == null) {
                resultBuilder.setSubscriptionId(amendResponse[0].SubscriptionId);
            }
        }
        if(quoteRequest.getSubscribeRequest() != null) {
            final List<SubscribeResponse> subscribeResponse = (List<SubscribeResponse>)
                    zApi.createPostRequest('/v1/action/subscribe')
                            .setRequestBody(quoteRequest.getSubscribeRequest().getRequestJson())
                            .setResponseParser(JsonApi.typeParser(List<SubscribeResponse>.class))
                            .execute();
            final String errorMessage = subscribeResponse[0].getError()?.getMessage();
            resultBuilder.setSuccess(subscribeResponse[0].Success)
                    .setError(errorMessage != null ? new WrikeQuoteZuoraService.Error(errorMessage) : null)
                    .setSubscriptionId(subscribeResponse[0].SubscriptionId);
        }
    }

    public class ZuoraQuoteRequest {
        private final ZuoraQuoteAmendmentRequest amendmentRequest;
        private final ZuoraQuoteSubscribeRequest subscribeRequest;

        public ZuoraQuoteRequest(final WrikeQuote quote,
                                 final SendQuoteRequest sendQuoteRequest,
                                 final Boolean preview) {
            System.assert(quote != null, 'Quote object is required.');
            System.assert(quote.newTerm != null, 'New term is required.');
            if(quote.getIsAmendment() || quote.getIsRenewal()) {
                this.amendmentRequest = new ZuoraQuoteAmendmentRequest.Builder(quote)
                        .setPreview(preview)
                        .build();
            }
            if(quote.getIsSubscription() || quote.isNewBillingCycle()) {
                this.subscribeRequest = new ZuoraQuoteSubscribeRequest.Builder(quote)
                        .setPreview(preview)
                        .setPurchaseOrderNumber(sendQuoteRequest != null ? sendQuoteRequest.getPurchaseOrderNumber() : null)
                        .build();
            }
        }

        public ZuoraQuoteAmendmentRequest getAmendmentRequest() {
            return amendmentRequest;
        }

        public ZuoraQuoteSubscribeRequest getSubscribeRequest() {
            return subscribeRequest;
        }
    }

    private class QuoteZuoraPreviewBuilder {
        private final WrikeQuote quote;
        private Boolean success = true;
        private Decimal deltaMrr = 0;
        private List<InvoiceItemPreview> previewInvoiceItems = new List<InvoiceItemPreview>();
        private List<Error> errors = new List<Error>();

        public QuoteZuoraPreviewBuilder(final WrikeQuote quote) {
            this.quote = quote;
        }

        public QuoteZuoraPreviewBuilder addPreviewResponse(final AmendmentResponse previewResponse) {
            addPreviewResponse(previewResponse.Success,
                    previewResponse.TotalDeltaMrr,
                    previewResponse.InvoiceDatas,
                    previewResponse.Errors);
            return this;
        }

        public QuoteZuoraPreviewBuilder addPreviewResponse(final SubscribeResponse previewResponse) {
            addPreviewResponse(previewResponse.Success,
                    previewResponse.TotalMrr,
                    previewResponse.InvoiceData,
                    previewResponse.Errors);
            return this;
        }

        private QuoteZuoraPreviewBuilder addPreviewResponse(final Boolean success,
                                                            final Decimal deltaMrr,
                                                            final List<InvoiceData> invoiceDataList,
                                                            final List<Error> errors) {
            this.success = this.success && (success == true);
            if(invoiceDataList != null) {
                for(InvoiceData invoiceData : invoiceDataList) {
                    if(invoiceData.InvoiceItem != null) {
                        previewInvoiceItems.addAll(invoiceData.InvoiceItem);
                    }
                }
            }
            if(deltaMrr != null) {
                this.deltaMrr = this.deltaMrr + deltaMrr;
            }
            if(errors != null) {
                this.errors.addAll(errors);
            }
            return this;
        }

        public WrikeQuoteZuoraService.SubscriptionPreview build() {
            if(!this.success) {
                final WrikeQuoteZuoraService.Error error = errors.isEmpty()
                        ? null
                        : new WrikeQuoteZuoraService.Error(errors[0].getCode(), errors[0].getField(), errors[0].getMessage());
                return new WrikeQuoteZuoraService.SubscriptionPreview(false, null, error);
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
            return new WrikeQuoteZuoraService.SubscriptionPreview(true, invoicePreview, null);
        }

        private WrikeQuoteItem findProductItem(final InvoiceItemPreview itemPreview) {
            final String chargeNumber = itemPreview.ChargeNumber;
            final String chargeDescription = itemPreview.ChargeDescription;
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
            for(InvoiceItemPreview itemPreview : previewInvoiceItems) {
                if(itemPreview.ServiceStartDate >= quote.effectiveDate) {
                    final WrikeQuoteItem productItem = findProductItem(itemPreview);
                    System.assert(productItem != null, 'Quote product data not found:' + itemPreview.ProductId);
                    if(!productItem.getIsExisting() || itemPreview.ServiceStartDate >= quote.subscriptionEndDate) {
                        final InvoiceItem invoiceItem = new InvoiceItem(
                                productItem,
                                itemPreview.Quantity,
                                itemPreview.ServiceStartDate,
                                itemPreview.ServiceEndDate,
                                itemPreview.ChargeAmount,
                                quote
                        );
                        invoiceItems.add(invoiceItem);
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

    public class AmendmentResponse {
        public List<InvoiceData> InvoiceDatas {get; set;}
        public Decimal TotalDeltaMrr {get; set;}
        public Boolean Success {get; set;}
        public List<Error> Errors {get; set;}
        public String SubscriptionId {get; set;}

        public Error getError() {
            return this.Errors != null && !this.Errors.isEmpty() ? this.Errors[0] : null;
        }
    }

    public class SubscribeResponse {
        public List<InvoiceData> InvoiceData {get; set;}
        public Decimal TotalMrr {get; set;}
        public Boolean Success {get; set;}
        private List<Error> Errors {get; set;}
        public String SubscriptionId {get; set;}

        public Error getError() {
            return this.Errors != null && !this.Errors.isEmpty() ? this.Errors[0] : null;
        }
    }

    public class InvoiceData {
        public List<InvoiceItemPreview> InvoiceItem {get; set;}
    }

    public class InvoiceItemPreview {
        public String ProductId {get; set;}
        public Decimal ChargeAmount {get; set;}
        public String ChargeNumber {get; set;}
        public String ChargeDescription {get; set;}
        public Decimal Quantity {get; set;}
        public Date ServiceStartDate {get; set;}
        public Date ServiceEndDate {get; set;}
    }

    public class Error {
        private final String code;
        private final String field;
        private final String message;

        private Error(final String message) {
            this.message = message;
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
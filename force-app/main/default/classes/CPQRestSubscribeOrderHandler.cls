public class CPQRestSubscribeOrderHandler implements RestHandlerService.RestHandler {

    public Type getRequestType() {
        return CPQRestSubscribeAddProductsRequest.class;
    }

    public RestHandlerService.RestResponseData processRequest(final Object requestData) {
        final CPQRestSubscribeAddProductsRequest request = (CPQRestSubscribeAddProductsRequest)requestData;
        if (String.isBlank(request.quoteId)) {
            return RestHandlerService.failed('No quote Id specified.');
        }
        if (String.isBlank(request.plan)) {
            return RestHandlerService.failed('No Product specified.');
        }
        if (!(request.seatsQuantity > 0)) {
            return RestHandlerService.failed('Invalid seats quantity: ' + request.seatsQuantity);
        }
        if (!(request.price > 0)) {
            return RestHandlerService.failed('New price is not valid: ' + request.price);
        }
        final CPQApi cpqApi = CPQApi.getInstance();
        final Map<Id, CPQApi.ProductModel> productMap = cpqApi.queryProductsMap(new Set<String> { request.plan }, 'USD');
        if (productMap.isEmpty()) {
            return RestHandlerService.failed('Specified Product is not found.');
        }
        final CPQApi.ProductModel newProduct = productMap.values()[0];
        final CPQApi.QuoteModel quoteModel = cpqApi.readQuote(request.quoteId);
        if (quoteModel.record.SBQQ__Status__c != 'Draft') {
            return RestHandlerService.failed('Non-draft quote: ' + quoteModel.record.SBQQ__Status__c);
        }
        final Id quoteId = quoteModel.record.Id;
        final CPQApi.QuoteModel updatedQuote = cpqApi.addProducts(
                quoteModel,
                new List<CPQApi.ProductModel> { newProduct },
                2
        );
        for (CPQAPI.QuoteLineModel quoteLine : updatedQuote.lineItems) {
            if (quoteLine.record.SBQQ__Existing__c != true) {
                quoteLine.record.SBQQ__AdditionalDiscountAmount__c =
                        quoteLine.record.SBQQ__ListPrice__c - request.price;
                quoteLine.record.SBQQ__Quantity__c = request.seatsQuantity;
            }
        }
        final CPQApi.QuoteModel calculatedQuote = cpqApi.calculate(updatedQuote);
        cpqApi.save(calculatedQuote);
        if(request.expectedSumWithoutTax != null && request.expectedSumWithoutTax != calculatedQuote.netTotal) {
            return RestHandlerService.failed('Total value mismatch! Expected: ' + request.expectedSumWithoutTax + ',  Actual: ' + calculatedQuote.netTotal);
        }
        final CPQQuoteService quoteService = CPQQuoteService.getInstance();
        quoteService.calculateBillingScheduleAndUpdateQuote(quoteId);
        quoteService.createOrder(request.quoteId);
        final Order order = CPQOrderQueryService.getInstance().findOrderByQuoteId(request.quoteId);
        final CPQOrderService orderService = CPQOrderService.getInstance();
        orderService.calculateBillingSchedule(order);
        orderService.createContract(order.Id);
        return RestHandlerService.success(new Map<String, String> {
            'orderId' => order.Id,
            'total' => String.valueOf(calculatedQuote.netTotal)
        });
    }

    private class CPQRestSubscribeAddProductsRequest {
        public Id quoteId {get; set;}
        public String plan {get; set;}
        public Integer seatsQuantity {get; set;}
        public Decimal price {get; set;}
        public Decimal expectedSumWithoutTax {get; set;}
    }
}
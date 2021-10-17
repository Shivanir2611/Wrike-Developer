public class CPQRestRenewalService extends RestHandlerService {

    @TestVisible
    protected override Map<String, RestHandlerService.RestHandler> getHandlerMap() {
        return new Map<String, RestHandlerService.RestHandler> {
            'quote' => new RenewalQuoteHandler(),
            'update' => new UpdateRenewalQuoteHandler(),
            'order' => new OrderRenewalQuoteHandler()
        };
    }

    public class RenewalQuoteHandler implements RestHandlerService.RestHandler {

        public Type getRequestType() {
            return RenewQuoteRequest.class;
        }

        public RestHandlerService.RestResponseData processRequest(final Object requestData) {
            final RenewQuoteRequest request = (RenewQuoteRequest)requestData;
            final Decimal wrikeAccountId = request.wrikeAccountId;
            if (!(wrikeAccountId > 0)) {
                return failed('Invalid Wrike Account Id.');
            }
            final List<Contract> contracts = listActiveContracts(wrikeAccountId);
            if(contracts.isEmpty()) {
                return failed('No active Contracts found.');
            }
            if(contracts.size() > 1) {
                return failed('Several active Contracts found: ' + contracts.size());
            }
            if(contracts[0].ResellerAccount__c != null) {
                return failed('Partner contract.');
            }
            final CPQQuoteCreationService quoteCreationService = CPQQuoteCreationService.getInstance();
            final CPQQuoteService quoteService = CPQQuoteService.getInstance();
            final Id quoteId = quoteCreationService.createSelfRenewalQuote(
                    contracts[0].Id,
                    request.userName,
                    request.userEmail
            );
            final CPQQuote quote = quoteService.findQuoteById(quoteId);
            deleteExistingQuoteLines(quoteId);
            if(!quote.primary) {
                quoteService.makePrimary(quote);
            }
            update new Opportunity(
                    Id = contracts[0].SBQQ__RenewalOpportunity__c,
                    SBQQ__PrimaryQuote__c = quoteId
            );
            return success(new Map<String, String> {
                'quoteId' => quoteId
            });
        }

        private void deleteExistingQuoteLines(final Id quoteId) {
            delete [
                    SELECT Id
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :quoteId
                      AND CreatedById = :UserInfo.getUserId()
                      AND SBQQ__Quote__r.SBQQ__Status__c = 'Draft'
            ];
        }

        private List<Contract> listActiveContracts(final Decimal wrikeAccountId) {
            return [
                    SELECT Id, SBQQ__RenewalOpportunity__c, ResellerAccount__c
                    FROM Contract
                    WHERE Status = 'Activated'
                    AND Wrike_Account_ID__c = :wrikeAccountId
            ];
        }
    }

    public class UpdateRenewalQuoteHandler implements RestHandlerService.RestHandler {

        public Type getRequestType() {
            return UpdateRenewalQuoteRequest.class;
        }

        public RestHandlerService.RestResponseData processRequest(final Object requestData) {
            final UpdateRenewalQuoteRequest request = (UpdateRenewalQuoteRequest)requestData;
            if (String.isBlank(request.quoteId)) {
                return failed('No quote Id specified.');
            }
            if (String.isBlank(request.newPlan)) {
                return failed('No Product specified.');
            }
            if (!(request.newSeatsQuantity > 0)) {
                return failed('Invalid seats quantity.');
            }
            final SBQQ__Quote__c quote = findAndLockQuote(request.quoteId);
            if (quote.SBQQ__Status__c != 'Draft') {
                return failed('Non-draft quote: ' + quote.SBQQ__Status__c);
            }
            final CPQApi cpqApi = CPQApi.getInstance();
            final Map<Id, CPQApi.ProductModel> productMap = cpqApi.queryProductsMap(new Set<String> { request.newPlan }, 'USD');
            if(productMap.isEmpty()) {
                return failed('Specified Product is not found.');
            }
            final CPQApi.QuoteModel quoteModel = cpqApi.readQuote(request.quoteId);
            final CPQApi.ProductModel newProduct = productMap.values()[0];
            final CPQApi.QuoteModel updatedQuote = cpqApi.addProducts(
                    quoteModel,
                    new List<CPQApi.ProductModel> { newProduct },
                    quoteModel.lineItemGroups[0].key
            );
            updatedQuote.lineItemGroups[0].record.SBQQ__StartDate__c = quote.SBQQ__StartDate__c;
            updatedQuote.lineItemGroups[0].record.SBQQ__EndDate__c = quote.SBQQ__EndDate__c;
            final SBQQ__QuoteLine__c quoteLine = updatedQuote.lineItems[0].record;
            quoteLine.SBQQ__Quantity__c = request.newSeatsQuantity;
            quoteLine.SBQQ__AdditionalDiscountAmount__c = quoteLine.SBQQ__ListPrice__c - request.newPrice;
            final CPQApi.QuoteModel calculatedQuote = cpqApi.calculate(updatedQuote);
            cpqApi.save(calculatedQuote);
            if(request.expectedSumWithoutTax != null && request.expectedSumWithoutTax != calculatedQuote.netTotal) {
                return failed('Total value mismatch! Expected: ' + request.expectedSumWithoutTax + ',  Actual: ' + calculatedQuote.netTotal);
            }
            return success(new Map<String, String> {
                'quoteId' => request.quoteId,
                'total' => String.valueOf(calculatedQuote.netTotal)
            });
        }

        private SBQQ__Quote__c findAndLockQuote(final Id quoteId) { //locking prevents conflict with calculator jobs
            return [
                    SELECT Id, SBQQ__Status__c, SBQQ__StartDate__c, SBQQ__EndDate__c
                    FROM SBQQ__Quote__c
                    WHERE Id = :quoteId
                    FOR UPDATE
            ];
        }
    }

    public class OrderRenewalQuoteHandler implements RestHandlerService.RestHandler {

        public Type getRequestType() {
            return OrderRenewalQuoteRequest.class;
        }

        public RestHandlerService.RestResponseData processRequest(final Object requestData) {
            final OrderRenewalQuoteRequest request = (OrderRenewalQuoteRequest)requestData;
            final CPQQuoteService quoteService = CPQQuoteService.getInstance();
            quoteService.calculateBillingScheduleAndUpdateQuote(request.quoteId);
            quoteService.createOrder(request.quoteId);
            final Order order = CPQOrderQueryService.getInstance().findOrderByQuoteId(request.quoteId);
            final CPQOrderService orderService = CPQOrderService.getInstance();
            orderService.calculateBillingSchedule(order);
            orderService.createContract(order.Id);
            return success(new Map<String, String> {
                'orderId' => order.Id
            });
        }
    }


    public class RenewQuoteRequest {
        public Decimal wrikeAccountId {get; set;}
        public String userName {get; set;}
        public String userEmail {get; set;}
    }

    public class UpdateRenewalQuoteRequest {
        public Id quoteId {get; set;}
        public String newPlan {get; set;}
        public Integer newSeatsQuantity {get; set;}
        public Decimal newPrice {get; set;}
        public Decimal expectedSumWithoutTax {get; set;}
    }

    public class OrderRenewalQuoteRequest {
        public Id quoteId {get; set;}
    }
}
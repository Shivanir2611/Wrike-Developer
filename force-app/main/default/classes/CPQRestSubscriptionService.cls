public with sharing class CPQRestSubscriptionService extends RestHandlerService {

    protected override Map<String, RestHandlerService.RestHandler> getHandlerMap() {
        return new Map<String, RestHandlerService.RestHandler> {
            'quote' => new CPQRestSubscribeHandler(),
            'order' => new CPQRestSubscribeOrderHandler(),
            'amend' => new AmendSubscriptionHandler(),
            'update' => new UpdateSubscriptionHandler()
        };
    }

    private class AmendSubscriptionHandler implements RestHandlerService.RestHandler {

        public Type getRequestType() {
            return AmendSubscriptionRequest.class;
        }

        public RestHandlerService.RestResponseData processRequest(Object requestData) {
            final AmendSubscriptionRequest request = (AmendSubscriptionRequest)requestData;
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
            final List<SBQQ__Subscription__c> subscriptions = contracts.get(0).SBQQ__Subscriptions__r;
            if(subscriptions == null || subscriptions.isEmpty()) {
                return failed('No Active subscriptions.');
            }
            final String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contracts[0].Id, null);
            final CPQApi.QuoteModel quoteModel = (CPQApi.QuoteModel) JSON.deserialize(quoteJSON, CPQApi.QuoteModel.class);
            CPQQuoteGroupService.getInstance().restoreQuoteGroups(
                    quoteModel.record,
                    DateUtils.getPacificLocalDate(),
                    false
            );
            update new SBQQ__Quote__c(
                    Id = quoteModel.record.Id,
                    SBQQ__LineItemsGrouped__c = true,
                    eCommerce__c = true
            );
            return success(new Map<String, String> {
                'quoteId' => quoteModel.record.Id
            });
        }

        private List<Contract> listActiveContracts(final Decimal wrikeAccountId) {
            return [
                SELECT Id,
                        (
                            SELECT Id, SBQQ__Product__c
                            FROM SBQQ__Subscriptions__r
                            WHERE SBQQ__ListPrice__c > 0
                        )
                FROM Contract
                WHERE Status = 'Activated'
                AND Wrike_Account_ID__c = :wrikeAccountId
            ];
        }
    }

    private class UpdateSubscriptionHandler implements RestHandlerService.RestHandler {

        public Type getRequestType() {
            return UpdateSubscriptionRequest.class;
        }

        public RestHandlerService.RestResponseData processRequest(Object requestData) {
            final UpdateSubscriptionRequest request = (UpdateSubscriptionRequest)requestData;
            if (String.isBlank(request.quoteId)) {
                return failed('No quote Id specified.');
            }
            if (String.isBlank(request.newPlan)) {
                return failed('No Product specified.');
            }
            if (!(request.newSeatsQuantity > 0)) {
                return failed('Invalid seats quantity.');
            }
            final List<AggregateResult> subscriptionData = [
                    SELECT max(SBQQ__Product__r.ZuoraServiceType__c) serviceType,
                           min(UnitPrice__c) minUnitPrice,
                           max(UnitPrice__c) maxUnitPrice
                    FROM SBQQ__Subscription__c
                    WHERE SBQQ__Contract__c IN (
                            SELECT SBQQ__MasterContract__c
                            FROM SBQQ__Quote__c
                            WHERE Id = :request.quoteId
                        )
                    AND SBQQ__ListPrice__c > 0
                    AND SBQQ__Quantity__c > 0
                    GROUP BY SBQQ__Product__c
            ];
            if(subscriptionData.isEmpty()) {
                return failed('No active Subscription found.');
            }
            if(subscriptionData.size() > 1) {
                return failed('Multiple Subscription products found: ' + subscriptionData.size());
            }
            final Decimal minUnitPrice = (Decimal)subscriptionData.get(0).get('minUnitPrice');
            final Decimal maxUnitPrice = (Decimal)subscriptionData.get(0).get('maxUnitPrice');
            final String serviceType = (String)subscriptionData.get(0).get('serviceType');
            if(maxUnitPrice != minUnitPrice) {
                return failed('Existing Subscriptions have different unit prices.');
            }
            if(serviceType == request.newPlan && maxUnitPrice != request.newPrice) {
                return failed('New price differs from existing unit price: ' + maxUnitPrice);
            } else if(!(request.newPrice > 0)) {
                return failed('New price is not valid.');
            }
            final CPQApi cpqApi = CPQApi.getInstance();
            final Map<Id, CPQApi.ProductModel> productMap = cpqApi.queryProductsMap(new Set<String> { request.newPlan }, 'USD');
            if(productMap.isEmpty()) {
                return failed('Specified Product is not found.');
            }
            final CPQApi.ProductModel newProduct = productMap.values()[0];
            final CPQApi.QuoteModel quoteModel = cpqApi.readQuote(request.quoteId);
            final Id quoteId = quoteModel.record.Id;
            final CPQApi.QuoteLineModel existingSeatsProductLine = findExistingProduct(newProduct.record.Id, quoteModel.lineItems);
            final CPQApi.QuoteModel updatedQuote = existingSeatsProductLine != null
                    ? quoteModel
                    : cpqApi.addProducts(
                            quoteModel,
                            new List<CPQApi.ProductModel> { newProduct },
                            quoteModel.lineItems[0].parentGroupKey
                    );
            for(CPQApi.QuoteLineModel quoteLine : updatedQuote.lineItems) {
                if(quoteLine.record.Id == null || quoteLine.record.Id == existingSeatsProductLine?.record?.Id) {
                    if(quoteLine.record.Id == null) {
                        quoteLine.record.SBQQ__AdditionalDiscountAmount__c = quoteLine.record.SBQQ__ListPrice__c - request.newPrice;
                    }
                    updateLineQuantity(quoteLine, request.newSeatsQuantity, updatedQuote.lineItems);
                } else {
                    updateLineQuantity(quoteLine, 0, updatedQuote.lineItems);
                }
            }
            final CPQApi.QuoteModel calculatedQuote = cpqApi.calculate(updatedQuote);
            cpqApi.save(calculatedQuote);
            if(request.expectedSumWithoutTax != null && request.expectedSumWithoutTax != calculatedQuote.netTotal) {
                return failed('Total value mismatch! Expected: ' + request.expectedSumWithoutTax + ',  Actual: ' + calculatedQuote.netTotal);
            }
            final CPQQuoteService quoteService = CPQQuoteService.getInstance();
            quoteService.calculateBillingScheduleAndUpdateQuote(quoteId);
            quoteService.createOrder(request.quoteId);
            final Order order = CPQOrderQueryService.getInstance().findOrderByQuoteId(request.quoteId);
            final CPQOrderService orderService = CPQOrderService.getInstance();
            orderService.calculateBillingSchedule(order);
            orderService.createContract(order.Id);
            return success(new Map<String, String> {
                'orderId' => order.Id,
                'total' => String.valueOf(calculatedQuote.netTotal)
            });
        }

        private void updateLineQuantity(final CPQApi.QuoteLineModel productLine,
                                        final Integer quantity,
                                        final List<CPQApi.QuoteLineModel> quoteLines) {
            final Id packageLineId = productLine.record.SBQQ__RequiredBy__c;
            if(packageLineId == null) {
                productLine.record.SBQQ__Quantity__c = quantity;
            } else {
                for(CPQApi.QuoteLineModel quoteLine : quoteLines) {
                    if(quoteLine.record.Id == packageLineId) {
                        quoteLine.record.SBQQ__Quantity__c = quantity;
                    }
                }
            }
        }

        private CPQApi.QuoteLineModel findExistingProduct(final Id newProductId,
                                                          final List<CPQApi.QuoteLineModel> quoteLines) {
            for(CPQApi.QuoteLineModel quoteLine : quoteLines) {
                if(quoteLine.record.SBQQ__Product__c == newProductId) {
                    return quoteLine;
                }
            }
            return null;
        }
    }

    private class AmendSubscriptionRequest {
        public Decimal wrikeAccountId {get; set;}
    }

    private class UpdateSubscriptionRequest {
        public Id quoteId {get; set;}
        public String newPlan {get; set;}
        public Integer newSeatsQuantity {get; set;}
        public Decimal newPrice {get; set;}
        public Decimal expectedSumWithoutTax {get; set;}
    }
}
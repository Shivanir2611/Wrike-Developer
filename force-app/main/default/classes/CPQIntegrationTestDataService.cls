@RestResource(urlMapping='/cpqtest/*')
global with sharing class CPQIntegrationTestDataService {

    private static final Logger log = Logger.create(CPQIntegrationTestDataService.class);

    private static final List<CPQTestHandler> handlers = new List<CPQTestHandler> {
        new CPQNewQuoteHandler(),
        new CPQAddProductsHandler(),
        new CPQCreateOrderRequestHandler(),
        new CPQUpdateContractRequestHandler(),
        new CPQFindContractRequestHandler()
    };

    @HttpPost
    global static CPQTestResponse processRequest() {
        try {
            System.assert(Test.isRunningTest() || OrganizationService.getInstance().isSandbox(),
                    'Must be used on Sandboxes only!');
            final RestRequest request = RestContext.request;
            if (request.requestBody == null || String.isBlank(request.requestBody.toString())) {
                return failed('Empty request');
            }
            final String action = request.requestURI.substringAfter('/cpqtest/');
            for (CPQTestHandler handler : handlers) {
                if (handler.getAction() == action) {
                    final Object requestData = JSON.deserialize(
                            request.requestBody.toString(),
                            handler.getRequestType()
                    );
                    return handler.processRequest(requestData);
                }
            }
            return failed('Unknown action: ' + action);
        } catch (JSONException e) {
            return failed('Failed to parse request data: ' + e.getMessage());
        } catch (Exception e) {
            log.error(e.getMessage(), e.getStackTraceString());
            return failed(e.getTypeName() + ': ' + e.getMessage());
        }
    }

    private static String getRandomToken() {
        return Datetime.now().format() + ' ' + StringUtils.generateRandomString(3);
    }

    private interface CPQTestHandler {

        String getAction();

        Type getRequestType();

        CPQTestResponse processRequest(final Object requestData);
    }


    private class CPQNewQuoteHandler implements CPQTestHandler {

        public String getAction() {
            return 'createQuote';
        }

        public Type getRequestType() {
            return CPQNewQuoteRequest.class;
        }

        public CPQTestResponse processRequest(final Object requestData) {
            final CPQNewQuoteRequest request = (CPQNewQuoteRequest)requestData;
            if(!(request.wrikeAccountId > 0)) {
                return failed('Invalid Wrike Account Id');
            }
            final String currencyCode = StringUtils.defaultIfBlank(request.currencyCode, 'USD');
            if(!new Set<String> { 'USD', 'EUR', 'JPY'}.contains(currencyCode)) {
                return failed('Invalid currency.');
            }
            final CPQRestQuoteService restQuoteService = CPQRestQuoteService.getInstance();
            if(!isValidGoverningTerms(request.governingTerms)) {
                return failed('Invalid governing terms.');
            }
            final Id accountId = restQuoteService.findOrCreateAccountByWrikeAccountId(
                    request.wrikeAccountId,
                            'eComm Test ' + getRandomToken()
            );
            final Opportunity opp = new Opportunity(
                Name = 'eComm Test ' + getRandomToken(),
                StageName = '0-MQL',
                AccountId = accountId,
                CloseDate = Date.today().addDays(1),
                Wrike_Account_Id__c = request.wrikeAccountId,
                CurrencyIsoCode = currencyCode
            );
            insert opp;
            final SBQQ__Quote__c quote = initNewQuote(accountId, opp, request.wrikeAccountId, request);
            insert quote;
            insert new SBQQ__QuoteLineGroup__c(
                Name = 'Group 1',
                SBQQ__Number__c = 1,
                SBQQ__Quote__c = quote.Id,
                SBQQ__StartDate__c = request.quoteStartDate,
                SBQQ__EndDate__c = request.quoteEndDate
            );
            return success(new Map<String, String> {
                'accountId' => accountId,
                'opportunityId' => opp.Id,
                'quoteId' => quote.Id
            });
        }

        private Boolean isValidGoverningTerms(final String governingTerms) {
            if (String.isBlank(governingTerms)) {
                return true;
            }
            for (PicklistEntry entry : Contract.GoverningTerms__c.getDescribe().getPicklistValues()) {
                if (governingTerms == entry.getValue()) {
                    return true;
                }
            }
            return false;
        }

        private SBQQ__Quote__c initNewQuote(final Id accountId,
                                            final Opportunity opportunity,
                                            final Decimal wrikeAccountId,
                                            final CPQNewQuoteRequest request) {
            final CPQRestQuoteService restQuoteService = CPQRestQuoteService.getInstance();
            final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = accountId,
                SBQQ__Opportunity2__c = opportunity.Id,
                CurrencyIsoCode = opportunity.CurrencyIsoCode,
                WrikeAccountId__c = wrikeAccountId,
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft',
                SBQQ__LineItemsGrouped__c = true
            );
            if(String.isNotBlank(request.governingTerms)) {
                quote.Governing_Terms__c = request.governingTerms;
            }
            if(request.billTo != null) {
                quote.QS_Bill_To__c = createBillToShipTo(request.billTo, accountId, wrikeAccountId, true);
            }
            if(request.shipTo != null) {
                quote.QS_Ship_To__c = createBillToShipTo(request.shipTo, accountId, wrikeAccountId, false);
            }
            final List<QS_Bill_To_Ship_To__c> contacts = [
                    SELECT Id, QS_Bill_To__c, QS_Ship_To__c
                    FROM QS_Bill_To_Ship_To__c
                    WHERE QS_Account__c = :quote.SBQQ__Account__c
                    AND Wrike_Account_ID__c = :quote.WrikeAccountId__c
                    ORDER BY CreatedDate
            ];
            for(QS_Bill_To_Ship_To__c contact : contacts) {
                if(contact.QS_Bill_To__c) {
                    quote.QS_Bill_To__c = contact.Id;
                } else if(contact.QS_Ship_To__c) {
                    quote.QS_Ship_To__c = contact.Id;
                }
            }
            if(quote.QS_Bill_To__c == null) {
                quote.QS_Bill_To__c = createBillToShipTo(defaultBillToShipTo(), accountId, wrikeAccountId, true);
            }
            if(quote.QS_Ship_To__c == null) {
                quote.QS_Ship_To__c = createBillToShipTo(defaultBillToShipTo(), accountId, wrikeAccountId, false);
            }
            return quote;
        }

        private Id createBillToShipTo(final CPQTestBillToShipTo billToShipTo,
                                     final Id accountId,
                                     final Decimal wrikeAccountId,
                                     final Boolean billTo) {
            final QS_Bill_To_Ship_To__c record = new QS_Bill_To_Ship_To__c(
                    QS_Attention_To__c = billToShipTo.userName,
                    QS_Email__c = billToShipTo.email,
                    QS_Account__c = accountId,
                    QS_Country_Code__c = billToShipTo.countryCode,
                    QS_State_Code__c = billToShipTo.stateCode,
                    QS_City__c = billToShipTo.city,
                    QS_Street_1__c = billToShipTo.address1,
                    QS_Street_2__c = billToShipTo.address2,
                    QS_Zip_Postal_Code__c = billToShipTo.postalCode,
                    RegionState__c = billToShipTo.region,
                    Wrike_Account_ID__c = wrikeAccountId
            );
            if(billTo) {
                record.QS_Bill_To__c = true;
            } else {
                record.QS_Ship_To__c = true;
            }
            insert record;
            return record.Id;
        }

        private Id createOpportunity(final Id accountId) {
            final Opportunity opp = new Opportunity(
                Name = 'eComm Test ' + getRandomToken(),
                StageName = '0-MQL',
                AccountId = accountId,
                CloseDate = Date.today().addDays(1)
            );
            insert opp;
            return opp.Id;
        }

        private CPQTestBillToShipTo defaultBillToShipTo() {
            final CPQTestBillToShipTo billToShipTo = new CPQTestBillToShipTo();
            billToShipTo.userName = 'Test User';
            billToShipTo.email = 'test.user@address.com';
            billToShipTo.countryCode = 'US';
            billToShipTo.stateCode = 'CA';
            billToShipTo.city = 'San Jose';
            billToShipTo.address1 = 'N 2nd Street';
            billToShipTo.address2 = '70';
            billToShipTo.postalCode = '95113';
            billToShipTo.region = 'California';
            return billToShipTo;
        }
    }

    private class CPQAddProductsHandler implements CPQTestHandler {

        public String getAction() {
            return 'addProducts';
        }

        public Type getRequestType() {
            return CPQAddProductsRequest.class;
        }

        public CPQIntegrationTestDataService.CPQTestResponse processRequest(final Object requestData) {
            final CPQAddProductsRequest request = (CPQAddProductsRequest)requestData;
            if(request.quoteId == null) {
                return failed('No quote id.');
            }
            final CPQApi cpqApi = CPQApi.getInstance();
            final CPQApi.QuoteModel quoteModel = cpqApi.readQuote(request.quoteId);
            if(quoteModel == null) {
                return failed('No quote found.');
            }
            final Map<String, CPQTestProduct> serviceTypeProductMap = request.getServiceTypeProductMap();
            final String currencyCode = [
                SELECT CurrencyIsoCode
                FROM SBQQ__Quote__c
                WHERE Id = :request.quoteId
            ].CurrencyIsoCode;
            final Map<Id, CPQApi.ProductModel> productModelMap = cpqApi.queryProductsMap(serviceTypeProductMap.keySet(), currencyCode);
            final CPQApi.QuoteModel quoteWithProducts = cpqApi.addProducts(quoteModel, productModelMap.values() , 2); // for some reason CPQ sets the first group key to 2 instead of 1
            for(CPQAPI.QuoteLineModel line: quoteWithProducts.lineItems) {
                if(line.record.SBQQ__Existing__c != true) {
                    final CPQApi.ProductModel productModel = productModelMap.get(line.record.SBQQ__Product__c);
                    if(productModel != null) {
                        final CPQTestProduct productRequest = serviceTypeProductMap.get(productModel.record.ZuoraServiceType__c);
                        if(productRequest != null) {
                            line.record.SBQQ__Quantity__c = productRequest.quantity;
                        }
                    }
                }
            }
            final CPQApi.QuoteModel calculatedQuote = cpqApi.calculate(quoteWithProducts);
            cpqApi.save(calculatedQuote);
            CPQQuoteService.getInstance().calculateBillingScheduleAndUpdateQuote(request.quoteId);
            return success(new Map<String, String> {
                'quoteId' => request.quoteId,
                'total' => String.valueOf(calculatedQuote.netTotal)
            });
        }
    }

    private class CPQCreateOrderRequestHandler implements CPQTestHandler {

        public String getAction() {
            return 'createOrder';
        }

        public Type getRequestType() {
            return CPQCreateOrderRequest.class;
        }

        public CPQIntegrationTestDataService.CPQTestResponse processRequest(final Object requestData) {
            final CPQCreateOrderRequest request = (CPQCreateOrderRequest)requestData;
            if(request.quoteId == null) {
                return failed('No quote id.');
            }
            CPQQuoteService.getInstance().createOrder(request.quoteId);
            final Order order = CPQOrderQueryService.getInstance().findOrderByQuoteId(request.quoteId);
            final CPQOrderService orderService = CPQOrderService.getInstance();
            orderService.calculateBillingSchedule(order);
            orderService.createContract(order.Id);
            return success(new Map<String, String> {
                'orderId' => order.Id
            });
        }
    }

    private class CPQFindContractRequestHandler implements CPQTestHandler {

        public String getAction() {
            return 'findContract';
        }

        public Type getRequestType() {
            return CPQFindContractRequest.class;
        }

        public CPQIntegrationTestDataService.CPQTestResponse processRequest(final Object requestData) {
            final CPQFindContractRequest request = (CPQFindContractRequest)requestData;
            final Id contractId = String.isNotBlank(request.contractId)
                                  ? request.contractId
                                  : findContractByOrderId(request.orderId);
            if(contractId == null) {
                return success(new Map<String, String>());
            }
            final List<Contract> contracts = [
                    SELECT Id, Status
                    FROM Contract
                    WHERE Id = :contractId
            ];
            return success(new Map<String, String> {
                'contractId' => contracts[0].Id,
                'status' => contracts[0].Status
            });
        }

        private Id findContractByOrderId(final Id orderId) {
            if(orderId == null) {
                return null;
            }
            final List<Contract> contracts = [
                    SELECT Id
                    FROM Contract
                    WHERE SBQQ__Order__c = :orderId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            return contracts.isEmpty() ? null : contracts[0].Id;
        }
    }

    private class CPQUpdateContractRequestHandler implements CPQTestHandler {

        public String getAction() {
            return 'updateContract';
        }

        public Type getRequestType() {
            return CPQUpdateContractRequest.class;
        }

        public CPQIntegrationTestDataService.CPQTestResponse processRequest(final Object requestData) {
            final CPQUpdateContractRequest request = (CPQUpdateContractRequest)requestData;
            final Id contractId = String.isNotBlank(request.contractId)
                                  ? request.contractId
                                  : findContractByOrderId(request.orderId);
            if(contractId == null) {
                return success(new Map<String, String>());
            }
            if(request.status != 'Activated' && request.status != 'Expired') {
                return failed('Invalid status.');
            }
            update new Contract(
                Id = contractId,
                Status = request.status,
                Auto_Renew__c = request.autoRenew == true ? 'Yes' : 'No'
            );
            final List<Contract> contracts = [
                SELECT Id, Status
                FROM Contract
                WHERE Id = :contractId
            ];
            return success(new Map<String, String> {
                'contractId' => contracts[0].Id,
                'status' => contracts[0].Status
            });
        }

        private Id findContractByOrderId(final Id orderId) {
            if(orderId == null) {
                return null;
            }
            final List<Contract> contracts = [
                SELECT Id
                FROM Contract
                WHERE SBQQ__Order__c = :orderId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return contracts.isEmpty() ? null : contracts[0].Id;
        }
    }

    private class CPQNewQuoteRequest {
        public Integer wrikeAccountId { get; set; }
        public String currencyCode { get; set; }
        public Date quoteStartDate { get; set; }
        public Date quoteEndDate { get; set; }
        public CPQTestBillToShipTo billTo { get; set; }
        public CPQTestBillToShipTo shipTo { get; set; }
        public String governingTerms { get; set; }
    }

    private class CPQTestBillToShipTo {
        public String userName { get; set; }
        public String email { get; set; }
        public String countryCode { get; set; }
        public String stateCode { get; set; }
        public String region { get; set; }
        public String city { get; set; }
        public String postalCode { get; set; }
        public String address1 { get; set; }
        public String address2 { get; set; }
    }

    private class CPQAddProductsRequest {
        public Id quoteId { get; set; }
        public List<CPQTestProduct> products { get; set; }

        private Map<String, CPQTestProduct> getServiceTypeProductMap() {
            final Map<String, CPQTestProduct> productMap = new Map<String, CPQTestProduct>();
            for(CPQTestProduct product : products) {
                productMap.put(product.serviceType, product);
            }
            return productMap;
        }
    }

    private class CPQTestProduct {
        public String serviceType { get; set; }
        public Decimal quantity { get; set; }
    }

    private class CPQCreateOrderRequest {
        public Id quoteId { get; set; }
    }

    private class CPQFindContractRequest {
        public Id orderId { get; set; }
        public Id contractId { get; set; }
    }

    private class CPQUpdateContractRequest {
        public Id orderId { get; set; }
        public Id contractId { get; set; }
        public String status { get; set; }
        public Boolean autoRenew { get; set; }
    }

    global class CPQTestResponse {
        private final Boolean success;
        private final String error;
        private final Map<String, String> data;

        public CPQTestResponse(final Boolean success, final String error, final Map<String, String> data) {
            this.success = success;
            this.error = error;
            this.data = data;
        }

        public Boolean getSuccess() {
            return success;
        }

        public String getError() {
            return error;
        }

        public Map<String, String> getData() {
            return data;
        }
    }

    private static CPQTestResponse failed(final String message) {
        return new CPQTestResponse(false, message, null);
    }

    private static CPQTestResponse success(final Map<String, String> responseData) {
        return new CPQTestResponse(true, null, responseData);
    }
}
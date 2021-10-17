public with sharing class CPQRestBillToShipToService extends RestHandlerService {

    private static final Logger log = Logger.create(CPQRestBillToShipToService.class);

    private static final CPQRestQuoteService restQuoteService = CPQRestQuoteService.getInstance();
    private static final BillToShipToQueryService billToShipToQuerySrv = BillToShipToQueryService.getInstance();

    protected override Map<String, RestHandlerService.RestHandler> getHandlerMap() {
        return new Map<String, RestHandlerService.RestHandler> {
            'listBillingInfo' => new FindBillToRequestHandler(),
            'updateBillingInfo' => new UpdateBillToRequestHandler()
        };
    }

    private class FindBillToRequestHandler implements RestHandlerService.RestHandler {

        public Type getRequestType() {
            return FindBillingInfoRequest.class;
        }

        public RestHandlerService.RestResponseData processRequest(final Object requestData) {
            final FindBillingInfoRequest request = (FindBillingInfoRequest)requestData;
            final Decimal wrikeAccountId = request.wrikeAccountId;
            if (!(wrikeAccountId > 0)) {
                return failed('Invalid Wrike Account ID.');
            }
            final List<QS_Bill_To_Ship_To__c> billToList =
                    billToShipToQuerySrv.findBillToFromContractsByWrikeAccountId(wrikeAccountId);
            return success(mapRecordsToObjects(billToList));
        }
    }

    private class UpdateBillToRequestHandler implements RestHandlerService.RestHandler {

        public Type getRequestType() {
            return UpdateBillingInfoRequest.class;
        }

        public RestHandlerService.RestResponseData processRequest(final Object requestData) {
            final UpdateBillingInfoRequest request = (UpdateBillingInfoRequest)requestData;
            final Decimal wrikeAccountId = request.wrikeAccountId;
            if (!(wrikeAccountId > 0)) {
                return failed('Invalid Wrike Account ID.');
            }
            if (request.billingInfo == null) {
                return failed('No billing info data.');
            }
            if (!isValidBillingInfo(request.billingInfo)) {
                return failed('Invalid billing info data.');
            }
            final Set<Id> billToShipToIds = billToShipToQuerySrv.listContractBillToShipToIds(wrikeAccountId);
            final List<QS_Bill_To_Ship_To__c> recordsToUpdate = new List<QS_Bill_To_Ship_To__c>();
            for(Id recordId : billToShipToIds) {
                recordsToUpdate.add(restQuoteService.mapToExistingRecord(recordId, request.billingInfo));
            }
            final DatabaseService.Result result = DatabaseService.getInstance().updateAndGetResult(recordsToUpdate, false);
            if (result.isSuccess()) {
                return success(billToShipToIds);
            } else {
                return failed(result.getErrorMessage());
            }
        }

        private Boolean isValidBillingInfo(final CPQRestService.CPQRestBillToShipTo billingInfo) {
            if(StringUtils.getEmptyIfNull(billingInfo.countryCode).length() != 2) {
                return false;
            }
            if(String.isBlank(billingInfo.stateCode)
                    && (billingInfo.countryCode == 'US' || billingInfo.countryCode == 'CA')) {
                return false;
            }
            return String.isNotBlank(billingInfo.userName) && String.isNotBlank(billingInfo.email);
        }
    }

    private class FindBillingInfoRequest {
        public Decimal wrikeAccountId {get; set;}
    }

    private class UpdateBillingInfoRequest {
        public Decimal wrikeAccountId {get; set;}
        public CPQRestService.CPQRestBillToShipTo billingInfo {get; set;}
    }

    private static List<CPQRestService.CPQRestBillToShipTo> mapRecordsToObjects(final List<QS_Bill_To_Ship_To__c> records) {
        final List<CPQRestService.CPQRestBillToShipTo> billToShipToList = new List<CPQRestService.CPQRestBillToShipTo>();
        for (QS_Bill_To_Ship_To__c record : records) {
            final CPQRestService.CPQRestBillToShipTo billToShipTo = new CPQRestService.CPQRestBillToShipTo();
            billToShipTo.userName = record.QS_Attention_To__c;
            billToShipTo.companyName = record.QS_Company_Name__c;
            billToShipTo.email = record.QS_Email__c;
            billToShipTo.phone = record.QS_Phone__c;
            billToShipTo.countryCode = record.QS_Country_Code__c;
            billToShipTo.stateCode = record.QS_State_Code__c;
            billToShipTo.stateName = record.RegionState__c;
            billToShipTo.city = record.QS_City__c;
            billToShipTo.postalCode = record.QS_Zip_Postal_Code__c;
            billToShipTo.address1 = record.QS_Street_1__c;
            billToShipTo.address2 = record.QS_Street_2__c;
            billToShipToList.add(billToShipTo);
        }
        return billToShipToList;
    }
}
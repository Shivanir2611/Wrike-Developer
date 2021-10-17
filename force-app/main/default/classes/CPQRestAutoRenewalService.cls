public class CPQRestAutoRenewalService extends RestHandlerService {

    protected override Map<String, RestHandlerService.RestHandler> getHandlerMap() {
        return new Map<String, RestHandlerService.RestHandler> {
            'quote' => new AutoRenewQuoteCreationHandler()
        };
    }

    private class AutoRenewQuoteCreationHandler implements RestHandlerService.RestHandler {

        public Type getRequestType() {
            return AutoRenewQuoteRequest.class;
        }

        public RestHandlerService.RestResponseData processRequest(final Object requestData) {
            final AutoRenewQuoteRequest request = (AutoRenewQuoteRequest)requestData;
            final CPQRenewalService renewalService = CPQRenewalService.getInstance();
            final CPQRenewalService.CPQRenewalData renewalData = renewalService.findRenewalData(request.contractId);
            final String renewalStatus = renewalData.getRenewalStatus();
            if(renewalStatus == CPQRenewalService.CPQRenewalStatus.Renew.name()) {
                if(renewalData.getContract().AutoRenewalQuote__r != null) {
                    return failed('Auto renewal quote has been created.');
                }
                final Id quoteId = renewalService.createRenewalQuote(request.contractId);
                Logger.create(CPQRestAutoRenewalService.class).logContractAction(
                        request.contractId,
                        'Contract Management Job: Create Renewal Quote',
                        'Auto Renewal Quote created: ' + quoteId,
                        renewalData
                );
                return success(new Map<String, String> {
                    'quoteId' => quoteId
                });
            }
            return failed('No auto renewal quote required.');
        }

        private List<Contract> listActiveContracts(final Decimal wrikeAccountId) {
            return [
                    SELECT Id, SBQQ__RenewalOpportunity__c
                    FROM Contract
                    WHERE Status = 'Activated'
                    AND Wrike_Account_ID__c = :wrikeAccountId
            ];
        }
    }

    private class AutoRenewQuoteRequest {
        public Id contractId {get; set;}
    }
}
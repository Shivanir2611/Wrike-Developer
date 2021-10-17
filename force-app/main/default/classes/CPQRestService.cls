@RestResource(urlMapping='/cpq/*')
global class CPQRestService {

    private static final Logger log = Logger.create(CPQRestService.class);

    private static final Map<String, RestHandlerService> serviceMap = new Map<String, RestHandlerService> {
        'billToShipTo' => new CPQRestBillToShipToService(),
        'subscription' => new CPQRestSubscriptionService(),
        'autorenew' => new CPQRestAutoRenewalService(),
        'renewal' => new CPQRestRenewalService()
    };

    @HttpPost
    global static void processRequest() {
        final RestResponse response = RestContext.response;
        try {
            final RestRequest request = RestContext.request;
            if (request.requestBody == null || String.isBlank(request.requestBody.toString())) {
                response.responseBody = failed('Empty request.');
            } else {
                final String serviceUri = request.requestURI.substringAfter('/cpq/');
                final RestHandlerService handlerService = serviceMap.get(serviceUri.substringBefore('/'));
                if(handlerService != null) {
                    final RestHandlerService.RestResponseData responseData = handlerService.handleRequest(serviceUri.substringAfter('/'), request);
                    response.responseBody = Blob.valueOf(JSON.serialize(responseData));
                } else {
                    response.responseBody = failed('Unknown action: ' + serviceUri);
                }
            }
        } catch (Exception e) {
            log.error(e.getMessage(), e.getStackTraceString());
            response.responseBody = failed(e.getTypeName() + ': ' + e.getMessage());
        }
    }

    private static Blob failed(final String message) {
        return Blob.valueOf(JSON.serialize(new RestHandlerService.RestResponseData(false, message, null)));
    }

    public class CPQRestBillToShipTo {
        public String userName {get; set;}
        public String email {get; set;}
        public String phone {get; set;}
        public String companyName {get; set;}
        public String countryCode {get; set;}
        public String stateCode {get; set;}
        public String stateName {get; set;}
        public String city {get; set;}
        public String postalCode {get; set;}
        public String address1 {get; set;}
        public String address2 {get; set;}
    }
}
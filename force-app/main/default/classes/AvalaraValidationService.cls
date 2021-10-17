public class AvalaraValidationService {
    
    public static Result validate(final BillingInfo billingInfo) {
        return validate(billingInfo.country, billingInfo.state, billingInfo.zip);
    }

    public static Result validate(final String countryCode, final String stateCode, final String zip) {
        final String customerCode = Settings__c.getInstance().Avalara_Customer_Code__c;
        if (countryCode == 'US' && String.isNotBlank(customerCode)) {
            final HttpRequest req = new HttpRequest();
            req.setEndpoint(Settings__c.getInstance().Avalara_Url__c);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(Settings__c.getInstance().Avalara_Credentials__c)));
            req.setBody(JSON.serialize(new Map<String, Object> {
                'CustomerCode' => customerCode,
                'Addresses' => new List<Map<String, String>> {
                    new Map<String, String> {
                        'AddressCode' => '01',
                        'Country' => countryCode,
                        'Region' => stateCode,
                        'PostalCode' => zip
                }},
                'Lines' => new List<Map<String, String>> {
                    new Map<String, String> {
                        'LineNo' => '1',
                        'DestinationCode' => '01'
                }}}));
            final HttpResponse res = new Http().send(req);
            if(res.getStatusCode() != 200) {
                final AvalaraResponse response = (AvalaraResponse)JSON.deserialize(res.getBody(), AvalaraResponse.class);
                final String error = response.isEmpty() ? '' : String.format('{0} [{1}]', new List<String> {
                        response.messages[0].get('Summary'),
                        response.messages[0].get('Details')});
                return new Result(false, error);
            }
        }
        return new Result(true, null);
    }
    
    public class AvalaraResponse {
        public List<Map<String, String>> messages;
        
        public Boolean isEmpty() {
            return messages == null || messages.isEmpty();
        }
    }
    
    public class Result {
        private Boolean valid;
        private String message;
        
        public Result(final Boolean valid, final String message) {
            this.valid = valid;
            this.message = message;
        }
        
        public String getMessage() {
            return this.message;
        }
        
        public Boolean isValid() {
            return valid;
        }
    }
}
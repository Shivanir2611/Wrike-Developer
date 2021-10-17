public class DocuSignRestApiService {

    public static DocuSignRestApiService getInstance() {
        return (DocuSignRestApiService)ServiceLocator.getInstance(DocuSignRestApiService.class);
    }

    public String getEnvelopeStatus(final String envelopeId) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(getEndpoint(envelopeId));
        request.setMethod('GET');
        request.setHeader('X-DocuSign-Authentication', getCredentialsHeader());
        final HTTPResponse response = new Http().send(request);
        if (response.getStatusCode() == 200) {
            final StatusResponse responseData =
                    (StatusResponse)JSON.deserialize(response.getBody(), StatusResponse.class);
            return responseData.status;
        }
        return null;
    }

    public Boolean voidEnvelope(final String envelopeId) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(getEndpoint(envelopeId));
        request.setMethod('PUT');
        request.setHeader('X-DocuSign-Authentication', getCredentialsHeader());
        request.setBody(JSON.serialize(new Map<String, String>{
            'status' => 'voided',
            'voidedReason' => '-'
        }));
        final HTTPResponse response = new Http().send(request);
        return response.getStatusCode() == 200;
    }

    private class StatusResponse {
        public String status {get; set;}
    }

    private String getEndpoint(final String envelopeId) {
        return 'callout:DocuSign/accounts/'
                + CPQSettings__c.getInstance().DocuSignAccountId__c
                + '/envelopes/'
                + envelopeId;
    }

    private String getCredentialsHeader() {
        return '<DocuSignCredentials>' +
                '<Username>{!$Credential.Username}</Username>' +
                '<Password>{!$Credential.Password}</Password>' +
                '<IntegratorKey>' + CPQSettings__c.getInstance().DocuSignIntegratorKey__c + '</IntegratorKey>' +
                '</DocuSignCredentials>';
    }
}
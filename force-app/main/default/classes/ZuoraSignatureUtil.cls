public class ZuoraSignatureUtil {

    public static Response requestSignature() {
        final HttpRequest req = new HttpRequest();
        final Settings__c settings = Settings__c.getInstance();
        req.setEndpoint(settings.ZuoraApiUrl__c + 'apps/v1/rsa-signatures');
        req.setMethod('POST');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apiAccessKeyId', WrikeUtil.decrypt(settings.ZuoraLogin__c));
        req.setHeader('apiSecretAccessKey', WrikeUtil.decrypt(settings.ZuoraPassword__c));
        req.setBody(JSON.serialize(new Map<String, String> { 
            'uri' => settings.ZuoraUrl__c + 'apps/PublicHostedPageLite.do',
            'method' => 'POST',
            'pageId' => settings.ZuoraPaymentPageId__c}));
        final HttpResponse res = new Http().send(req);
        return (Response)JSON.deserialize(res.getBody(), Response.class);
    }
    
    public class Response {
        public Boolean success {get; set;}
        public String token {get; set;}
        public String key {get; set;}
        public String tenantId {get; set;}
        public String signature {get; set;}
        public List<Map<String, String>> reasons {get; set;}
    }
}
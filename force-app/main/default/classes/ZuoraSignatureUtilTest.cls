@IsTest
public class ZuoraSignatureUtilTest {
    
    @IsTest
    public static void testRequestSignature() {
        TestDataFactory.insertSettings();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraSignatureMock());
        final ZuoraSignatureUtil.Response requestSignature = ZuoraSignatureUtil.requestSignature();
        Test.stopTest();
        System.assertEquals(true, requestSignature.success);
        System.assertEquals('YsDrDyIPsklC2PhIDAYnMka7uqRpg4AV', requestSignature.token);
        System.assertEquals('testkey', requestSignature.key);
        System.assertEquals('12345', requestSignature.tenantId);
        System.assertEquals('testsgn', requestSignature.signature);
    }
    
    public class ZuoraSignatureMock implements HttpCalloutMock {
        public HttpResponse respond(final HttpRequest req) {
            final HttpResponse res = new HttpResponse();
            System.assertEquals('POST', req.getMethod());
            System.assertEquals('application/json', req.getHeader('Accept'));
            System.assertEquals('application/json', req.getHeader('Content-Type'));
            System.assert(req.getHeader('apiAccessKeyId') != null, 'No access key id header.');
            System.assert(req.getHeader('apiSecretAccessKey') != null, 'No secret access key id header.');
            System.assert(req.getHeader('apiSecretAccessKey') != null, 'No secret access key id header.');
            final Map<String, String> params = (Map<String, String>)JSON.deserialize(req.getBody(), Map<String, String>.class);
            System.assertEquals('POST', params.get('method'));
            System.assert(params.get('uri').contains('PublicHostedPageLite.do'), 'Uri is not valid.');
            System.assert(String.isNotBlank(params.get('pageId')), 'Pageid is blank.');
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true, "token":"YsDrDyIPsklC2PhIDAYnMka7uqRpg4AV", "tenantId":"12345", "signature":"testsgn", "key":"testkey"}');
            res.setStatusCode(200);
            return res;
        }
    }
}
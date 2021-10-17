@IsTest
public class ZuoraRestUpdateServiceTest {

    @IsTest
    static void testCreateBillingContact() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ObjectIdResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final String id =
                ZuoraRestUpdateService.getInstance().createBillingContact('zuoraAccountId', new BillingInfo(), 'CompanyName');
        Test.stopTest();

        System.assertEquals('123', id);
    }

    @IsTest
    static void testUpdateContact() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ObjectIdResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        ZuoraRestUpdateService.getInstance().updateContact('123', new BillingInfo(), 'CompanyName');
        Test.stopTest();
    }

    @IsTest
    static void testUpdateSubscriptionPurchaseOrderNumber() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ObjectIdResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        ZuoraRestUpdateService.getInstance().updateSubscriptionPurchaseOrderNumber('123', 'PurchaseOrderNumber');
        Test.stopTest();
    }

    final static String ObjectIdResponse = '[' +
    '	{' +
    '		"Success": true,' +
    '		"Id": "123"' +
    '	}' +
    ']';
}
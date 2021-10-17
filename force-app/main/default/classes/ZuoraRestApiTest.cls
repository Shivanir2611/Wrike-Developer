@IsTest
public class ZuoraRestApiTest {

    @IsTest
    static void testCreatePostRequestQuery() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody('{"done": true}');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));

        final Boolean done = (Boolean)ZuoraRestApi.getInstance().createPostRequest('/v1/action/query')
                .setRequestBody(JSON.serialize(new Map<String, String>{
        'queryString' => 'SELECT Id, Name FROM Subscription'
        }))
                .setResponseParser(JsonApi.parseField('done', Boolean.class).required().parser())
                .execute();

        Test.stopTest();

        System.assertEquals(true, done);
    }

    @IsTest
    static void testCreateObject() {
        final String ObjectIdResponse = '[' +
                '	{' +
                '		"Success": true,' +
                '		"Id": "123"' +
                '	}' +
                ']';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody(ObjectIdResponse);

        final ZuoraObject.ZuoraAccount account = new ZuoraObject.ZuoraAccount();
        account.id = '123';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final String id = ZuoraRestApi.getInstance().createObject(account, 'Account');
        Test.stopTest();

        System.assertEquals('123', id);
    }

    @IsTest
    static void testUpdateObject() {
        final String ObjectIdResponse = '[' +
                '	{' +
                '		"Success": true,' +
                '		"Id": "123"' +
                '	}' +
                ']';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody(ObjectIdResponse);

        final ZuoraObject.ZuoraAccount account = new ZuoraObject.ZuoraAccount();
        account.id = '123';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final String id = ZuoraRestApi.getInstance().updateObject(account, 'Account');
        Test.stopTest();

        System.assertEquals('123', id);
    }

    @IsTest
    static void testGenerateObject() {
        final String ObjectIdResponse = '[' +
                '	{' +
                '		"Success": true,' +
                '		"Id": "123"' +
                '	}' +
                ']';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody(ObjectIdResponse);

        final ZuoraObject.ZuoraAccount account = new ZuoraObject.ZuoraAccount();
        account.id = '123';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final Map<String, Object> result = ZuoraRestApi.getInstance().generate(account);
        Test.stopTest();

        System.assertEquals('123', result.get('Id'), result);
    }

    @IsTest
    static void testQuery() {
        final String ProductResponse = '{' +
        '  "records": [' +
        '    {' +
        '      "Id": "productId1",' +
        '      "Name": "productName1"' +
        '    }' +
        '  ],' +
        '  "size": 2,' +
        '  "done": true' +
        '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody(ProductResponse);

        final String zoql = 'SELECT Id, Name, Description, serviceType__c, SKU FROM Product ' +
                'WHERE EffectiveEndDate > \'' + Date.today() + '\' AND salesQuotes__c = \'Enabled\'';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraProduct> result = (List<ZuoraObject.ZuoraProduct>) ZuoraRestApi.getInstance().query(zoql, List<ZuoraObject.ZuoraProduct>.class);
        Test.stopTest();

        System.assertEquals('productId1', result.get(0).id);
    }
}
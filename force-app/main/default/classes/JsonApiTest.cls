@IsTest
public class JsonApiTest {

    @IsTest
    static void testTypeParser() {
        String json = JSON.serialize(TestDataFactory.createAccount());

        Account account = (Account)JsonApi.typeParser(Account.class).parse(json);

        System.assertEquals(TestDataFactory.TEST_NAME, account.Name);
        System.assertEquals('USD', account.CurrencyIsoCode);
    }

    @IsTest
    static void testSingleFieldParser() {
        String json = JSON.serialize(new Map<String, Object> {
        'records' => new List<Account> {
                TestDataFactory.createAccount(),
                TestDataFactory.createAccount()
                },
        'done' => true
        });

        List<Account> accounts = (List<Account>)JsonApi.parseField('records', List<Account>.class)
                .required()
                .parser()
                .parse(json);

        System.assertEquals(2, accounts.size());
    }

    @IsTest
    static void testFieldMapParserHasValidRequired() {
        String json = JSON.serialize(new Map<String, Object> {
        'size' => 2,
        'done' => true
        });

        Map<String, Object> result = (Map<String, Object>)JsonApi.parseFields()
                .field('size', Integer.class)
                .field('done', Boolean.class).requiredValue(true)
                .parser()
                .parse(json);

        System.assertEquals(2, result.get('size'));
        System.assertEquals(true, result.get('done'));
    }

    @IsTest
    static void testFieldMapParserHasNotRequired() {
        String json = JSON.serialize(new Map<String, Object> {
        'size' => 2,
        'success' => true
        });

        try {
            JsonApi.parseFields()
                    .field('size', Integer.class)
                    .field('success', Boolean.class)
                    .field('done', Boolean.class).required()
                    .parser()
                    .parse(json);
        } catch (JsonApi.JsonApiException e) {
            System.assert(e.getMessage().contains('required field not found'));
        }
    }

    @IsTest
    static void testFieldMapParserHasInvalidRequired() {
        String json = JSON.serialize(new Map<String, Object> {
        'size' => 2,
        'done' => false
        });

        try {
            JsonApi.parseFields()
                    .field('size', Integer.class)
                    .field('done', Boolean.class).requiredValue(true)
                    .parser()
                    .parse(json);
        } catch (JsonApi.JsonApiException e) {
            System.assert(e.getMessage().contains('can not be'));
        }
    }

    @IsTest
    static void testListOfMapsParserHasValidRequired() {
        String json = '[' +
                '	{' +
                '		"size": 3,' +
                '		"done": true,' +
                '		"mainAccount": {' +
                '			"Id": "12"' +
                '		},' +
                '   	"accounts": [' +
                '			{' +
                '				"Id": "123"' +
                '			},' +
                '			{' +
                '				"Id": "1234"' +
                '			}' +
                '		]' +
                '	},' +
                '	{' +
                '		"size": 4,' +
                '		"done": true' +
                '	},' +
                '   {' +
                '		"size": 5,' +
                '		"done": true' +
                '	}' +
                ']';

        List<Map<String, Object>> result = (List<Map<String, Object>>)JsonApi.parseList()
                .field('size', Integer.class)
                .field('accounts', List<ZuoraObject.ZuoraAccount>.class)
                .field('mainAccount', ZuoraObject.ZuoraAccount.class)
                .field('done', Boolean.class).requiredValue(true)
                .parser()
                .parse(json);

        System.assertEquals(3, result.size());
        System.assertEquals(3, result.get(0).get('size'));
        System.assertEquals(2, ((List<ZuoraObject.ZuoraAccount>)result.get(0).get('accounts')).size());
        System.assertEquals(true, result.get(0).get('done'));
    }

    @IsTest
    static void testListOfMapsParserHasNotRequired() {
        String json = '[' +
                '	{' +
                '		"size": 3,' +
                '		"success": true' +
                '	},' +
                '	{' +
                '		"size": 4,' +
                '		"done": true' +
                '	},' +
                '   {' +
                '		"size": 5,' +
                '		"done": true' +
                '	}' +
                ']';

        try {
            JsonApi.parseList()
                    .field('size', Integer.class)
                    .field('success', Boolean.class)
                    .field('done', Boolean.class).required()
                    .parser()
                    .parse(json);
        } catch (JsonApi.JsonApiException e) {
            System.assert(e.getMessage().contains('required field not found'));
        }
    }

    @IsTest
    static void testListOfMapsParserHasInvalidRequired() {
        String json = '[' +
                '	{' +
                '		"size": 3,' +
                '		"done": true' +
                '	},' +
                '	{' +
                '		"size": 4,' +
                '		"done": false' +
                '	},' +
                '   {' +
                '		"size": 5,' +
                '		"done": true' +
                '	}' +
                ']';

        try {
            JsonApi.parseList()
                    .field('size', Integer.class)
                    .field('done', Boolean.class).requiredValue(true)
                    .parser()
                    .parse(json);
        } catch (JsonApi.JsonApiException e) {
            System.assert(e.getMessage().contains('can not be'));
        }
    }
}
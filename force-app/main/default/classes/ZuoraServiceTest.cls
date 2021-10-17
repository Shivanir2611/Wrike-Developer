@IsTest
public class ZuoraServiceTest {

    @IsTest
    static void testZuoraObjectGetAccountFieldValueMap() {
        ZuoraObject.ZuoraAccount account = new ZuoraObject.ZuoraAccount();
        account.id = '123';
        account.name = 'Name';
        account.currencyCode = ZuoraCurrency.USD.name();

        Map<String, Object> fieldValueMap = account.getFieldValueMap();

        System.assertEquals('123', fieldValueMap.get('Id'));
        System.assertEquals('Name', fieldValueMap.get('Name'));
        System.assertEquals(ZuoraCurrency.USD.name(), fieldValueMap.get('Currency'));
    }

    @IsTest
    static void testZuoraObjectGetContactFieldValueMap() {
        ZuoraObject.ZuoraContactWithCompanyName contact = new ZuoraObject.ZuoraContactWithCompanyName();
        contact.id = '123';
        contact.firstName = 'FirstName';
        contact.companyName = 'CompanyName';

        Map<String, Object> fieldValueMap = contact.getFieldValueMap();

        System.assertEquals('123', fieldValueMap.get('Id'));
        System.assertEquals('FirstName', fieldValueMap.get('FirstName'));
        System.assertEquals('CompanyName', fieldValueMap.get('Company__c'));
    }

    @IsTest
    static void testZuoraObjectGetSubscriptionFieldValueMap() {
        ZuoraObject.ZuoraSubscription subscription = new ZuoraObject.ZuoraSubscription();
        subscription.id = '123';
        subscription.accountName = 'AccountName';

        Map<String, Object> fieldValueMap = subscription.getFieldValueMap();

        System.assertEquals('123', fieldValueMap.get('Id'));
        System.assertEquals('AccountName', fieldValueMap.get('AccountName'));
    }

    @IsTest
    static void testGenerateInvoice() {
        final ZuoraRestApi zuoraRestApi = (ZuoraRestApi)MockApi.mock(ZuoraRestApi.class);
        MockApi.setup()
                .mock(zuoraRestApi.updateObject(null, null), 'successId')
                .mock(zuoraRestApi.generate(null), new Map<String, Object> { 'Id' => 'successId', 'Success' => true })
                .build();

        Test.startTest();
        ZuoraService.getInstance().generateInvoice('account_id', Date.today(), Date.today());
        Test.stopTest();
    }


    @IsTest
    static void testUpdatePaymentInfo() {
        final ZuoraObject.ZuoraContact contact = new ZuoraObject.ZuoraContact();
        contact.id = 'contactId';
        contact.workEmail = 'test@mail.com';

        final ZuoraObject.ZuoraAccount account = new ZuoraObject.ZuoraAccount();
        account.id = '123';
        account.soldToId = 'contactId';

        final ZuoraRestQueryService zuoraRestQuerySrv = MockApi.zuoraRestQueryService();
        final ZuoraRestUpdateService zuoraRestUpdateSrv = (ZuoraRestUpdateService)MockApi.mock(ZuoraRestUpdateService.class);
        final ZuoraRestApi zuoraRestApi = (ZuoraRestApi)MockApi.mock(ZuoraRestApi.class);
        MockApi.setup()
                .mock(zuoraRestQuerySrv.findContactMap('123'), new Map<String, ZuoraObject.ZuoraContact> {contact.workEmail => contact})
                .mock(zuoraRestUpdateSrv.createBillingContact('123', null, 'Company Name'), 'billingContactId')
                .mock(zuoraRestQuerySrv.findZuoraAccountById('123'), account)
                .mock(zuoraRestQuerySrv.getCheckPaymentMethodId('checkPaymentMethodId'), 'newPaymentMethodId')
                .mock(zuoraRestApi.updateObject(null, 'Account'), 'successId')
                .build();

        Test.startTest();
        ZuoraService.getInstance().updatePaymentInfo('123', false, new BillingInfo(), 'creditCardId', '0', '12', 'Company Name');
        Test.stopTest();
    }

    @IsTest
    static void testFindBillingInfo() {
        final ZuoraObject.ZuoraAccount account = new ZuoraObject.ZuoraAccount();
        account.id = '123';
        account.soldToId = 'contactId';

        final ZuoraObject.ZuoraContact billingContact = new ZuoraObject.ZuoraContact();
        billingContact.id = 'contactId';
        billingContact.postalCode = '00000';

        MockApi.setup()
                .mock(MockApi.zuoraRestQueryService().findAccountSoldToIdAndVatNumber('123'), account)
                .mock(MockApi.zuoraRestQueryService().findBillingContact('contactId', '123'), billingContact)
                .build();

        Test.startTest();
        final BillingInfo billingInfo = ZuoraService.getInstance().findBillingInfo('123');
        Test.stopTest();

        System.assert(billingInfo != null);
        System.assertEquals('00000', billingInfo.zip);
    }
}
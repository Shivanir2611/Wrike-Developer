@IsTest
public class ZuoraRestQueryServiceTest {

    @IsTest
    static void testNonexistentAccountRequest() {
        final String EmptyResponse = '{' +
                '  "records" : [],' +
                '  "size" : 0,' +
                '  "done" : true' +
                '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(EmptyResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final ZuoraObject.ZuoraAccount zuoraAccount =
                ZuoraRestQueryService.getInstance().findZuoraAccountByWrikeAccountId(123);
        Test.stopTest();

        System.assertEquals(null, zuoraAccount);
    }

    @IsTest
    static void testFindZuoraAccountById() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ZuoraAccountResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final ZuoraObject.ZuoraAccount zuoraAccount =
                ZuoraRestQueryService.getInstance().findZuoraAccountById('123');
        Test.stopTest();

        System.assert(zuoraAccount != null, 'No account returned');
        System.assertEquals('Active', zuoraAccount.status, 'Status is incorrect');
        System.assertEquals('Default_Payment_Method_Id', zuoraAccount.defaultPaymentMethodId,
                'DefaultPaymentMethodId is incorrect');
        System.assertEquals('BillToId', zuoraAccount.billToId, 'BillToId is incorrect');
        System.assertEquals('SoldToId', zuoraAccount.soldToId, 'SoldToId is incorrect');
        System.assertEquals('VatNumber', zuoraAccount.vatNumber, 'VatNumber is incorrect');
    }

    @IsTest
    static void testFindZuoraAccountByWrikeAccountId() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ZuoraAccountResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final ZuoraObject.ZuoraAccount zuoraAccount =
                ZuoraRestQueryService.getInstance().findZuoraAccountByWrikeAccountId(123);
        Test.stopTest();

        System.assert(zuoraAccount != null, 'No account returned');
        System.assertEquals(zuoraAccount.accountNumber, '123', 'Wrong account number');
        System.assertEquals(zuoraAccount.crmId, 'CrmId', 'CrmId is incorrect');
        System.assertEquals(zuoraAccount.status, 'Active', 'Status is incorrect');
        System.assertEquals(zuoraAccount.name, 'AccName', 'Acc name is incorrect');
        System.assertEquals(zuoraAccount.id, 'AccId', 'Acc id is incorrect');
        System.assertEquals(zuoraAccount.currencyCode, ZuoraCurrency.EUR.name(), 'CurrencyCode is incorrect');
    }

    @IsTest
    static void testFindZuoraAccountIdByWrikeAccountId() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ZuoraAccountResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final String zuoraAccountId = ZuoraRestQueryService.getInstance().findZuoraAccountIdByWrikeAccountId(123);
        Test.stopTest();

        System.assertEquals('AccId', zuoraAccountId, 'Acc id is incorrect');
    }

    @IsTest
    static void testGetZuoraAccounts() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ZuoraAccountResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraAccount> zuoraAccounts = ZuoraRestQueryService.getInstance().getZuoraAccounts('AccId', 123, 'Active');
        Test.stopTest();

        System.assertEquals('AccId', zuoraAccounts.get(0).id, 'Acc id is incorrect');
    }

    @IsTest
    static void testFindFullSubscriptionsByZuoraAccountId() {
        final HttpResponse res = new HttpResponse();
        res.setBody(SubscriptionsWithRatePlansResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraSubscriptionWithRatePlans> allSubscriptions =
                (List<ZuoraObject.ZuoraSubscriptionWithRatePlans>)
                        ZuoraRestQueryService.getInstance().findAllSubscriptionsByZuoraAccountId(
                                '123test');
        Test.stopTest();

        System.assert(allSubscriptions != null, 'Null list returned');
        System.assert(!allSubscriptions.isEmpty(), 'Empty list returned');
        System.assert(allSubscriptions.size() == 1);
        ZuoraObject.ZuoraSubscriptionWithRatePlans sub = allSubscriptions.get(0);
        System.assertEquals('Active', sub.status, 'Status is invalid');
        System.assertEquals('subNumber', sub.subscriptionNumber, 'Subscription number is invalid');
        System.assertEquals('subTermType', sub.termType, 'Subscription term type is invalid');
        System.assertEquals(Date.Today().addDays(-2), sub.contractEffectiveDate, 'contractEffectiveDate is invalid');
        System.assertEquals(Date.Today().addDays(-1), sub.subscriptionStartDate, 'subscriptionStartDate is invalid');
        System.assertEquals(Date.Today(), sub.termStartDate, 'termStartDate is invalid');
        System.assertEquals(Date.Today().addYears(-1), sub.termEndDate, 'termEndDate is invalid');
        System.assertEquals(false, sub.isEvergreen(), 'isEvergreen is invalid');

        final List<ZuoraObject.ZuoraRatePlanWithCharges> ratePlans = sub.ratePlans;
        System.assert(ratePlans != null, 'Null rate plans');
        System.assertEquals(2, ratePlans.size(), 'Rate plans size is invalid');
        final ZuoraObject.ZuoraRatePlanWithCharges ratePlan1 = ratePlans.get(0);
        System.assertEquals('ratePlanId1', ratePlan1.id, 'Rate plan 1 id is invalid');
        System.assertEquals('ratePlanName1', ratePlan1.ratePlanName, 'ratePlanName1 is invalid');
        System.assertEquals('productId1', ratePlan1.productId, 'productId1 is invalid');
        System.assertEquals('productRatePlanId1', ratePlan1.productRatePlanId, 'productRatePlanId1 is invalid');
        final ZuoraObject.ZuoraRatePlan ratePlan2 = ratePlans.get(1);
        System.assertEquals('ratePlanId2', ratePlan2.id, 'Rate plan 2 id is invalid');
        System.assertEquals('ratePlanName2', ratePlan2.ratePlanName, 'ratePlanName2 is invalid');
        System.assertEquals('productId2', ratePlan2.productId, 'productId2 is invalid');
        System.assertEquals('productRatePlanId2', ratePlan2.productRatePlanId, 'productRatePlanId2 is invalid');

        final List<ZuoraObject.ZuoraRatePlanChargeWithTiers> ratePlanCharges1 =
                ratePlan1.ratePlanCharges;
        System.assert(ratePlanCharges1 != null, 'Null ratePlanCharges1');
        System.assertEquals(1, ratePlanCharges1.size(), 'ratePlanCharges1 size is invalid');
        final ZuoraObject.ZuoraRatePlanChargeWithTiers rpc1 = ratePlanCharges1.get(0);
        System.assertEquals('billingPeriod1', rpc1.billingPeriod, 'ratePlanCharge billingPeriod1 is invalid');
        System.assertEquals('description1', rpc1.description, 'ratePlanCharge description1 is invalid');
        System.assertEquals('listPriceBase1', rpc1.listPriceBase, 'ratePlanCharge listPriceBase1 is invalid');
        System.assertEquals('rpcName', rpc1.name, 'ratePlanCharge name is invalid');
        System.assertEquals('prpcId', rpc1.productRatePlanChargeId,
                'ratePlanCharge productRatePlanChargeId is invalid');
        System.assertEquals('rpcId', rpc1.id, 'ratePlanCharge id is invalid');
        System.assertEquals('rpcModel', rpc1.model, 'ratePlanCharge model is invalid');
        System.assertEquals('Recurring', rpc1.type, 'ratePlanCharge type is invalid');
        System.assertEquals(12345, rpc1.mrr, 'ratePlanCharge mrr is invalid');
        System.assertEquals(7, rpc1.quantity, 'ratePlanCharge quantity is invalid');
        System.assertEquals(1, rpc1.segment, 'ratePlanCharge segment is invalid');

        final List<ZuoraObject.ZuoraRatePlanChargeTier> tiers = rpc1.tiers;
        System.assert(tiers != null, 'Null tiers');
        System.assertEquals(2, tiers.size(), 'tiers size is invalid');
        final ZuoraObject.ZuoraRatePlanChargeTier tier1 = tiers.get(0);
        System.assertEquals(1, tier1.startingUnit, 'tier1 price is invalid');
        System.assertEquals(5, tier1.endingUnit, 'tier1 price is invalid');
        System.assertEquals(5, tier1.price, 'tier1 price is invalid');
        System.assertEquals('FlatFee', tier1.priceFormat, 'tier1 price is invalid');
        final ZuoraObject.ZuoraRatePlanChargeTier tier2 = tiers.get(1);
        System.assertEquals(6, tier2.startingUnit, 'tier2 price is invalid');
        System.assertEquals(10, tier2.endingUnit, 'tier2 price is invalid');
        System.assertEquals(9, tier2.price, 'tier2 price is invalid');
        System.assertEquals('FlatFee', tier2.priceFormat, 'tier2 price is invalid');
    }

    @IsTest
    static void testGetCheckPaymentMethodId() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(PaymentMethodResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final String checkPaymentMethodId = ZuoraRestQueryService.getInstance().getCheckPaymentMethodId(null);
        Test.stopTest();

        System.assertEquals('123', checkPaymentMethodId);
    }

    @IsTest
    static void testFindContactMap() {
        final String contactsResponse = '{' +
                '  "records": [' +
                '    {' +
                '      "State": "Arizona",' +
                '      "Country": "United States",' +
                '      "WorkEmail": "mail@testmail.com",' +
                '      "Id": "123"' +
                '    }' +
                '  ],' +
                '  "size": 1,' +
                '  "done": true' +
                '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(contactsResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final Map<String, ZuoraObject.ZuoraContact> contactMap =
                ZuoraRestQueryService.getInstance().findContactMap('123');
        Test.stopTest();

        final ZuoraObject.ZuoraContact contact = contactMap.get('mail@testmail.com');
        System.assertNotEquals(null, contact);
        System.assertEquals('123', contact.id);
        System.assertEquals('United States', contact.country);
        System.assertEquals('Arizona', contact.state);
    }

    @IsTest
    static void testFindAccountSoldToIdAndVatNumber() {
        final String accountSoldToIdAndVatNumberResponse = '{' +
                '  "records": [' +
                '    {' +
                '      "VatNumber__c": "RURU",' +
                '      "SoldToId": "1234",' +
                '      "Id": "123"' +
                '    }' +
                '  ],' +
                '  "size": 1,' +
                '  "done": true' +
                '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(accountSoldToIdAndVatNumberResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final ZuoraObject.ZuoraAccount account =
                ZuoraRestQueryService.getInstance().findAccountSoldToIdAndVatNumber('123');
        Test.stopTest();

        System.assertNotEquals(null, account);
        System.assertEquals('1234', account.soldToId);
        System.assertEquals('RURU', account.vatNumber);
    }

    @IsTest
    static void testFindBillingContact() {
        final String billingContactsResponse = '{' +
                '  "records": [' +
                '    {' +
                '      "State": "California",' +
                '      "Country": "United States",' +
                '      "City": "Mountain View",' +
                '      "Id": "1234",' +
                '      "FirstName": "FirstName",' +
                '      "Address1": "Evelyn Ave, 1",' +
                '      "LastName": "LastName",' +
                '      "PostalCode": "00000"' +
                '    }' +
                '  ],' +
                '  "size": 1,' +
                '  "done": true' +
                '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(billingContactsResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final ZuoraObject.ZuoraContact contact =
                ZuoraRestQueryService.getInstance().findBillingContact('1234', '123');
        Test.stopTest();

        System.assertNotEquals(null, contact);
        System.assertEquals('1234', contact.id);
        System.assertEquals('United States', contact.country);
        System.assertEquals('Mountain View', contact.city);
        System.assertEquals('00000', contact.postalCode);
        System.assertEquals('Evelyn Ave, 1', contact.address1);
        System.assertEquals('FirstName', contact.firstName);
        System.assertEquals('LastName', contact.lastName);
        System.assertEquals('California', contact.state);
    }

    @IsTest
    static void testFindProductsByIds() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ProductResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraProduct> products =
                ZuoraRestQueryService.getInstance().findProductsByIds(new Set<String>{'productId1', 'productId2'});
        Test.stopTest();

        final ZuoraObject.ZuoraProduct product = products.get(0);
        System.assertNotEquals(null, product);
        System.assertEquals('productId1', product.id);
        System.assertEquals('productName1', product.name);
        System.assertEquals('product description 1', product.description);
        System.assertEquals('serviceType1', product.serviceType);
    }

    @IsTest
    static void testFindProductsByEffectiveEndDate() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ProductResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraProduct> products =
                ZuoraRestQueryService.getInstance().findProductsByEffectiveEndDate(String.valueOf(Date.today()));
        Test.stopTest();

        final ZuoraObject.ZuoraProduct product = products.get(0);
        System.assertNotEquals(null, product);
        System.assertEquals('productId1', product.id);
        System.assertEquals('productName1', product.name);
        System.assertEquals('product description 1', product.description);
        System.assertEquals('serviceType1', product.serviceType);
    }

    @IsTest
    static void testFindProductRatePlansByEffectiveEndDateAndProductId() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(RatePlansResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraRatePlan> ratePlans =
                ZuoraRestQueryService.getInstance().findProductRatePlansByEffectiveEndDateAndProductId(
                        String.valueOf(Date.today()), 'productId1');
        Test.stopTest();

        final ZuoraObject.ZuoraRatePlan ratePlan = ratePlans.get(0);
        System.assertNotEquals(null, ratePlan);
        System.assertEquals('ratePlanId1', ratePlan.id);
        System.assertEquals('ratePlanName1', ratePlan.name);
        System.assertEquals('ratePlanDescription1', ratePlan.description);
        System.assertEquals('productId1', ratePlan.productId);
    }

    @IsTest
    static void testFindProductRatePlansByEffectiveEndDate() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(RatePlansResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraRatePlan> ratePlans =
                ZuoraRestQueryService.getInstance().findProductRatePlansByEffectiveEndDate(String.valueOf(Date.today()));
        Test.stopTest();

        final ZuoraObject.ZuoraRatePlan ratePlan = ratePlans.get(0);
        System.assertNotEquals(null, ratePlan);
        System.assertEquals('ratePlanId1', ratePlan.id);
        System.assertEquals('ratePlanName1', ratePlan.name);
        System.assertEquals('ratePlanDescription1', ratePlan.description);
        System.assertEquals('productId1', ratePlan.productId);
    }

    @IsTest
    static void testFindProductsRatePlanCharges() {
        final String ratePlanChargesResponse = '{' +
                '   "records": [' +
                '		{' +
                '       	"id": "rpcId",' +
                '           "ChargeModel": "chargeModel",' +
                '           "ChargeType": "chargeType",' +
                '           "name": "rpcName",' +
                '           "listPriceBase": "listPriceBase1",' +
                '           "billingPeriod": "billingPeriod1",' +
                '           "ProductRatePlanId": "productRatePlanId"' +
                '       }' +
                '	],' +
                '	"size": 1,' +
                '	"done": true' +
                '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ratePlanChargesResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraRatePlanCharge> ratePlanCharges =
                ZuoraRestQueryService.getInstance().findProductsRatePlanCharges();
        Test.stopTest();

        final ZuoraObject.ZuoraRatePlanCharge ratePlanCharge = ratePlanCharges.get(0);
        System.assertNotEquals(null, ratePlanCharge);
        System.assertEquals('rpcId', ratePlanCharge.id);
        System.assertEquals('rpcName', ratePlanCharge.name);
        System.assertEquals('chargeModel', ratePlanCharge.chargeModel);
        System.assertEquals('chargeType', ratePlanCharge.chargeType);
        System.assertEquals('productRatePlanId', ratePlanCharge.productRatePlanId);
        System.assertEquals('billingPeriod1', ratePlanCharge.billingPeriod);
        System.assertEquals('listPriceBase1', ratePlanCharge.listPriceBase);
    }

    @IsTest
    static void testFindRatePlanChargesByProductRatePlanChargeIds() {
        final String ratePlanChargesResponse = '{' +
                '   "records": [' +
                '		{' +
                '           "ChargeNumber": "C-123",' +
                '           "ProductRatePlanChargeId": "productRatePlanChargeId"' +
                '       }' +
                '	],' +
                '	"size": 1,' +
                '	"done": true' +
                '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ratePlanChargesResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraRatePlanCharge> ratePlanCharges =
                ZuoraRestQueryService.getInstance().findRatePlanChargesByProductRatePlanChargeIds(new List<String> {'123'});
        Test.stopTest();

        final ZuoraObject.ZuoraRatePlanCharge ratePlanCharge = ratePlanCharges.get(0);
        System.assertNotEquals(null, ratePlanCharge);
        System.assertEquals('productRatePlanChargeId', ratePlanCharge.productRatePlanChargeId);
        System.assertEquals('C-123', ratePlanCharge.chargeNumber);
    }

    @IsTest
    static void testFindProductsRatePlanChargeTiersByCurrency() {
        final String ratePlanChargeTiersResponse = '{' +
                '   "records": [' +
                '   	{' +
                '			"id": "tierId1",' +
                '       	"tier": 1,' +
                '           "startingUnit": 1,' +
                '           "endingUnit": 5,' +
                '           "price": 5,' +
                '           "priceFormat": "FlatFee",' +
                '			"ProductRatePlanChargeId": "rpcId1"' +
                '       },' +
                '       {' +
                '			"id": "tierId2",' +
                '           "tier": 2,' +
                '           "startingUnit": 6,' +
                '           "endingUnit": 10,' +
                '           "price": 9,' +
                '           "priceFormat": "FlatFee",' +
                '			"ProductRatePlanChargeId": "rpcId2"' +
                '       }' +
                '   ],' +
                '	"size": 2,' +
                '	"done": true' +
                '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ratePlanChargeTiersResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraRatePlanChargeTier> ratePlanChargeTiers =
                ZuoraRestQueryService.getInstance().findProductsRatePlanChargeTiersByCurrency(ZuoraCurrency.USD);
        Test.stopTest();

        final ZuoraObject.ZuoraRatePlanChargeTier ratePlanChargeTier = ratePlanChargeTiers.get(0);
        System.assertNotEquals(null, ratePlanChargeTier);
        System.assertEquals('tierId1', ratePlanChargeTier.id);
        System.assertEquals(1, ratePlanChargeTier.tier);
        System.assertEquals(1, ratePlanChargeTier.startingUnit);
        System.assertEquals(5, ratePlanChargeTier.endingUnit);
        System.assertEquals(5, ratePlanChargeTier.price);
        System.assertEquals('FlatFee', ratePlanChargeTier.priceFormat);
        System.assertEquals('rpcId1', ratePlanChargeTier.productRatePlanChargeId);
    }

    @IsTest
    static void testFindCreditCardInfoById() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(PaymentMethodResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final BillingInfo billingInfo =
                ZuoraRestQueryService.getInstance().findCreditCardInfoById('123', false);
        Test.stopTest();

        System.assertNotEquals(null, billingInfo);
        System.assertEquals('123', billingInfo.id);
        System.assertEquals('test@email.com', billingInfo.email);
        System.assertEquals('1', billingInfo.cardNumber);
        System.assertEquals(11, billingInfo.cardExpirationMonth);
        System.assertEquals(23, billingInfo.cardExpirationYear);
        System.assertEquals('Name', billingInfo.firstName);
        System.assertEquals('address 1', billingInfo.address1);
        System.assertEquals('address 2', billingInfo.address2);
        System.assertEquals('US', billingInfo.countryFullName);
        System.assertEquals('California', billingInfo.stateFullName);
        System.assertEquals('LA', billingInfo.city);
        System.assertEquals('12345', billingInfo.zip);
    }

    @IsTest
    static void testFindDefaultPaymentMethodId() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ZuoraAccountResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final String defaultPaymentMethodId = ZuoraRestQueryService.getInstance().findDefaultPaymentMethodId('123');
        Test.stopTest();

        System.assertEquals('Default_Payment_Method_Id', defaultPaymentMethodId, 'Default payment method id is incorrect');
    }

    @IsTest
    static void testGetAccountNameById() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ZuoraAccountResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final String accountName = ZuoraRestQueryService.getInstance().getAccountNameById('123');
        Test.stopTest();

        System.assertEquals('AccName', accountName, 'Account name is incorrect');
    }

    @IsTest
    static void testFindSubscriptionById() {
        final HttpResponse res = new HttpResponse();
        res.setBody(SubscriptionsResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final ZuoraObject.ZuoraSubscription subscription = ZuoraRestQueryService.getInstance().findSubscriptionById('subId');
        Test.stopTest();

        System.assert(subscription != null, 'Null subscription returned');
        System.assertEquals('subId', subscription.id);
        System.assertEquals('accId', subscription.accountId);
        System.assertEquals(Date.Today().addDays(-1), subscription.cancelledDate);
        System.assertEquals('prevSubId', subscription.previousSubscriptionId);
        System.assertEquals('Active', subscription.status);
        System.assertEquals(Date.Today().addDays(-2), subscription.contractEffectiveDate);
        System.assertEquals(12, subscription.currentTerm);
        System.assertEquals(12, subscription.renewalTerm);
        System.assertEquals(Date.Today().addYears(-1), subscription.termEndDate);
        System.assertEquals('subName', subscription.name);
    }

    @IsTest
    static void testFindAmendmentBySubscriptionId() {
        final String amendmentResponse = '{' +
        '   "records": [' +
        '   	{' +
        '			"Id": "amendmentId",' +
        '       	"Name": "amendmentName",' +
        '           "CreatedById": "1",' +
        '           "CreatedDate": "' + String.valueOf(Date.today().addDays(-1)) + '",' +
        '           "EffectiveDate": "' + String.valueOf(Date.today().addDays(-1)) + '"' +
        '       }' +
        '   ],' +
        '	"size": 2,' +
        '	"done": true' +
        '}';

        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(amendmentResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final ZuoraObject.ZuoraAmendment amendment =
                ZuoraRestQueryService.getInstance().findAmendmentBySubscriptionId('123');
        Test.stopTest();

        System.assertNotEquals(null, amendment);
        System.assertEquals('amendmentId', amendment.id);
        System.assertEquals('amendmentName', amendment.name);
        System.assertEquals('1', amendment.createdById);
        System.assertEquals(Date.today().addDays(-1), amendment.createdDate);
        System.assertEquals(Date.today().addDays(-1), amendment.effectiveDate);
    }

    @IsTest
    static void testFindSubscriptionsByZuoraAccountId() {
        final HttpResponse res = new HttpResponse();
        res.setBody(SubscriptionsResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraSubscription> subscriptions =
                (List<ZuoraObject.ZuoraSubscription>) ZuoraRestQueryService.getInstance().findSubscriptionsByZuoraAccountId('accId');
        final ZuoraObject.ZuoraSubscription subscription = subscriptions.get(0);
        Test.stopTest();

        System.assert(subscription != null, 'Null subscription returned');
        System.assertEquals('subId', subscription.id);
        System.assertEquals('subName', subscription.name);
        System.assertEquals('accId', subscription.accountId);
        System.assertEquals('Active', subscription.status);
        System.assertEquals(Date.Today().addDays(-2), subscription.contractEffectiveDate);
        System.assertEquals('subTermType', subscription.termType);
        System.assertEquals(12, subscription.currentTerm);
        System.assertEquals(12, subscription.renewalTerm);
        System.assertEquals(Date.Today(), subscription.termStartDate);
        System.assertEquals(Date.Today().addYears(-1), subscription.termEndDate);
        System.assertEquals(Date.Today().addDays(-1), subscription.subscriptionStartDate);
        System.assertEquals(Date.Today().addDays(-2), subscription.subscriptionEndDate);
    }

    @IsTest
    static void testFindAllProductsByEffectiveEndDate() {
        final HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ProductResponse);
        res.setStatusCode(200);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestUtils.ZuoraRestMock(res));
        final List<ZuoraObject.ZuoraProduct> products =
                ZuoraRestQueryService.getInstance().findAllProductsByEffectiveEndDate(String.valueOf(Date.today()));
        Test.stopTest();

        final ZuoraObject.ZuoraProduct product = products.get(0);
        System.assertNotEquals(null, product);
        System.assertEquals('productId1', product.id);
        System.assertEquals('productName1', product.name);
        System.assertEquals('product description 1', product.description);
        System.assertEquals('serviceType1', product.serviceType);
    }

    public static final String SubscriptionsWithRatePlansResponse = '{' +
    '  "subscriptions": [' +
    '    {' +
    '      "id": "subId",' +
    '      "Name": "subName",' +
    '      "PreviousSubscriptionId": "prevSubId",' +
    '      "RenewalTerm": 12,' +
    '      "accountId": "accId",' +
    '      "accountName": "accName",' +
    '      "subscriptionNumber": "subNumber",' +
    '      "termType": "subTermType",' +
    '      "contractEffectiveDate": "' + String.valueOf(Date.Today().addDays(-2)) + '",' +
    '      "subscriptionStartDate": "' + String.valueOf(Date.Today().addDays(-1)) + '",' +
    '      "subscriptionEndDate": "' + String.valueOf(Date.Today().addDays(-2)) + '",' +
    '      "termStartDate": "' + String.valueOf(Date.Today()) + '",' +
    '      "termEndDate": "' + String.valueOf(Date.Today().addYears(-1)) + '",' +
    '      "cancelledDate": "' + String.valueOf(Date.Today().addDays(-1)) + '",' +
    '      "currentTerm": 12,' +
    '      "status": "Active",' +
    '      "ratePlans": [' +
    '        {' +
    '          "id": "ratePlanId1",' +
    '          "productId": "productId1",' +
    '          "productName": "productName1",' +
    '          "productRatePlanId": "productRatePlanId1",' +
    '          "ratePlanName": "ratePlanName1",' +
    '          "ratePlanCharges": [' +
    '            {' +
    '              "id": "rpcId",' +
    '              "productRatePlanChargeId": "prpcId",' +
    '              "number": "rpcNumber",' +
    '              "name": "rpcName",' +
    '              "type": "Recurring",' +
    '              "model": "rpcModel",' +
    '              "price": null,' +
    '              "tiers": [' +
    '                {' +
    '                  "tier": 1,' +
    '                  "startingUnit": 1,' +
    '                  "endingUnit": 5,' +
    '                  "price": 5,' +
    '                  "priceFormat": "FlatFee"' +
    '                },' +
    '                {' +
    '                  "tier": 2,' +
    '                  "startingUnit": 6,' +
    '                  "endingUnit": 10,' +
    '                  "price": 9,' +
    '                  "priceFormat": "FlatFee"' +
    '                }' +
    '              ],' +
    '              "listPriceBase": "listPriceBase1",' +
    '              "billingPeriod": "billingPeriod1",' +
    '              "quantity": 7,' +
    '              "segment": 1,' +
    '              "mrr": 12345,' +
    '              "description": "description1"' +
    '            }' +
    '          ],' +
    '          "subscriptionProductFeatures": []' +
    '        },' +
    '        {' +
    '          "id": "ratePlanId2",' +
    '          "lastChangeType": "Add",' +
    '          "productId": "productId2",' +
    '          "productName": "productName2",' +
    '          "productRatePlanId": "productRatePlanId2",' +
    '          "ratePlanName": "ratePlanName2",' +
    '          "ratePlanCharges": [' +
    '            {' +
    '              "type": "notRecurring"' +
    '            }' +
    '          ],' +
    '          "subscriptionProductFeatures": []' +
    '        }' +
    '      ]' +
    '    }' +
    '  ],' +
    '  "success": true' +
    '}';

    public static final String SubscriptionsWithRatePlansWithPricePerUnitResponse = '{' +
    '  "subscriptions": [' +
    '    {' +
    '      "id": "subId",' +
    '      "Name": "subName",' +
    '      "PreviousSubscriptionId": "prevSubId",' +
    '      "RenewalTerm": 12,' +
    '      "accountId": "accId",' +
    '      "accountName": "accName",' +
    '      "subscriptionNumber": "subNumber",' +
    '      "termType": "subTermType",' +
    '      "contractEffectiveDate": "' + String.valueOf(Date.Today().addDays(-2)) + '",' +
    '      "subscriptionStartDate": "' + String.valueOf(Date.Today().addDays(-1)) + '",' +
    '      "subscriptionEndDate": "' + String.valueOf(Date.Today().addDays(-2)) + '",' +
    '      "termStartDate": "' + String.valueOf(Date.Today()) + '",' +
    '      "termEndDate": "' + String.valueOf(Date.Today().addYears(-1)) + '",' +
    '      "cancelledDate": "' + String.valueOf(Date.Today().addDays(-1)) + '",' +
    '      "currentTerm": 12,' +
    '      "status": "Active",' +
    '      "ratePlans": [' +
    '        {' +
    '          "id": "ratePlanId1",' +
    '          "productId": "productId1",' +
    '          "productName": "productName1",' +
    '          "productRatePlanId": "productRatePlanId1",' +
    '          "ratePlanName": "ratePlanName1",' +
    '          "ratePlanCharges": [' +
    '            {' +
    '              "id": "rpcId",' +
    '              "productRatePlanChargeId": "prpcId",' +
    '              "number": "rpcNumber",' +
    '              "name": "rpcName",' +
    '              "type": "Recurring",' +
    '              "model": "rpcModel",' +
    '              "price": null,' +
    '              "tiers": [' +
    '                {' +
    '                  "tier": 1,' +
    '                  "startingUnit": 1,' +
    '                  "price": 5,' +
    '                  "priceFormat": "PerUnit"' +
    '                },' +
    '                {' +
    '                  "tier": 2,' +
    '                  "startingUnit": 6,' +
    '                  "price": 9,' +
    '                  "priceFormat": "PerUnit"' +
    '                }' +
    '              ],' +
    '              "listPriceBase": "listPriceBase1",' +
    '              "billingPeriod": "billingPeriod1",' +
    '              "quantity": 7,' +
    '              "segment": 1,' +
    '              "mrr": 12345,' +
    '              "description": "description1"' +
    '            }' +
    '          ],' +
    '          "subscriptionProductFeatures": []' +
    '        },' +
    '        {' +
    '          "id": "ratePlanId2",' +
    '          "lastChangeType": "Add",' +
    '          "productId": "productId2",' +
    '          "productName": "productName2",' +
    '          "productRatePlanId": "productRatePlanId2",' +
    '          "ratePlanName": "ratePlanName2",' +
    '          "ratePlanCharges": [' +
    '            {' +
    '              "type": "notRecurring"' +
    '            }' +
    '          ],' +
    '          "subscriptionProductFeatures": []' +
    '        }' +
    '      ]' +
    '    }' +
    '  ],' +
    '  "success": true' +
    '}';

    private final static String SubscriptionsResponse = '{' +
    '  "records": [' +
    '    {' +
    '      "id": "subId",' +
    '      "Name": "subName",' +
    '      "PreviousSubscriptionId": "prevSubId",' +
    '      "RenewalTerm": 12,' +
    '      "accountId": "accId",' +
    '      "accountName": "accName",' +
    '      "subscriptionNumber": "subNumber",' +
    '      "termType": "subTermType",' +
    '      "contractEffectiveDate": "' + String.valueOf(Date.Today().addDays(-2)) + '",' +
    '      "subscriptionStartDate": "' + String.valueOf(Date.Today().addDays(-1)) + '",' +
    '      "subscriptionEndDate": "' + String.valueOf(Date.Today().addDays(-2)) + '",' +
    '      "termStartDate": "' + String.valueOf(Date.Today()) + '",' +
    '      "termEndDate": "' + String.valueOf(Date.Today().addYears(-1)) + '",' +
    '      "cancelledDate": "' + String.valueOf(Date.Today().addDays(-1)) + '",' +
    '      "currentTerm": 12,' +
    '      "status": "Active"' +
    '    }' +
    '  ],' +
    '  "size": 1,' +
    '  "done": true' +
    '}';

    private final static String ZuoraAccountResponse = '{' +
    '  "records": [' +
    '    {' +
    '      "AccountNumber": "123",' +
    '      "Status": "Active",' +
    '      "Id": "AccId",' +
    '      "Name": "AccName",' +
    '      "CrmId": "CrmId",' +
    '      "Currency": "EUR",' +
    '      "BillToId": "BillToId",' +
    '      "SoldToId": "SoldToId",' +
    '      "VatNumber__c": "VatNumber",' +
    '      "DefaultPaymentMethodId": "Default_Payment_Method_Id"' +
    '    }' +
    '  ],' +
    '  "size": 1,' +
    '  "done": true' +
    '}';

    private static final String ProductResponse = '{' +
    '  "records": [' +
    '    {' +
    '      "serviceType__c": "serviceType1",' +
    '      "Id": "productId1",' +
    '      "Name": "productName1",' +
    '      "Description": "product description 1"' +
    '    },' +
    '    {' +
    '      "serviceType__c": "serviceType2",' +
    '      "Id": "productId2",' +
    '      "Name": "productName2",' +
    '      "Description": "product description 2"' +
    '    }' +
    '  ],' +
    '  "size": 2,' +
    '  "done": true' +
    '}';

    private static final String PaymentMethodResponse = '{' +
    '  "records": [' +
    '    {' +
    '      "Id": "123",' +
    '      "Email": "test@email.com",' +
    '      "CreditCardHolderName": "Name",' +
    '      "CreditCardMaskNumber": "1",' +
    '      "CreditCardExpirationMonth": 11,' +
    '      "CreditCardExpirationYear": 23,' +
    '      "CreditCardAddress1": "address 1",' +
    '      "CreditCardAddress2": "address 2",' +
    '      "CreditCardCity": "LA",' +
    '      "CreditCardState": "California",' +
    '      "CreditCardCountry": "US",' +
    '      "CreditCardPostalCode": "12345"' +
    '    }' +
    '  ],' +
    '  "size": 1,' +
    '  "done": true' +
    '}';

    private static final String RatePlansResponse = '{' +
    '   "records": [' +
    '   	 {' +
    '   	   "id": "ratePlanId1",' +
    '          "productId": "productId1",' +
    '          "name": "ratePlanName1",' +
    '          "description": "ratePlanDescription1"' +
    '        },' +
    '        {' +
    '          "id": "ratePlanId2",' +
    '          "productId": "productId2",' +
    '          "name": "ratePlanName2",' +
    '          "description": "ratePlanDescription2"' +
    '        }' +
    '   ],' +
    '	"size": 2,' +
    '	"done": true' +
    '}';
}
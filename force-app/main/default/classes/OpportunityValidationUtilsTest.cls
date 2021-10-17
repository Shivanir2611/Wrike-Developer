@IsTest
public class OpportunityValidationUtilsTest {

    @IsTest
    static void testListSubscriptionProducts() {
        final List<ZuoraObject.ZuoraSubscriptionWithRatePlans> allSubscriptions =
                (List<ZuoraObject.ZuoraSubscriptionWithRatePlans>)JsonApi.parseField('subscriptions',
                                List<ZuoraObject.ZuoraSubscriptionWithRatePlans>.class)
                        .required()
                        .parser()
                        .parse(SubscriptionsWithRatePlansResponse);

        final ZuoraObject.ZuoraSubscriptionWithRatePlans sub = allSubscriptions.get(0);
        final List<OpportunityValidationUtils.SubscriptionProduct> sProducts = OpportunityValidationUtils.listSubscriptionProducts(sub);

        System.assert(sProducts != null, 'Null products');
        System.assertEquals(1, sProducts.size(), 'Products size is invalid');

        OpportunityValidationUtils.SubscriptionProduct sProduct = sProducts.get(0);
        ZuoraObject.ZuoraRatePlanChargeWithTiers charge = sub.ratePlans.get(0).ratePlanCharges.get(0);

        System.assertEquals(50, sProduct.mrr, 'Product mrr is invalid');
        System.assertEquals(charge.billingPeriod, sProduct.billingPeriod, 'Product billingPeriod is invalid');
        System.assertEquals(15, sProduct.quantity, 'Product quantity is invalid');
        System.assertEquals('Product Name', sProduct.name, 'Product name is invalid');
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
    '          "productName": "Product Name",' +
    '          "productRatePlanId": "productRatePlanId1",' +
    '          "ratePlanName": "ratePlanName1",' +
    '          "ratePlanCharges": [' +
    '            {' +
    '              "type": "Recurring",' +
    '              "billingPeriod": "Two Years",' +
    '              "quantity": 7,' +
    '              "mrr": 45' +
    '            }' +
    '          ],' +
    '          "subscriptionProductFeatures": []' +
    '        },' +
    '        {' +
    '          "id": "ratePlanId2",' +
    '          "lastChangeType": "Add",' +
    '          "productId": "productId1",' +
    '          "productName": "Product Name",' +
    '          "productRatePlanId": "productRatePlanId2",' +
    '          "ratePlanName": "ratePlanName2",' +
    '          "ratePlanCharges": [' +
    '            {' +
    '              "type": "Recurring",' +
    '              "quantity": 8,' +
    '              "mrr": 5,' +
    '              "billingPeriod": "Two Years"' +
    '            }' +
    '          ],' +
    '          "subscriptionProductFeatures": []' +
    '        }' +
    '      ]' +
    '    }' +
    '  ],' +
    '  "success": true' +
    '}';
}
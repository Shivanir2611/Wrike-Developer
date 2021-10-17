public class OpportunityValidationUtils {

    private static final String RECURRING = 'Recurring';

    public static List<SubscriptionProduct> listSubscriptionProducts(final ZuoraObject.ZuoraSubscriptionWithRatePlans subscription) {
        final Map<String, Map<String, ZuoraObject.ZuoraRatePlanChargeWithTiers>> ratePlanChargeMap
                = new Map<String, Map<String, ZuoraObject.ZuoraRatePlanChargeWithTiers>>();
        for (ZuoraObject.ZuoraRatePlanWithCharges ratePlan : subscription.ratePlans) {
            if (!ratePlan.wasRemovedFromSubscription()
                    && !String.isBlank(ratePlan.productName)
                    && ratePlan.ratePlanCharges != null
                    && !ratePlan.ratePlanCharges.isEmpty()) {
                for (ZuoraObject.ZuoraRatePlanChargeWithTiers ratePlanCharge : ratePlan.ratePlanCharges) {
                    if (ratePlanCharge.type == RECURRING) {
                        if (ratePlanChargeMap.containsKey(ratePlan.productName)) {
                            ratePlanChargeMap.get(ratePlan.productName).put(ratePlan.id, ratePlanCharge);
                        } else {
                            ratePlanChargeMap.put(
                                    ratePlan.productName,
                                    new Map<String, ZuoraObject.ZuoraRatePlanChargeWithTiers>{
                                            ratePlan.id => ratePlanCharge
                                    });
                        }
                    }
                }
            }
        }
        final List<SubscriptionProduct> subscriptionProducts = new List<SubscriptionProduct>();
        if (!ratePlanChargeMap.isEmpty()) {
            for (String productName : ratePlanChargeMap.keySet()) {
                final SubscriptionProduct subscriptionProduct = new SubscriptionProduct();
                subscriptionProduct.name = productName;
                subscriptionProduct.quantity = 0;
                subscriptionProduct.mrr = 0;
                final Map<String, ZuoraObject.ZuoraRatePlanChargeWithTiers> chargeByRatePlanIdMap =
                        ratePlanChargeMap.get(productName);
                for (String ratePlanId : chargeByRatePlanIdMap.keySet()) {
                    ZuoraObject.ZuoraRatePlanChargeWithTiers ratePlanCharge = chargeByRatePlanIdMap.get(ratePlanId);
                    subscriptionProduct.billingPeriod = ratePlanCharge.billingPeriod;
                    subscriptionProduct.quantity += ratePlanCharge.quantity;
                    subscriptionProduct.mrr += ratePlanCharge.mrr;
                }
                subscriptionProducts.add(subscriptionProduct);
            }
        }
        return subscriptionProducts;
    }

    public class SubscriptionProduct {
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String billingPeriod {get; set;}
        @AuraEnabled
        public Decimal quantity {get; set;}
        @AuraEnabled
        public Decimal mrr {get; set;}
    }
}
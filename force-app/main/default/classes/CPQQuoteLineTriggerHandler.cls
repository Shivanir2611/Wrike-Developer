public class CPQQuoteLineTriggerHandler {

    public static CPQQuoteLineTriggerHandler getInstance() {
        return (CPQQuoteLineTriggerHandler)ServiceLocator.getInstance(CPQQuoteLineTriggerHandler.class);
    }

    public void beforeInsert(final List<SBQQ__QuoteLine__c> quoteLines) {
        final List<Id> productIds = new List<Id>();
        final List<Id> renewalSubscriptionIds = new List<Id>();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if(quoteLine.SBQQ__Product__c != null) {
                productIds.add(quoteLine.SBQQ__Product__c);
            }
            if(quoteLine.SBQQ__RenewedSubscription__c != null) {
                renewalSubscriptionIds.add(quoteLine.SBQQ__RenewedSubscription__c);
            }
        }
        final Map<Id, Product2> productMap = new Map<Id, Product2>([
                SELECT Id, PG1__c, PG2__c, PG3__c
                FROM Product2
                WHERE Id IN :productIds
        ]);
        final Map<Id, SBQQ__Subscription__c> subscriptionMap = new Map<Id, SBQQ__Subscription__c>([
                SELECT Id, SBQQ__Discount__c, SBQQ__AdditionalDiscountAmount__c
                FROM SBQQ__Subscription__c
                WHERE Id IN :renewalSubscriptionIds
        ]);
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            quoteLine.IsChangedOrAdded__c = true;
            quoteLine.PG1__c = productMap.get(quoteLine.SBQQ__Product__c)?.PG1__c;
            quoteLine.PG2__c = productMap.get(quoteLine.SBQQ__Product__c)?.PG2__c;
            quoteLine.PG3__c = productMap.get(quoteLine.SBQQ__Product__c)?.PG3__c;
            if(quoteLine.SBQQ__RenewedSubscription__c != null) {
                final SBQQ__Subscription__c subscription = subscriptionMap.get(quoteLine.SBQQ__RenewedSubscription__c);
                if(subscription != null) {
                    quoteLine.DisableRenewalDiscountUpdate__c = true;
                    quoteLine.SBQQ__Discount__c = subscription.SBQQ__Discount__c;
                    quoteLine.SBQQ__AdditionalDiscountAmount__c = subscription.SBQQ__AdditionalDiscountAmount__c;
                }
            }
        }
    }

    public void beforeUpdate(final Map<Id, SBQQ__QuoteLine__c> oldMap, final Map<Id, SBQQ__QuoteLine__c> newMap) {
        final List<SBQQ__QuoteLine__c> quoteLines = newMap.values();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            final SBQQ__QuoteLine__c oldQuoteLine = oldMap.get(quoteLine.Id);
            if (quoteLine.SBQQ__EffectiveQuantity__c != oldQuoteLine.SBQQ__EffectiveQuantity__c) {
                quoteLine.IsChangedOrAdded__c = true;
            }
        }
    }
}
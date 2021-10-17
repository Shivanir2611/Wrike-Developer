public class CPQSubscriptionQueryService {

    public static CPQSubscriptionQueryService getInstance() {
        return (CPQSubscriptionQueryService)ServiceLocator.getInstance(CPQSubscriptionQueryService.class);
    }

    public List<AggregateResult> findAggregatedSubscriptionsByWrikeAccountId(final Decimal wrikeAccountId) {
        return [
                SELECT SBQQ__Product__r.ProductCode productCode, MAX(SBQQ__Product__r.Name) name,
                       SUM(SBQQ__Quantity__c) quantity, SUM(MRR__c) mrr, SUM(MRRnoNRDiscount__c) renewalMrr
                  FROM SBQQ__Subscription__c
                 WHERE SBQQ__Contract__r.Wrike_Account_ID__c = :wrikeAccountId
                   AND SBQQ__Contract__r.Status = 'Activated'
                   AND SBQQ__Product__r.PG2__c != 'Bundle'
                   AND SBQQ__OrderProduct__r.Bundled__c = false
                   AND SBQQ__SubscriptionStartDate__c <= TODAY
                   AND SBQQ__SubscriptionEndDate__c >= TODAY
              GROUP BY SBQQ__Product__r.ProductCode
              ORDER BY MAX(SBQQ__Product__r.SBQQ__SortOrder__c)
        ];
    }

    public List<SBQQ__Subscription__c> findSubscriptionsByContractId(final Id contractId) {
        return [
                SELECT Id, SBQQ__EndDate__c, SBQQ__Product__r.ProductCode
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c = :contractId
        ];
    }

    public List<SBQQ__Subscription__c> findSubscriptionsByContractIdAndProductCode(final Id contractId,
                                                                                   final String productCode) {
        return [
                SELECT Id, SBQQ__EndDate__c
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c = :contractId
                AND SBQQ__Product__r.ProductCode = :productCode
        ];
    }

    public List<SBQQ__Subscription__c> findBasePlanSubscriptionsByContractId(final Id contractId) {
        return [
                SELECT Id, SBQQ__EndDate__c, SBQQ__Quantity__c, SBQQ__Product__r.ProductCode
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c = :contractId
                AND SBQQ__Product__r.PG2__c = 'Base Plans'
        ];
    }
}
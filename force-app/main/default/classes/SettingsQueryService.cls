public class SettingsQueryService {

    public static SettingsQueryService getInstance() {
        return (SettingsQueryService)ServiceLocator.getInstance(SettingsQueryService.class);
    }

    public List<QuoteApprovalDiscount__mdt> findQuoteApprvalDiscountByName(String productServiceType) {
        return [
            Select Id, DeveloperName, Level0__c, Level1__c, Level2__c, Level3__c, Level4__c
            FROM QuoteApprovalDiscount__mdt
            WHERE DeveloperName = :productServiceType
        ];
    }
}
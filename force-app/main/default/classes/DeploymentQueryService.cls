public class DeploymentQueryService {

    public static DeploymentQueryService getInstance() {
        return (DeploymentQueryService)ServiceLocator.getInstance(DeploymentQueryService.class);
    }

    public List<Deployment__c> listByWrikeAccountIds(final List<Decimal> wrikeAccountIds) {
        return [
            SELECT Id, Wrike_Account_ID__c, Subscription__c
            FROM Deployment__c
            WHERE Wrike_Account_ID__c IN :wrikeAccountIds
            ORDER BY Wrike_Account_ID__c ASC, CreatedDate ASC
        ];
    }

    public List<Deployment__c> listByIds(final List<Id> ids) {
        return [
                SELECT Id, Wrike_Account_ID__c, Subscription__c
                FROM Deployment__c
                WHERE Id IN :ids
        ];
    }

    public List<Deployment__c> listWithOpportunityByIds(final List<Id> ids) {
        return [
                SELECT Id, Account__c, Opportunity__r.Wrike_Account_Id__c
                FROM Deployment__c
                WHERE Id IN :ids
        ];
    }
}
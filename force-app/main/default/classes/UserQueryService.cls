public class UserQueryService {

    public static UserQueryService getInstance() {
        return (UserQueryService)ServiceLocator.getInstance(UserQueryService.class);
    }

    public List<User> findEqualsOrGreaterThenApproverLevel(String approverLevel, String opportunityApproverType) {
        return [
            SELECT Id, Name, FirstName, LastName, ApproverLevel__c, OpportunityApproverType__c
            FROM User
            WHERE ApproverLevel__c >= :approverLevel
                AND OpportunityApproverType__c INCLUDES (:opportunityApproverType)
                AND IsActive = true
        ];
    }

    public List<User> findById(String userId) {
        return [
            SELECT Id, Name, FirstName, LastName, ApproverLevel__c, OpportunityApproverType__c, USGeo__c,
                   CPQApproveAllAbove__c
            FROM User
            WHERE Id = :userId
                 AND IsActive = true
        ];
    }

    public List<User> listByIds(List<String> userIds) {
        return [
            SELECT Id, Name, FirstName, LastName
            FROM User
            WHERE Id IN :userIds
        ];
    }

    public List<User> listActiveByIds(final List<String> userIds) {
        return [
            SELECT Id, Name, FirstName, LastName
            FROM User
            WHERE Id IN :userIds
                AND IsActive = true
        ];
    }
}
public class CPQApprovalQueryService {

    public static CPQApprovalQueryService getInstance() {
        return (CPQApprovalQueryService)ServiceLocator.getInstance(CPQApprovalQueryService.class);
    }

    public List<sbaa__Approval__c> findApprovalsByQuoteId(final Id quoteId) {
        return [
                SELECT Id, Name, sbaa__ApprovalChain__c, sbaa__ApprovalChain__r.Name, sbaa__Rule__c, sbaa__Rule__r.Name,
                       sbaa__ApprovalStep__c, sbaa__Status__c, sbaa__CommentsLong__c, sbaa__Approver__r.Name,
                       sbaa__Approver__r.sbaa__User__c, sbaa__Approver__r.sbaa__GroupId__c, sbaa__AssignedTo__c,
                       sbaa__AssignedTo__r.Name, sbaa__ApprovedBy__c, sbaa__ApprovedBy__r.Name, Quote__c,
                       sbaa__Rule__r.ApprovalLine__c
                FROM sbaa__Approval__c
                WHERE Quote__c = :quoteId
        ];
    }

    public List<sbaa__Approval__c> findApprovalsByQuoteIdAndUserIdAndStatus(final Id quoteId,
                                                                            final Id userId,
                                                                            final Set<Id> userGroupIds,
                                                                            final String status) {
        return [
                SELECT Id, sbaa__AssignedTo__c, sbaa__Status__c, sbaa__Rule__r.ApprovalLine__c, sbaa__ApprovalStep__c
                FROM sbaa__Approval__c
                WHERE Quote__c = :quoteId
                AND sbaa__Status__c = :status
                AND (sbaa__Approver__r.sbaa__User__c = :userId
                OR sbaa__Approver__r.sbaa__GroupId__c IN :userGroupIds
                OR sbaa__AssignedTo__c = :userId)
        ];
    }

    public List<sbaa__Approval__c> findApprovalsByQuoteIdApprovalLines(final Id quoteId,
                                                                       final Set<String> approvalLines) {
        return [
                SELECT Id, sbaa__AssignedTo__c, sbaa__Status__c
                FROM sbaa__Approval__c
                WHERE Quote__c = :quoteId
                AND sbaa__Rule__r.ApprovalLine__c IN :approvalLines
        ];
    }

    public List<sbaa__Approval__c> findRequestedApprovalsByUserId(final Id userId, final Set<Id> userGroupIds) {
        return [
                SELECT Id, Name, sbaa__ApprovalChain__c, sbaa__ApprovalChain__r.Name, sbaa__Rule__c, sbaa__Rule__r.Name,
                       sbaa__ApprovalStep__c, sbaa__Status__c, sbaa__CommentsLong__c, sbaa__Approver__r.Name,
                       sbaa__Approver__r.sbaa__User__c, sbaa__Approver__r.sbaa__GroupId__c, sbaa__AssignedTo__c,
                       sbaa__AssignedTo__r.Name, sbaa__ApprovedBy__c, sbaa__ApprovedBy__r.Name, Quote__c
                  FROM sbaa__Approval__c
                 WHERE (sbaa__Approver__r.sbaa__User__c = :userId
                    OR sbaa__Approver__r.sbaa__GroupId__c IN :userGroupIds
                    OR sbaa__AssignedTo__c = :userId)
                   AND sbaa__Status__c = 'Requested'
        ];
    }
}
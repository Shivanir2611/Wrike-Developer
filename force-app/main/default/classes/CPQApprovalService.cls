public class CPQApprovalService {

    public static CPQApprovalService getInstance() {
        return (CPQApprovalService)ServiceLocator.getInstance(CPQApprovalService.class);
    }

    private CPQApprovalQueryService approvalQuerySrv = CPQApprovalQueryService.getInstance();
    private GroupService groupSrv = GroupService.getInstance();
    private UserService userSrv = UserService.getInstance();

    public List<CPQApproval> findApprovalsByQuoteId(final Id quoteId) {
        final List<sbaa__Approval__c> records = approvalQuerySrv.findApprovalsByQuoteId(quoteId);
        final List<CPQApproval> approvals = new List<CPQApproval>();
        for (sbaa__Approval__c record : records) {
            approvals.add(CPQApprovalMapper.mapToApproval(record));
        }
        return approvals;
    }

    public void prepareApprovalsBeforeDecision(final Id quoteId, final Id userId) {
        final Set<Id> userGroupIds = groupSrv.getUserGroupIds(userId);
        final User user = userSrv.findUserById(userId);
        final List<sbaa__Approval__c> records = approvalQuerySrv.findApprovalsByQuoteId(quoteId);
        final List<sbaa__Approval__c> recordsToUpdate = new List<sbaa__Approval__c>();
        final Map<String, Decimal> approvalLineMaxStepMap = new Map<String, Decimal>();
        if (user.CPQApproveAllAbove__c) {
            for (sbaa__Approval__c record : records) {
                if (isUserRecord(record, userId, userGroupIds)
                        && record.sbaa__ApprovalStep__c > 1
                        && record.sbaa__Rule__r != null
                        && record.sbaa__Rule__r.ApprovalLine__c != null) {
                    final String approvalLine = record.sbaa__Rule__r.ApprovalLine__c;
                    if (!approvalLineMaxStepMap.containsKey(approvalLine)
                            || approvalLineMaxStepMap.get(approvalLine) < record.sbaa__ApprovalStep__c) {
                        approvalLineMaxStepMap.put(approvalLine, record.sbaa__ApprovalStep__c);
                    }
                }
            }
        }
        for (sbaa__Approval__c record : records) {
            if (isUserRecord(record, userId, userGroupIds)
                    && ('Assigned'.equals(record.sbaa__Status__c)
                            || record.sbaa__AssignedTo__c != userId)) {
                recordsToUpdate.add(new sbaa__Approval__c(
                        Id = record.Id,
                        sbaa__AssignedTo__c = userId,
                        sbaa__Status__c = 'Requested'
                ));
            } else if (user.CPQApproveAllAbove__c
                    && record.sbaa__Rule__r != null
                    && record.sbaa__Rule__r.ApprovalLine__c != null
                    && !'Approved'.equals(record.sbaa__Status__c)) {
                final String approvalLine = record.sbaa__Rule__r.ApprovalLine__c;
                if (approvalLineMaxStepMap.containsKey(approvalLine)
                        && approvalLineMaxStepMap.get(approvalLine) >= record.sbaa__ApprovalStep__c) {
                    recordsToUpdate.add(new sbaa__Approval__c(
                            Id = record.Id,
                            sbaa__AssignedTo__c = userId,
                            sbaa__Status__c = 'Requested'
                    ));
                }
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    private Boolean isUserRecord(final sbaa__Approval__c record,
                                 final Id userId,
                                 final Set<Id> userGroupIds) {
        return record.sbaa__Approver__r.sbaa__User__c == userId
                || record.sbaa__AssignedTo__c == userId
                || userGroupIds.contains(record.sbaa__Approver__r.sbaa__GroupId__c);
    }

    public List<CPQApproval> findUserApprovals(final Id userId) {
        final Set<Id> userGroupIds = groupSrv.getUserGroupIds(userId);
        final List<sbaa__Approval__c> records = approvalQuerySrv.findRequestedApprovalsByUserId(userId, userGroupIds);
        final List<CPQApproval> approvals = new List<CPQApproval>();
        for (sbaa__Approval__c record : records) {
            approvals.add(CPQApprovalMapper.mapToApproval(record));
        }
        return approvals;
    }

    public Id findFirstRequestedApprovalId(final Id quoteId, final Id userId) {
        final Set<Id> userGroupIds = groupSrv.getUserGroupIds(userId);
        final List<sbaa__Approval__c> records =
                approvalQuerySrv.findApprovalsByQuoteIdAndUserIdAndStatus(quoteId, userId, userGroupIds, 'Requested');
        return records.isEmpty() ? null : records.get(0).Id;
    }
}
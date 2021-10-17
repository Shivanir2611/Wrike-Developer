public class CPQApprovalsTableController {

    private final static GroupService groupSrv = GroupService.getInstance();
    private final static CPQApprovalService approvalSrv = CPQApprovalService.getInstance();

    @AuraEnabled
    public static CurrentUserInfo getUserInfo() {
        final Id currentUserId = UserInfo.getUserId();
        final CurrentUserInfo currentUserInfo = new CurrentUserInfo();
        currentUserInfo.userId = currentUserId;
        currentUserInfo.userGroupIds = groupSrv.getUserGroupIds(currentUserId);
        return currentUserInfo;
    }

    @AuraEnabled
    public static List<CPQApproval> findQuoteApprovals(final Id quoteId) {
        final List<CPQApproval> approvals = approvalSrv.findApprovalsByQuoteId(quoteId);
        final Set<Id> groupIds = new Set<Id>();
        for (CPQApproval approval : approvals) {
            if (approval.approverGroupId != null) {
                groupIds.add(approval.approverGroupId);
            }
        }
        if (!groupIds.isEmpty()) {
            final Map<Id, List<String>> groupMemberNamesMap = groupSrv.getGroupMemberNames(groupIds);
            for (CPQApproval approval : approvals) {
                if (approval.approverGroupId != null &&
                        groupMemberNamesMap.containsKey(approval.approverGroupId)) {
                    approval.approverGroupMemberNames =
                            String.join(groupMemberNamesMap.get(approval.approverGroupId), ', ');
                }
            }
        }
        return approvals;
    }

    @AuraEnabled
    public static Id prepareApprovals(final Id quoteId) {
        final Id userId = UserInfo.getUserId();
        approvalSrv.prepareApprovalsBeforeDecision(quoteId, UserInfo.getUserId());
        return approvalSrv.findFirstRequestedApprovalId(quoteId, userId);
    }

    class CurrentUserInfo {
        @AuraEnabled
        public Id userId {get; set;}
        @AuraEnabled
        public Set<Id> userGroupIds {get; set;}
    }
}
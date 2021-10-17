public class CPQApprovalMapper {

    public static CPQApproval mapToApproval(final sbaa__Approval__c record) {
        final CPQApproval approval = new CPQApproval();
        approval.id = record.Id;
        approval.name = record.Name;
        approval.chainId = record.sbaa__ApprovalChain__c;
        if (record.sbaa__ApprovalChain__r != null) {
            approval.chainName = record.sbaa__ApprovalChain__r.Name;
        }
        approval.ruleId = record.sbaa__Rule__c;
        if (record.sbaa__Rule__r != null) {
            approval.ruleName =  record.sbaa__Rule__r.Name;
        }
        approval.step = record.sbaa__ApprovalStep__c;
        approval.status = record.sbaa__Status__c;
        approval.comments = record.sbaa__CommentsLong__c;
        approval.quoteId = record.Quote__c;
        approval.approverUserId = record.sbaa__Approver__r.sbaa__User__c;
        approval.approverGroupId = record.sbaa__Approver__r.sbaa__GroupId__c;
        approval.approverName = record.sbaa__Approver__r.Name;
        approval.assignedToId = record.sbaa__AssignedTo__c;
        if (record.sbaa__AssignedTo__r != null) {
            approval.assignedToName = record.sbaa__AssignedTo__r.Name;
        }
        approval.approvedById = record.sbaa__ApprovedBy__c;
        if (record.sbaa__ApprovedBy__r != null) {
            approval.approvedByName = record.sbaa__ApprovedBy__r.Name;
        }

        return approval;
    }
}
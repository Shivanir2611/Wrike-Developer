@IsTest
public class CPQApprovalsTableControllerTest {

    @IsTest
    static void testFindQuoteApprovals() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;

        final Group userGroup = new Group(Name = 'Test Group');
        insert userGroup;

        final sbaa__Approver__c approver = new sbaa__Approver__c(sbaa__GroupId__c = userGroup.Id);
        insert approver;

        final sbaa__Approval__c approval = new sbaa__Approval__c(
                Quote__c = quote.Id,
                sbaa__Approver__c = approver.Id,
                sbaa__ApprovalStep__c = 1,
                sbaa__RecordField__c = 'ApprovalStatus__c'
        );
        insert approval;

        final List<CPQApproval> approvals = CPQApprovalsTableController.findQuoteApprovals(quote.Id);
        System.assertEquals(1, approvals.size());
        System.assertEquals(userGroup.Id, approvals.get(0).approverGroupId);
    }
}
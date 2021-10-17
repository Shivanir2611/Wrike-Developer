@IsTest
public class CPQMyApprovalsTableControllerTest {

    @IsTest
    static void testFindMyApprovals() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = account.Id,
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__SalesRep__c = UserInfo.getUserId(),
                SBQQ__Status__c = 'PendingApproval'
        );
        insert quote;
        final sbaa__Approval__c approval = new sbaa__Approval__c(
                Quote__c = quote.Id,
                sbaa__Status__c = 'Requested',
                sbaa__AssignedTo__c = UserInfo.getUserId(),
                sbaa__ApprovalStep__c = 1,
                sbaa__RecordField__c = 'ApprovalStatus__c'
        );
        insert approval;
        final List<CPQMyApprovalsTableController.MyApproval> approvals = CPQMyApprovalsTableController.findMyApprovals();
        System.assert(!approvals.isEmpty());
        System.assertEquals('PendingApproval', approvals.get(0).quoteStatus);
    }

    @IsTest
    static void testGetRequestedApprovalId() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__SalesRep__c = UserInfo.getUserId(),
                SBQQ__Status__c = 'Draft'
        );
        insert quote;
        final sbaa__Approval__c approval = new sbaa__Approval__c(
                Quote__c = quote.Id,
                sbaa__Status__c = 'Requested',
                sbaa__AssignedTo__c = UserInfo.getUserId(),
                sbaa__ApprovalStep__c = 1,
                sbaa__RecordField__c = 'ApprovalStatus__c'
        );
        insert approval;
        final Id approvalId = CPQMyApprovalsTableController.getRequestedApprovalId(quote.Id);
        System.assertEquals(approval.Id, approvalId);
    }
}
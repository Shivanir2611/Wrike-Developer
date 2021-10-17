@IsTest
public class ApprovalTriggerHandlerTest {
    private static final String QuoteApproverEmail = 'quote.approver@team.wrike.com';

    @TestSetup
    static void setup() {
        TestUtils.createUser('Quote Approver', QuoteApproverEmail, 'System Administrator');
    }

    @IsTest
    static void testApprovalInsert() {
        final Id quoteId = createNewQuote();
        final sbaa__Approver__c approver = new sbaa__Approver__c(
            sbaa__User__c = findApproverUserId()
        );
        insert approver;

        final sbaa__Approval__c approval = new sbaa__Approval__c(
            Quote__c = quoteId,
            sbaa__RecordField__c = 'Quote__c',
            sbaa__Status__c = 'Requested',
            sbaa__Approver__c = approver.Id,
            sbaa__ApprovalStep__c = 1
        );
        insert approval;
    }

    @IsTest
    static void testApprovalUpdate() {
        final Id quoteId = createNewQuote();
        final sbaa__Approver__c approver = new sbaa__Approver__c(
            sbaa__User__c = findApproverUserId()
        );
        insert approver;

        final sbaa__Approval__c approval = new sbaa__Approval__c(
            Quote__c = quoteId,
            sbaa__RecordField__c = 'Quote__c',
            sbaa__Status__c = 'Assigned',
            sbaa__Approver__c = approver.Id,
            sbaa__ApprovalStep__c = 1
        );
        insert approval;
        approval.sbaa__Status__c = 'Requested';
        update approval;
    }

    private static Id findApproverUserId() {
       return [
           SELECT Id
           FROM User
           WHERE Email = :QuoteApproverEmail
       ].Id;
    }

    private static Id createNewQuote() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;

        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opportunity.Id,
            WrikeAccountId__c = 123,
            SBQQ__Primary__c = true
        );
        insert quote;
        return quote.Id;
    }
}
public class CPQCitrixOrderProcessingController {

    private final static AccountQueryService accountQuerySrv = AccountQueryService.getInstance();
    private final static CPQQuoteCreationService quoteCreationSrv = CPQQuoteCreationService.getInstance();

    @AuraEnabled
    public static Id createOpportunityAndQuote(final Id accountId,
                                               final String orderType) {
        final Account account = accountQuerySrv.findAccountById(accountId);
        final Date today = DateUtils.getPacificLocalDate();
        final Opportunity opportunity = new Opportunity(
                AccountId = accountId,
                Name = 'CTRX - ' + account.Name + ' - ' + DateUtils.format(today, 'yyyy/MM/dd'),
                CitrixReplica__c = true,
                CloseDate = today,
                StageName = 'Closed Won - Pending',
                Type = 'New Business',
                Lost_Reason_Detail__c = 'Citrix Order Form Replica',
                Reasons_Lost__c = 'Other',
                Competitor_Lost_To__c = 'Nothing',
                Other_Competitors_Won_Lost_To__c = 'Nothing',
                Other_Won_Lost_Reasons__c = 'Citrix Replica',
                RecordTypeId = SchemaUtils.getRecordTypeIdByName(Opportunity.getSObjectType(), 'Fast Track')
        );
        insert opportunity;
        final Id quoteId = quoteCreationSrv.createdNewSubscriptionQuote(opportunity.Id, 'New Subscription', null, '0');
        update new SBQQ__Quote__c(
                Id = quoteId,
                Governing_Terms__c = orderType,
                IgnoreQuantityValidation__c = true,
                Automatic_Renewal__c = orderType == 'CTRX-NotForResell-Replica'
                                       ? 'Yes'
                                       : 'No',
                ApprovalRequired__c = false
        );
        return quoteId;
    }
}
public class CPQQuotePartnerSelectionController {

    private final static AccountQueryService accountQuerySrv = AccountQueryService.getInstance();
    private final static CPQQuoteService quoteSrv = CPQQuoteService.getInstance();
    private final static OpportunityQueryService opportunityQuerySrv = OpportunityQueryService.getInstance();
    private final static BillToShipToQueryService billToShipToQuerySrv = BillToShipToQueryService.getInstance();

    @AuraEnabled
    public static List<LookupInputSearchResultItem> searchForPartnerAccounts(final String searchText) {
        final String filter = '%' + searchText + '%';
        final Id partnerRecordTypeId = SchemaUtils.getRecordTypeIdByName(Account.getSObjectType(), 'Partner');
        final List<Account> accounts = [
                SELECT Id, Name
                FROM Account
                WHERE Name LIKE :filter
                AND RecordTypeId = :partnerRecordTypeId
        ];
        final List<LookupInputSearchResultItem> resultItems = new List<LookupInputSearchResultItem>();
        for (Account account : accounts) {
            resultItems.add(new LookupInputSearchResultItem(
                    account.Id,
                    'standard:account',
                    account.Name,
                    account.Name
            ));
        }
        return resultItems;
    }

    @AuraEnabled
    public static void recalculateQuote(final Id quoteId) {
        final CPQApi cpqApi = CPQApi.getInstance();
        cpqApi.save(cpqApi.calculate(cpqApi.readQuote(quoteId)));
    }

    @AuraEnabled
    public static String updateQuotePartnerAccount(final Id quoteId, final Id partnerAccountId) {
        final Account partnerAccount = accountQuerySrv.findResellerAccountById(partnerAccountId);
        if (String.isBlank(partnerAccount.AgreementType__c)
                || String.isBlank(partnerAccount.GoverningTerms__c)
                || partnerAccount.GoverningTermsDate__c == null
                || String.isBlank(partnerAccount.PaymentTerms__c)
                || partnerAccount.OnetimeFeesCommission__c == null
                || partnerAccount.NewSubscriptionCommission__c == null
                        && partnerAccount.RenewalSubscriptionCommission__c == null) {
            return 'One or more fields in the "Partner Terms" section on the partner account is not filled in. ' +
                    'Please ensure each field is filled in there to add a partner to the Quote.';
        }
        final QS_Bill_To_Ship_To__c billTo = billToShipToQuerySrv.findLastContactByAccountId(partnerAccountId, true, false);
        final QS_Bill_To_Ship_To__c shipTo = billToShipToQuerySrv.findLastContactByAccountId(partnerAccountId, false, true);
        if (billTo == null || shipTo == null) {
            return 'Bill To/Ship To contacts on the partner account are not created.';
        }
        final SBQQ__Quote__c quote = [
                SELECT Id, QuoteType__c, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.RecordTypeId
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
        quoteSrv.setQuoteFieldsFromResellerAccount(quote, partnerAccount);
        update quote;
        final Boolean migration = quote.SBQQ__Opportunity2__r.RecordTypeId ==
                SchemaUtils.getRecordTypeIdByName(Opportunity.getSObjectType(), 'CPQ Migration');
        quoteSrv.updateQuoteLinesPartnerCommission(
                quoteId,
                migration,
                quote.SubscriptionCommission__c,
                quote.OnetimeFeesCommission__c
        );
        final List<Partner__c> opportunityPartners =
                opportunityQuerySrv.findOpportunityResellerPartners(quote.SBQQ__Opportunity2__c);
        final List<Partner__c> opportunityPartnersToDelete = new List<Partner__c>();
        Boolean hasCurrentPartner = false;
        for (Partner__c partner : opportunityPartners) {
            if (partner.Partner__c != partnerAccountId) {
                opportunityPartnersToDelete.add(new Partner__c(Id = partner.Id));
            } else {
                hasCurrentPartner = true;
            }
        }
        if (!opportunityPartnersToDelete.isEmpty()) {
            delete opportunityPartnersToDelete;
        }
        if (!hasCurrentPartner) {
            insert new Partner__c(
                    Opportunity__c = quote.SBQQ__Opportunity2__c,
                    Partner__c = partnerAccountId,
                    Engagement_Level__c = partnerAccount.AgreementType__c
            );
        }
        return null;
    }
}
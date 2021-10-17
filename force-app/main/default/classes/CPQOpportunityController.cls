public class CPQOpportunityController {

    private final static ContractQueryService contractQuerySrv = ContractQueryService.getInstance();
    private final static CPQQuoteCreationService cpqQuoteCreationSrv = CPQQuoteCreationService.getInstance();

    @AuraEnabled
    public static CPQOpportunityData queryOpportunityData(final Id opportunityId) {
        final List<Quote__c> primaryZuoraQuotes = [
            SELECT Id, Name, Status__c
            FROM Quote__c
            WHERE Opportunity__c = :opportunityId
              AND Primary__c = true
              AND Status__c NOT IN ('DRAFT', 'CANCEL')
        ];
        final Opportunity opportunity = [
                SELECT Id,
                       Type,
                       SBQQ__RenewedContract__r.Id,
                       SBQQ__RenewedContract__r.ContractNumber,
                       SBQQ__RenewedContract__r.Wrike_Account_ID__c,
                       SBQQ__RenewedContract__r.StartDate,
                       SBQQ__RenewedContract__r.EndDate,
                       (SELECT Id FROM Orders LIMIT 1)
                FROM Opportunity
                WHERE Id = :opportunityId
        ];
        final CPQOpportunityData opportunityData = new CPQOpportunityData();
        opportunityData.opportunityType = opportunity.Type;
        opportunityData.renewedContract = opportunity.SBQQ__RenewedContract__r;
        opportunityData.orderCreated = opportunity.Orders != null && !opportunity.Orders.isEmpty();
        if(!primaryZuoraQuotes.isEmpty()) {
            opportunityData.existingZuoraQuoteId = primaryZuoraQuotes[0].Id;
            opportunityData.existingZuoraQuoteName = primaryZuoraQuotes[0].Name;
            opportunityData.sentZuoraQuote = (primaryZuoraQuotes[0].Status__c == WrikeQuote.Status.SENT.name());
        }
        return opportunityData;
    }

    @AuraEnabled
    public static List<Map<String, String>> getNumberOfTeamsOptions() {
        final List<Map<String, String>> options = new List<Map<String, String>> {
            new Map<String, String> {
                'value' => '',
                'label' => ''
            }
        };
        final List<PicklistEntry> picklistValues = SBQQ__Quote__c.NumberOfTeams__c.getDescribe().getPicklistValues();
        for(PicklistEntry value : picklistValues) {
            options.add(new Map<String, String> {
                'value' => value.getValue(),
                'label' => value.getLabel()
            });
        }
        return options;
    }

    @AuraEnabled
    public static CPQOpportunityData cancelZuoraQuote(final Id opportunityId, final Id zuoraQuoteId) {
        QuoteService.getInstance().cancelQuote(zuoraQuoteId);
        OpportunityProductService.getInstance().deleteOpportunityLineItems(opportunityId);
        return queryOpportunityData(opportunityId);
    }

    @AuraEnabled
    public static List<Contract> listAccountContracts(final Id opportunityId) {
        final Id cpqRecordTypeId = SchemaUtils.getRecordTypeIdByName(Contract.getSObjectType(), 'CPQ Contracts');
        return [
            SELECT Id, ContractNumber, Wrike_Account_ID__c, StartDate, EndDate
            FROM Contract
            WHERE AccountId IN (
                    SELECT AccountId
                    FROM Opportunity
                    WHERE Id = :opportunityId
              )
              AND Status = 'Activated'
              AND Wrike_Account_ID__c > 0
              AND RecordTypeId = :cpqRecordTypeId
        ];
    }

    @AuraEnabled
    public static Id createdNewSubscriptionQuote(final Id opportunityId,
                                                 final String quoteType,
                                                 final String quoteSubType,
                                                 final String numberOfTeams) {
        return cpqQuoteCreationSrv.createdNewSubscriptionQuote(
                opportunityId,
                quoteType,
                quoteSubType,
                numberOfTeams
        );
    }

    @AuraEnabled
    public static Date findAmendmentStartDate(final Id contractId) {
        return cpqQuoteCreationSrv.findAmendmentStartDate(contractId);
    }

    @AuraEnabled
    public static CPQQuoteCreationService.CPQQuoteCreationResponse createAmendmentQuote(final Id opportunityId,
                                                                                        final Id contractId,
                                                                                        final String quoteType,
                                                                                        final String quoteSubType,
                                                                                        final String numberOfTeams) {
        return cpqQuoteCreationSrv.createAmendmentQuote(
                opportunityId,
                contractId,
                quoteType,
                quoteSubType,
                numberOfTeams
        );
    }

    @AuraEnabled
    public static Id createRenewalQuote(final Id opportunityId,
                                        final String numberOfTeams,
                                        final Id selectedContractId) {
        return cpqQuoteCreationSrv.createRenewalQuote(
                opportunityId,
                numberOfTeams,
                selectedContractId
        );
    }

    public class CPQOpportunityData {
        @AuraEnabled
        public String opportunityType {get; set;}
        @AuraEnabled
        public Contract renewedContract {get; set;}
        @AuraEnabled
        public Boolean orderCreated {get; set;}
        @AuraEnabled
        public Boolean sentZuoraQuote {get; set;}
        @AuraEnabled
        public Id existingZuoraQuoteId {get; set;}
        @AuraEnabled
        public String existingZuoraQuoteName {get; set;}
    }
}
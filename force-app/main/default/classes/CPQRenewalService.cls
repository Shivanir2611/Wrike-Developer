public class CPQRenewalService {

    private final CPQQuoteCreationService cpqQuoteCreationSrv = CPQQuoteCreationService.getInstance();
    private final CPQQuoteService cpqQuoteSrv = CPQQuoteService.getInstance();

    public static CPQRenewalService getInstance() {
        return (CPQRenewalService)ServiceLocator.getInstance(CPQRenewalService.class);
    }

    public CPQRenewalData findRenewalData(final Id contractId) {
        final Contract contract = [
            SELECT Id, ContractNumber, Status, StartDate, EndDate,
                   Account.Id, Account.Name, Auto_Renew__c, Wrike_Account_ID__c,
                   SBQQ__RenewalOpportunity__r.Id,  SBQQ__RenewalOpportunity__r.Name,
                   SBQQ__RenewalOpportunity__r.Probability, SBQQ__RenewalOpportunity__r.IsClosed,
                   AutoRenewalQuote__r.Id, AutoRenewalQuote__r.Name
            FROM Contract
            WHERE Id = :contractId
            ORDER BY Name
        ];
        final List<Opportunity> activeOpportunities = [
            SELECT Id, Name, StageName, Owner.Name
            FROM Opportunity
            WHERE Probability >= 30
              AND Probability < 100
              AND Wrike_Account_Id__c = :contract.Wrike_Account_ID__c
              AND Type = 'Renewal'
              AND CloseDate > :contract.StartDate
            ORDER BY Name
        ];
        final List<Contract> activeContracts = [
                SELECT Id, ContractNumber, StartDate, EndDate, Wrike_Account_ID__c
                FROM Contract
                WHERE Status = 'Activated'
                  AND StartDate <= TODAY
                  AND Wrike_Account_ID__c = :contract.Wrike_Account_ID__c
                  AND EndDate > TODAY
                  AND RecordType.DeveloperName = 'CPQ_Contracts'
                ORDER BY ContractNumber
        ];
        final WrikeData__c wrikeData = findWrikeData(contract.Wrike_Account_ID__c);
        return new CPQRenewalData(
                contract,
                wrikeData.GracePeriodStartDate__c,
                activeOpportunities,
                activeContracts
        );
    }

    public void expireContract(final Id contactId) {
        final CPQRenewalData renewalData = findRenewalData(contactId);
        if(renewalData.getRenewalStatus() == CPQRenewalStatus.Expire.name()) {
            final Decimal wrikeAccountId = renewalData.getContract().Wrike_Account_ID__c;
            final Savepoint savepoint = Database.setSavepoint();
            update new Contract(
                Id = contactId,
                Status = 'Expired'
            );
            final Opportunity renewalOpportunity = renewalData.getContract().SBQQ__RenewalOpportunity__r;
            final Boolean renewedContract = !renewalData.activeContracts.isEmpty();
            if(!renewalOpportunity.IsClosed) {
                final Opportunity oppToUpdate = new Opportunity(
                    Id = renewalOpportunity.Id
                );
                if(renewedContract) {
                    oppToUpdate.StageName = 'Closed Won';
                    oppToUpdate.ForecastCategoryName = 'Closed';
                    oppToUpdate.Probability = 100;
                    oppToUpdate.Competitor_Lost_To__c = 'Nothing';
                } else {
                    oppToUpdate.StageName = 'Closed Lost';
                    oppToUpdate.ForecastCategoryName = 'Omitted';
                    oppToUpdate.Probability = 0;
                    oppToUpdate.Competitor_Lost_To__c = 'Nothing';
                }
                update oppToUpdate;
            }
            final WrikeData__c wrikeData = findWrikeData(wrikeAccountId);
            if(wrikeData.GracePeriodStartDate__c != null) {
                wrikeData.GracePeriodStartDate__c = null;
                final Database.UpsertResult upsertResult = Database.upsert(wrikeData, Schema.WrikeData__c.Wrike_Account_Id__c);
                if(!upsertResult.isSuccess()) {
                    Database.rollback(savepoint);
                }
            }
        }
    }

    public void setGracePeriod(final Id contactId) {
        final CPQRenewalData renewalData = findRenewalData(contactId);
        if(renewalData.getRenewalStatus() == CPQRenewalStatus.GracePeriod.name()) {
            final WrikeData__c wrikeData = findWrikeData(renewalData.getContract().Wrike_Account_ID__c);
            if(wrikeData.GracePeriodStartDate__c == null) {
                wrikeData.GracePeriodStartDate__c = renewalData.getContract().EndDate.addDays(1);
                Database.upsert(wrikeData, Schema.WrikeData__c.Wrike_Account_Id__c);
            }
        }
    }

    public Id createRenewalQuote(final Id contractId) {
        final CPQRenewalData renewalData = findRenewalData(contractId);
        if(renewalData.getRenewalStatus() == CPQRenewalStatus.Renew.name()) {
            final Opportunity opportunity = renewalData.getContract().SBQQ__RenewalOpportunity__r;
            if(opportunity != null) {
                final Id quoteId = cpqQuoteCreationSrv.createAutoRenewalQuote(opportunity.Id, contractId);
                update new Contract(
                        Id = contractId,
                        AutoRenewalQuote__c = quoteId
                );
                final CPQQuote quote = cpqQuoteSrv.findQuoteById(quoteId);
                if(!quote.primary) {
                    cpqQuoteSrv.makePrimary(quote);
                }
                return quoteId;
            }
        }
        return null;
    }

    private WrikeData__c findWrikeData(final Decimal wrikeAccountId) {
        final List<WrikeData__c> wrikeData = [
                SELECT Id, Wrike_Account_Id__c, GracePeriodStartDate__c
                FROM WrikeData__c
                WHERE Wrike_Account_Id__c = :wrikeAccountId
        ];
        return wrikeData.isEmpty()
               ? new WrikeData__c(Wrike_Account_Id__c = wrikeAccountId)
               : wrikeData[0];
    }

    public enum CPQRenewalStatus {
        Expire, GracePeriod, Renew, None
    }

    public class CPQRenewalData {
        private final Contract contract;
        private final Date gracePeriodStartDate;
        private final List<Opportunity> activeOpportunities;
        private final List<Contract> activeContracts;

        public CPQRenewalData(final Contract contract,
                              final Date gracePeriodStartDate,
                              final List<Opportunity> activeOpportunities,
                              final List<Contract> activeContracts) {
            this.gracePeriodStartDate = gracePeriodStartDate;
            this.contract = contract;
            this.activeOpportunities = activeOpportunities;
            this.activeContracts = activeContracts;
        }

        @AuraEnabled
        public Contract getContract() {
            return contract;
        }

        @AuraEnabled
        public Date getGracePeriodStartDate() {
            return gracePeriodStartDate;
        }

        @AuraEnabled
        public List<Opportunity> getActiveOpportunities() {
            return activeOpportunities;
        }

        @AuraEnabled
        public List<Contract> getActiveContracts() {
            return activeContracts;
        }

        @AuraEnabled
        public String getRenewalStatus() {
            if(contract.Status == 'Activated'
                    && contract.EndDate < DateUtils.getPacificLocalDate()) {
                final Opportunity renewalOpp = contract.SBQQ__RenewalOpportunity__r;
                if(!activeContracts.isEmpty()
                        || (renewalOpp != null && renewalOpp.IsClosed && renewalOpp.Probability == 0)
                        || (contract.Auto_Renew__c != 'Yes' && activeOpportunities.isEmpty())) {
                    return CPQRenewalStatus.Expire.name();
                } else if(!activeOpportunities.isEmpty()) {
                    return CPQRenewalStatus.GracePeriod.name();
                } else if(contract.Auto_Renew__c == 'Yes') {
                    return CPQRenewalStatus.Renew.name();
                }
            }
            return CPQRenewalStatus.None.name();
        }
    }
}
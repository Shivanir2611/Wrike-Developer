public class ContractQueryService {

    public static ContractQueryService getInstance() {
        return (ContractQueryService)ServiceLocator.getInstance(ContractQueryService.class);
    }

    public List<Contract> findContractsByWrikeAccountId(final Decimal wrikeAccountId) {
        return [
                SELECT Id, ContractNumber, StartDate, EndDate, CurrencyIsoCode, BillingFrequency__c
                  FROM Contract
                 WHERE Wrike_Account_ID__c = :wrikeAccountId
                   AND Status = 'Activated'
                   AND StartDate <= TODAY
                   AND EndDate >= TODAY
              ORDER BY StartDate
        ];
    }

    public Contract findContractById(final Id contractId) {
        final List<Contract> contracts = [
                SELECT Id, Wrike_Account_ID__c, CurrencyIsoCode, BillingFrequency__c, ResellerAccount__c,
                       ResellerAccount__r.Id, ResellerAccount__r.AgreementType__c, EndDate
                FROM Contract
                WHERE Id = :contractId
        ];
        return contracts.isEmpty() ? null : contracts.get(0);
    }
}
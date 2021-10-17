public class ContractRenewalsController {

    private final static CPQRenewalService cpqRenewalSrv = CPQRenewalService.getInstance();

    @AuraEnabled
    public static List<Contract> listRenewalContracts() {
        return [
            SELECT Id, ContractNumber, StartDate, EndDate, Account.Id, Account.Name,
                   Auto_Renew__c, Wrike_Account_ID__c, LastRenewalCheckDate__c,
                   SBQQ__RenewalOpportunity__r.Id, SBQQ__RenewalOpportunity__r.Name,
                   SBQQ__RenewalOpportunity__r.StageName, SBQQ__RenewalOpportunity__r.Wrike_Data__r.GracePeriodStartDate__c,
                   AutoRenewalQuote__r.Id, AutoRenewalQuote__r.Name, AutoRenewalQuote__r.SBQQ__Status__c
            FROM Contract
            WHERE EndDate < TODAY
              AND Status = 'Activated'
              AND StartDate <= TODAY
              AND Wrike_Account_ID__c > 0
              AND RecordType.DeveloperName = 'CPQ_Contracts'
            ORDER BY EndDate, Wrike_Account_ID__c, Contract.AccountId
        ];
    }

    @AuraEnabled
    public static CPQRenewalService.CPQRenewalData findRenewalData(final Id contractId) {
        return cpqRenewalSrv.findRenewalData(contractId);
    }

    @AuraEnabled
    public static void expireContract(final Id contractId) {
        cpqRenewalSrv.expireContract(contractId);
    }

    @AuraEnabled
    public static void keepGracePeriod(final Id contractId) {
        cpqRenewalSrv.setGracePeriod(contractId);
    }

    @AuraEnabled
    public static Id createRenewalQuote(final Id contractId) {
        return cpqRenewalSrv.createRenewalQuote(contractId);
    }
}
@IsTest
public class ContractServiceTest {

    @IsTest
    static void testUpdateContractFromQuote() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__BillingFrequency__c = 'Monthly',
                Automatic_Renewal__c = 'Yes',
                Internal_Notes__c = 'aaa'
        );
        insert quote;
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = new Contract(
                AccountId = account.Id
        );
        insert contract;

        ContractService.getInstance().updateContractFromQuote(contract.Id, quote.Id);

        final Contract updatedContract = findContractById(contract.Id);
        System.assertEquals('Monthly', updatedContract.BillingFrequency__c);
        System.assertEquals('Yes', updatedContract.Auto_Renew__c);
        System.assertEquals('aaa', updatedContract.InternalNotes__c);
    }

    private static Contract findContractById(final Id contractId) {
        return  [
                SELECT Id, BillingFrequency__c, Auto_Renew__c, InternalNotes__c
                FROM Contract
                WHERE Id = :contractId
        ];
    }
}
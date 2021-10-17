@IsTest
public class ContractTriggerTest {

    @IsTest
    static void testUpdateContractFromOrder() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
                QS_Account__c =  account.Id,
                Wrike_Account_ID__c = 123,
                QS_Bill_To__c = true
        );
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = new QS_Bill_To_Ship_To__c(
            QS_Account__c =  account.Id,
            Wrike_Account_ID__c = 123,
            QS_Ship_To__c = true
        );
        insert shipTo;

        final Order order = new Order(
                AccountId = account.Id,
                QS_Bill_To__c = billTo.Id,
                QS_Ship_To__c = shipTo.Id,
                WrikeAccountId__c = 123,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                EndDate =  Date.today().addMonths(12).addDays(-1),
                SBQQ__RenewalTerm__c = 12
        );
        insert order;
        final Contract contract = new Contract(
                Wrike_Account_ID__c = 123,
                AccountId = account.Id,
                StartDate = Date.today().addDays(-1),
                EndDate = Date.today().addMonths(12),
                SBQQ__RenewalTerm__c = 12,
                RecordTypeId = SchemaUtils.getRecordTypeIdByName(Contract.getSObjectType(), 'CPQ Contracts'),
                QS_Bill_To__c = billTo.Id,
                QS_Ship_To__c = shipTo.Id
        );
        insert contract;
        contract.SBQQ__Order__c = order.Id;
        contract.Status = 'Activated';
        update contract;

        final Contract updatedContract = findContractById(contract.Id);
        final Id recordTypeId = SchemaUtils.getRecordTypeIdByName(Contract.getSObjectType(), 'CPQ Contracts');
        System.assertEquals(billTo.Id, updatedContract.QS_Bill_To__c);
        System.assertEquals(shipTo.Id, updatedContract.QS_Ship_To__c);
        System.assertEquals(123, updatedContract.Wrike_Account_ID__c);
        System.assertEquals('Activated', updatedContract.Status);
        System.assertEquals(recordTypeId, updatedContract.RecordTypeId);
        System.assertEquals(true, updatedContract.SBQQ__PreserveBundleStructureUponRenewals__c);
    }

    @IsTest
    static void testDeleteContractWithCPQRecordType() {
        if (!OrganizationService.getInstance().isSandbox()) {
            final Account account = TestDataFactory.createAccount();
            insert account;
            final Contract contract = new Contract(
                    RecordTypeId = SchemaUtils.getRecordTypeIdByName(Contract.getSObjectType(), 'CPQ Contracts'),
                    AccountId = account.Id
            );
            insert contract;
            DatabaseService.Result result = DatabaseService.getInstance().deleteSObject(contract.Id, true);
            System.assert(result.isSuccess() == false);
            System.assert(result.getErrorMessage().contains('CPQ Contract cannot be deleted. Id: ' + contract.Id),
                    result.getErrorMessage());
        }
    }

    private static Contract findContractById(final Id id) {
        return [
                SELECT Id, QS_Bill_To__c, QS_Ship_To__c, Wrike_Account_ID__c, Status, RecordTypeId,
                       SBQQ__PreserveBundleStructureUponRenewals__c
                FROM Contract
                WHERE Id = :id
        ];
    }
}
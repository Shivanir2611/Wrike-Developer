@IsTest
public class CPQRenewalServiceTest {

    @IsTest
    static void testNonExpiredContractStatus() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(
                account.Id,
                Date.today().addDays(1),
                Date.today().addDays(1),
                true
        );
        Test.startTest();
        assertRenewalStatus(contract.Id, CPQRenewalService.CPQRenewalStatus.None);
        Test.stopTest();
    }

    @IsTest
    static void testNonAutoRenewalContractStatus() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                Date.today().addDays(-1),
                false
        );
        Test.startTest();
        assertRenewalStatus(contract.Id, CPQRenewalService.CPQRenewalStatus.Expire);
        Test.stopTest();
    }

    @IsTest
    static void testExpiredContractStatus() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        createContract(
                account.Id,
                Date.today().addDays(-1),
                Date.today().addDays(1),
                true
        );
        final Contract expiredContract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                Date.today().addDays(-1),
                true
        );
        Test.startTest();
        assertRenewalStatus(expiredContract.Id, CPQRenewalService.CPQRenewalStatus.Expire);
        Test.stopTest();
    }

    @IsTest
    static void testContractWithClosedLostRenewalOpportunity() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                Date.today().addDays(-1),
                true
        );
        update new Opportunity(
            Id = contract.SBQQ__RenewalOpportunity__c,
            StageName = 'Closed Lost'
        );
        Test.startTest();
        assertRenewalStatus(contract.Id, CPQRenewalService.CPQRenewalStatus.Expire);
        Test.stopTest();
    }

    @IsTest
    static void testContractWithActiveRenewalOpportunity() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                Date.today().addDays(-1),
                true
        );
        final Opportunity renewalOpportunity = TestDataFactory.createOpportunity(contract.AccountId, 123);
        renewalOpportunity.StageName = 'Working';
        renewalOpportunity.Type = 'Renewal';
        insert renewalOpportunity;
        Test.startTest();
        assertRenewalStatus(contract.Id, CPQRenewalService.CPQRenewalStatus.GracePeriod);
        Test.stopTest();
    }


    @IsTest
    static void testAutoRenewalContractStatus() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                Date.today().addDays(-1),
                true
        );
        Test.startTest();
        assertRenewalStatus(contract.Id, CPQRenewalService.CPQRenewalStatus.Renew);
        Test.stopTest();
    }

    private static Contract createContract(final Id accountId,
                                           final Date startDate,
                                           final Date endDate,
                                           final Boolean autoRenewal) {
        final Opportunity renewalOpportunity = TestDataFactory.createOpportunity(accountId, 123);
        renewalOpportunity.Type = 'Renewal';
        insert renewalOpportunity;
        final Contract contract = TestDataFactory.createCPQContract(accountId, 123);
        contract.Auto_Renew__c = (autoRenewal ? 'Yes' : 'No');
        contract.SBQQ__RenewalOpportunity__c = renewalOpportunity.Id;
        contract.StartDate = startDate;
        contract.EndDate = endDate;
        insert contract;
        contract.Status = 'Activated';
        update contract;
        return contract;
    }

    private static void assertRenewalStatus(final Id contractId,
                                            final CPQRenewalService.CPQRenewalStatus renewalStatus) {
        final CPQRenewalService.CPQRenewalData renewalData = CPQRenewalService.getInstance().findRenewalData(contractId);
        System.assertEquals(renewalStatus.name(), renewalData.getRenewalStatus());
    }

    @IsTest
    static void testExpireChurnedContract() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                Date.today().addDays(-1),
                false
        );
        Database.upsert(new WrikeData__c(
                    Wrike_Account_Id__c = 123,
                    GracePeriodStartDate__c = Date.today()
                ),
                Schema.WrikeData__c.Wrike_Account_Id__c
        );
        Test.startTest();
        CPQRenewalService.getInstance().expireContract(contract.Id);
        System.assertEquals('Expired', findContractStatus(contract.Id));
        System.assertEquals('Closed Lost', findOpportunityStage(contract.SBQQ__RenewalOpportunity__c));
        System.assertEquals(null, findGracePeriodStartDate(123));
        Test.stopTest();
    }

    @IsTest
    static void testExpireRenewedContract() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        createContract(
                account.Id,
                Date.today().addDays(-1),
                Date.today().addYears(1).addDays(-2),
                true
        );
        final Contract contract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                Date.today().addDays(-1),
                false
        );
        Test.startTest();
        CPQRenewalService.getInstance().expireContract(contract.Id);
        System.assertEquals('Expired', findContractStatus(contract.Id));
        System.assertEquals('Closed Won', findOpportunityStage(contract.SBQQ__RenewalOpportunity__c));
        Test.stopTest();
    }

    @IsTest
    static void testSetGracePeriod() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Date contractEndDate = Date.today().addDays(-1);
        final Contract contract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                contractEndDate,
                true
        );
        final Opportunity renewalOpportunity = TestDataFactory.createOpportunity(contract.AccountId, 123);
        renewalOpportunity.StageName = 'Working';
        renewalOpportunity.Type = 'Renewal';
        insert renewalOpportunity;
        Test.startTest();
        CPQRenewalService.getInstance().setGracePeriod(contract.Id);
        System.assertEquals('Activated', findContractStatus(contract.Id));
        System.assertEquals(contractEndDate.addDays(1), findGracePeriodStartDate(123));
        Test.stopTest();
    }

    @IsTest
    static void testCreateRenewalQuote() {
        final CPQQuoteCreationService quoteCreationServiceMock = (CPQQuoteCreationService)MockApi.mock(CPQQuoteCreationService.class);
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = createContract(
                account.Id,
                Date.today().addMonths(-1),
                Date.today().addDays(-1),
                true
        );
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = contract.SBQQ__RenewalOpportunity__c,
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft',
                CurrencyIsoCode = 'USD'
        );
        insert quote;
        MockApi.setup()
                .mockStrict(quoteCreationServiceMock.createAutoRenewalQuote(contract.SBQQ__RenewalOpportunity__c, contract.Id), quote.Id)
                .build();
        Test.startTest();
        CPQRenewalService.getInstance().createRenewalQuote(contract.Id);
        final Contract updatedContract = [
                SELECT Id, Status, AutoRenewalQuote__c
                FROM Contract
                WHERE Id = :contract.Id
        ];
        System.assertEquals('Activated', updatedContract.Status);
        System.assertEquals(quote.Id, updatedContract.AutoRenewalQuote__c);
        Test.stopTest();
    }

    private static Date findGracePeriodStartDate(final Decimal wrikeAccountId) {
        return [
            SELECT GracePeriodStartDate__c
            FROM WrikeData__c
            WHERE Wrike_Account_Id__c = :wrikeAccountId
        ]?.GracePeriodStartDate__c;
    }

    private static String findContractStatus(final Id contractId) {
        return [
                SELECT Status
                FROM Contract
                WHERE Id = :contractId
        ].Status;
    }

    private static String findOpportunityStage(final Id opportunityId) {
        return [
                SELECT StageName
                FROM Opportunity
                WHERE Id = :opportunityId
        ]?.StageName;
    }
}
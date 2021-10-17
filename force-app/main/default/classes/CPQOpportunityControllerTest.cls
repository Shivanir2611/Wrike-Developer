@IsTest
public class CPQOpportunityControllerTest {

    @IsTest
    static void testValidateNoZuoraQuotes() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final CPQOpportunityController.CPQOpportunityData data = CPQOpportunityController.queryOpportunityData(opportunity.Id);
        System.assertEquals('New Business', data.opportunityType);
        System.assertEquals(null, data.renewedContract);
        System.assertEquals(null, data.existingZuoraQuoteId);
        System.assertEquals(null, data.existingZuoraQuoteName);
    }

    @IsTest
    static void testValidateSentZuoraQuote() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final Quote__c zuoraQuote = TestDataFactory.createQuote(opportunity.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        zuoraQuote.Primary__c = true;
        zuoraQuote.Status__c = WrikeQuote.Status.SENT.name();
        insert zuoraQuote;
        final CPQOpportunityController.CPQOpportunityData data = CPQOpportunityController.queryOpportunityData(opportunity.Id);
        System.assertEquals(null, data.renewedContract);
        System.assertEquals(true, data.sentZuoraQuote);
        System.assertEquals(zuoraQuote.Id, data.existingZuoraQuoteId);
        System.assertNotEquals(null, data.existingZuoraQuoteName);
        System.assertEquals(true, data.existingZuoraQuoteName.endsWith(zuoraQuote.Name));
    }

    @IsTest
    static void testCancelZuoraQuote() {
        TestDataFactory.insertSettings();
        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final Quote__c zuoraQuote = TestDataFactory.createQuote(opportunity.Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        zuoraQuote.Primary__c = true;
        zuoraQuote.Status__c = WrikeQuote.Status.PROPOSAL.name();
        insert zuoraQuote;
        final CPQOpportunityController.CPQOpportunityData data = CPQOpportunityController.cancelZuoraQuote(opportunity.Id, zuoraQuote.Id);
        System.assertEquals(null, data.sentZuoraQuote);
        System.assertEquals(null, data.existingZuoraQuoteId);
        System.assertEquals(null, data.existingZuoraQuoteName);
    }

    @IsTest
    static void testListAccountContracts() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final Id contractId = createContract(account.Id, 123);
        final List<Contract> contracts = CPQOpportunityController.listAccountContracts(opportunity.Id);
        System.assertEquals(1, contracts.size());
        System.assertEquals(contractId, contracts[0].Id);
    }

    @IsTest
    static void testGetNumberOfTeamsOptions() {
        System.assertEquals(false, CPQOpportunityController.getNumberOfTeamsOptions().isEmpty());
    }

    @IsTest
    static void testCreatedNewSubscriptionQuote() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final Id quoteId = CPQOpportunityController.createdNewSubscriptionQuote(opportunity.Id, 'New Subscription', 'New Pilot', '5');
        System.assertNotEquals(null, quoteId);
        final SBQQ__Quote__c quote = findQuoteById(quoteId);
        System.assertEquals('Quote', quote.SBQQ__Type__c);
        System.assertEquals('Draft', quote.SBQQ__Status__c);
        System.assertEquals(true, quote.SBQQ__Primary__c);
        System.assertEquals(account.Id, quote.SBQQ__Account__c);
        System.assertEquals(opportunity.Id, quote.SBQQ__Opportunity2__c);
        System.assertEquals('New Subscription', quote.QuoteType__c);
        System.assertEquals('New Pilot', quote.QuoteSubType__c);
        System.assertEquals('5', quote.NumberOfTeams__c);
    }

    @IsTest
    static void testCreateAmendmentQuote() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final Id contractId = createContract(account.Id, 123);
        final Id quoteId = CPQOpportunityController.createAmendmentQuote(
                opportunity.Id,
                contractId,
                'Upsell',
                'Upgrade Subscription',
                '5'
        ).quoteId;
        System.assertNotEquals(null, quoteId);
        final SBQQ__Quote__c quote = findQuoteById(quoteId);
        System.assertEquals('Amendment', quote.SBQQ__Type__c);
        System.assertEquals('Draft', quote.SBQQ__Status__c);
        System.assertEquals(true, quote.SBQQ__Primary__c);
        System.assertEquals(account.Id, quote.SBQQ__Account__c);
        System.assertEquals(opportunity.Id, quote.SBQQ__Opportunity2__c);
        System.assertEquals('Upsell', quote.QuoteType__c);
        System.assertEquals('Upgrade Subscription', quote.QuoteSubType__c);
        System.assertEquals('5', quote.NumberOfTeams__c);
    }

    @IsTest
    static void testCreateRenewalQuote() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        opportunity.Type = 'Renewal';
        insert opportunity;
        final Id contractId = createContract(account.Id, 123);
        update new Opportunity(
            Id = opportunity.Id,
            SBQQ__RenewedContract__c = contractId
        );
        final Id quoteId = CPQOpportunityController.createRenewalQuote(opportunity.Id, '0', null);
        System.assertNotEquals(null, quoteId);
        final SBQQ__Quote__c quote = findQuoteById(quoteId);
        System.assertEquals('Renewal', quote.SBQQ__Type__c);
        System.assertEquals('Draft', quote.SBQQ__Status__c);
        System.assertEquals(true, quote.SBQQ__Primary__c);
        System.assertEquals(account.Id, quote.SBQQ__Account__c);
        System.assertEquals(opportunity.Id, quote.SBQQ__Opportunity2__c);
        System.assertEquals('Renewal', quote.QuoteType__c);
        System.assertEquals(null, quote.QuoteSubType__c);
        System.assertEquals('0', quote.NumberOfTeams__c);
    }

    private static Id createContract(final Id accountId, final Decimal wrikeAccountId) {
        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
                QS_Account__c =  accountId,
                Wrike_Account_ID__c = wrikeAccountId,
                QS_Bill_To__c = true
        );
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = new QS_Bill_To_Ship_To__c(
                QS_Account__c =  accountId,
                Wrike_Account_ID__c = wrikeAccountId,
                QS_Ship_To__c = true
        );
        insert shipTo;
        final Order order = new Order(
                AccountId = accountId,
                QS_Bill_To__c = billTo.Id,
                QS_Ship_To__c = shipTo.Id,
                WrikeAccountId__c = wrikeAccountId,
                Status = 'Draft',
                EffectiveDate = Date.today()
        );
        insert order;
        final Contract contract = new Contract(
                Wrike_Account_ID__c = wrikeAccountId,
                AccountId = accountId,
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
        return contract.Id;
    }

    private static SBQQ__Quote__c findQuoteById(final Id quoteId) {
        return [
            SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c,
                   SBQQ__Type__c, SBQQ__Status__c, SBQQ__Primary__c,
                   QuoteType__c, QuoteSubType__c, NumberOfTeams__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
        ];
    }
}
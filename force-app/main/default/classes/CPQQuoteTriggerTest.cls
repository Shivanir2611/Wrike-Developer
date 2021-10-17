@IsTest
public class CPQQuoteTriggerTest {

    @IsTest
    static void testUpdateQuoteFromContract() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Contract contract = TestDataFactory.createCPQContract(account.Id, 123);
        contract.Auto_Renew__c = 'No';
        contract.BillingFrequency__c = 'Annually';
        contract.PaymentTerms__c = 'Net 30';
        contract.GoverningTerms__c = 'Existing MSA';
        contract.QuoteGoverningLaw__c = 'USA: California';
        contract.TaxExempt__c = true;
        contract.DataCenter__c = 'US';
        insert contract;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        opportunity.SBQQ__RenewedContract__c = contract.Id;
        insert opportunity;

        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Primary__c = true,
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__Type__c = 'Quote',
                Governing_Terms__c = 'Custom Pilot',
                Date_of_Agreement__c = Date.today()
        );
        insert quote;

        final SBQQ__Quote__c updatedQuote = findQuoteById(quote.Id);
        System.assertEquals(contract.QS_Bill_To__c, updatedQuote.QS_Bill_To__c);
        System.assertEquals(contract.QS_Ship_To__c, updatedQuote.QS_Ship_To__c);
        System.assertEquals(123, updatedQuote.WrikeAccountId__c);
        System.assertEquals('No', updatedQuote.Automatic_Renewal__c);
        System.assertEquals('Annually', updatedQuote.SBQQ__BillingFrequency__c);
        System.assertEquals('Net 30', updatedQuote.SBQQ__PaymentTerms__c);
        System.assertEquals('Existing MSA', updatedQuote.Governing_Terms__c);
        System.assertEquals('USA: California', updatedQuote.Governing_Law__c);
        System.assertEquals('US', updatedQuote.DataCenter__c);
        System.assertEquals(true, updatedQuote.Tax_Exempt__c);
        System.assertEquals(false, updatedQuote.SBQQ__LineItemsGrouped__c);
    }

    @IsTest
    static void testUpdateOpportunityWrikeAccountId() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;

        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opportunity.Id
        );
        insert quote;

        quote.SBQQ__Primary__c = true;
        quote.WrikeAccountId__c = 321;
        update quote;

        final Opportunity updatedOpportunity = findOpportunityById(opportunity.Id);
        System.assertEquals(321, updatedOpportunity.Wrike_Account_Id__c);
    }

    @IsTest
    static void testUpdateGroupDates() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__BillingFrequency__c = 'Quarterly',
                SBQQ__Status__c = 'Draft'
        );
        insert quote;

        final Product2 product = new Product2(Name = 'Test Product');
        insert product;

        final SBQQ__QuoteLineGroup__c recurringGroup =  new SBQQ__QuoteLineGroup__c(
                Name = 'Group1',
                SBQQ__StartDate__c = Date.newInstance(2020, 1, 31),
                SBQQ__EndDate__c = Date.newInstance(2021, 1, 30),
                SBQQ__Quote__c = quote.Id,
                OneTime__c = false
        );
        insert recurringGroup;

        final SBQQ__QuoteLineGroup__c oneTimeGroup =  new SBQQ__QuoteLineGroup__c(
                Name = 'Non recurring products',
                SBQQ__Quote__c = quote.Id,
                OneTime__c = true
        );
        insert oneTimeGroup;

        insert new SBQQ__QuoteLine__c(
                SBQQ__StartDate__c = Date.newInstance(2020, 1, 31),
                SBQQ__EndDate__c = Date.newInstance(2021, 1, 30),
                SBQQ__SubscriptionType__c = 'Renewable',
                SBQQ__ProductSubscriptionType__c = 'Renewable',
                SBQQ__NetPrice__c = 500,
                SBQQ__Quantity__c = 1,
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__Group__c = recurringGroup.Id
        );

        quote.SBQQ__LastSavedOn__c = Datetime.now();
        update quote;

        final SBQQ__QuoteLineGroup__c updatedOneTimeGroup = findGroupById(oneTimeGroup.Id);
        System.assertEquals(Date.newInstance(2020, 1, 31), updatedOneTimeGroup.SBQQ__StartDate__c);
        System.assertEquals(Date.newInstance(2020, 1, 31), updatedOneTimeGroup.SBQQ__EndDate__c);
    }

    @IsTest
    static void testUpdateRestructureNewQuotes() {
        final SBQQ__Quote__c newQuote = new SBQQ__Quote__c(
                QuoteType__c = 'Restructure',
                QuoteSubType__c = 'Restart Contract (new contract - create)'
        );
        insert newQuote;

        final SBQQ__Quote__c cancellationQuote1 = new SBQQ__Quote__c(
                QuoteType__c = 'Restructure',
                QuoteSubType__c = 'Restart Contract (old contract - cancel)',
                SubscriptionTotal__c = 5,
                MRR__c = 1
        );
        insert cancellationQuote1;
        cancellationQuote1.RestructureNewQuote__c = newQuote.Id;
        update cancellationQuote1;

        System.assertEquals(5, findQuoteById(newQuote.Id).ProrationCredit__c);
        System.assertEquals(1, findQuoteById(newQuote.Id).MRRCredit__c);

        final SBQQ__Quote__c cancellationQuote2 = new SBQQ__Quote__c(
                QuoteType__c = 'Restructure',
                QuoteSubType__c = 'Restart Contract (old contract - cancel)',
                SubscriptionTotal__c = 10,
                MRR__c = 2
        );
        insert cancellationQuote2;
        cancellationQuote2.RestructureNewQuote__c = newQuote.Id;
        update cancellationQuote2;

        System.assertEquals(15, findQuoteById(newQuote.Id).ProrationCredit__c);
        System.assertEquals(3, findQuoteById(newQuote.Id).MRRCredit__c);
    }

    private static SBQQ__Quote__c findQuoteById(Final Id id) {
        return [
                SELECT Id, QS_Bill_To__c, QS_Ship_To__c, WrikeAccountId__c, Automatic_Renewal__c,
                       SBQQ__BillingFrequency__c, Governing_Terms__c, Governing_Law__c,
                       SBQQ__PaymentTerms__c, SBQQ__LineItemsGrouped__c, Tax_Exempt__c, DataCenter__c,
                       ProrationCredit__c, MRRCredit__c
                  FROM SBQQ__Quote__c
                 WHERE Id = :id
        ];
    }

    private static Opportunity findOpportunityById(Final Id id) {
        return [
                SELECT Id, Wrike_Account_Id__c
                FROM Opportunity
                WHERE Id = :id
        ];
    }

    private static SBQQ__QuoteLineGroup__c findGroupById(Final Id id) {
        return [
                SELECT Id, SBQQ__StartDate__c, SBQQ__EndDate__c
                FROM SBQQ__QuoteLineGroup__c
                WHERE Id = :id
        ];
    }
}
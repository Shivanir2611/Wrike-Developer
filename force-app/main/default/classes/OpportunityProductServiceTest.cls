@IsTest
private class OpportunityProductServiceTest {

    @IsTest
    static void testDeleteOpportunityLineItems() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
        insert pricebook;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        opportunity.Pricebook2Id = pricebook.Id;
        insert opportunity;

        final Product2 product = new Product2(Name = 'Test Product', ZuoraProductId__c = '1');
        insert product;

        final PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(pricebook.Id, product.Id, 11.11);
        insert pricebookEntry;

        final OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
                OpportunityId = opportunity.Id,
                Product2Id = product.Id,
                PricebookEntryId = pricebookEntry.Id,
                Quantity = 5,
                UnitPrice = 11.11
        );
        insert opportunityLineItem;

        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.opportunityId = opportunity.Id;
        OpportunityProductService.getInstance().deleteOpportunityLineItems(wQuote);

        final List<OpportunityLineItem> opportunityLineItems = findOpportunityLineItems(opportunity.Id);

        System.assert(opportunityLineItems.isEmpty());
    }

    @IsTest
    static void testCreateOpportunityLineItems() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
        insert pricebook;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;

        opportunity.Pricebook2Id = pricebook.Id;
        update opportunity;

        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.opportunityId = opportunity.Id;
        wQuote.addItem(WrikeQuoteItem.State.ADDED, createWrikeQuoteProduct(pricebook.Id, 11.11, '1'));
        wQuote.addItem(WrikeQuoteItem.State.REMOVED, createWrikeQuoteProduct(pricebook.Id, 22.22, '2'));

        OpportunityProductService.getInstance().createOpportunityLineItems(wQuote);

        final List<OpportunityLineItem> opportunityLineItems = findOpportunityLineItems(opportunity.Id);

        System.assert(opportunityLineItems.size() == 1);
        System.assertEquals(11.11, opportunityLineItems.get(0).UnitPrice);
        System.assertEquals(55.55, opportunityLineItems.get(0).TotalPrice);
    }
    
    private static Opportunity oppQuoteRelated(Id wQuoteOppRecord){
        Opportunity oppRecord = [
            SELECT Id, Deployments__c
            FROM Opportunity
            WHERE Id =: wQuoteOppRecord
        ];
        return oppRecord;
    }
    
    private static Deployment__c depQuoteRelated(Id oppRecord){
        Deployment__c deploymentRecord = [
            SELECT Id, Deployments__c
            FROM Deployment__c
            WHERE Opportunity__c =: oppRecord
        ];
        return deploymentRecord;
    }

    private static WrikeQuoteProduct createWrikeQuoteProduct(final Id pricebookId,
                                                             final Decimal unitPrice,
                                                             final String zuoraProductId) {
        final Product2 product = new Product2(Name = 'Test Product', ZuoraProductId__c = zuoraProductId);
        insert product;
        final PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(pricebookId, product.Id, unitPrice);
        insert pricebookEntry;
        final WrikeQuoteProduct quoteProduct = new WrikeQuoteProduct();
        quoteProduct.product2Id = pricebookEntry.Product2Id;
        quoteProduct.quantity = 5;
        quoteProduct.chargeType = ZuoraRestQueryService.RECURRING;
        quoteProduct.effectivePricePerUserPerMonth = unitPrice;
        return quoteProduct;
    }

    private static List<OpportunityLineItem> findOpportunityLineItems(final Id opportunityId) {
        return [
                SELECT Id, UnitPrice, TotalPrice
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId
        ];
    }
}
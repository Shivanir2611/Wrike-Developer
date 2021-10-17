public class OpportunityProductService {
    
    public static OpportunityProductService getInstance(){
        return (OpportunityProductService)ServiceLocator.getInstance(OpportunityProductService.class);
    }
    
    public void deleteOpportunityLineItems(final WrikeQuote quote) {
        if (quote != null) {
            delete [
                    SELECT Id
                    FROM OpportunityLineItem
                    WHERE OpportunityId = :quote.opportunityId
            ];
        }
    }

    public void deleteOpportunityLineItems(final Id opportunityId) {
        delete [
                SELECT Id
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId
        ];
    }

    public void createOpportunityLineItems(final WrikeQuote quote) {
        if (quote != null) {
            final Opportunity opportunity = [
                    SELECT Id, Pricebook2Id, CurrencyIsoCode
                    FROM Opportunity
                    WHERE Id =: quote.opportunityId
            ];
            final List<PricebookEntry> pricebookEntries = [
                    SELECT Id, Product2Id
                    FROM PricebookEntry
                    WHERE Pricebook2Id = :opportunity.Pricebook2Id
                    AND CurrencyIsoCode = :opportunity.CurrencyIsoCode
            ];
            final Map<Id, Id> pricebookEntriesMap = new Map<Id, Id>();
            for (PricebookEntry pricebookEntry : pricebookEntries) {
                pricebookEntriesMap.put(pricebookEntry.Product2Id, pricebookEntry.Id);
            }

            final List<OpportunityLineItem> opportunityItemsToCreate = new List<OpportunityLineItem>();
            for (WrikeQuoteItem quoteItem : quote.items) {
                final Id product2Id = quoteItem.product.product2Id;
                if (!quoteItem.getIsRemoved() && pricebookEntriesMap.containsKey(product2Id)) {
                    final OpportunityLineItem opportunityItem = new OpportunityLineItem();
                    opportunityItem.PricebookEntryId = pricebookEntriesMap.get(product2Id);
                    opportunityItem.OpportunityId = quote.opportunityId;
                    opportunityItem.Product2Id = product2Id;

                    final WrikeProduct product = ProductService.getInstance().findProductById(product2Id);
                    opportunityItem.PG1__c = product.pg1;
                    opportunityItem.PG2__c = product.pg2;
                    opportunityItem.PG3__c = product.pg3;

                    opportunityItem.Term__c = quoteItem.product.term;
                    opportunityItem.MRR__c = quoteItem.product.getProductMrr();
                    opportunityItem.WrikeQuoteItem__c = quoteItem.id;
                    opportunityItem.Quantity = quoteItem.product.quantity > 0 ? quoteItem.product.quantity : 1;
                    if (quoteItem.product.getIsRecurrent()) {
                        opportunityItem.UnitPrice = quoteItem.product.getPricePerUnitPerMonth();
                    } else {
                        opportunityItem.UnitPrice = quoteItem.product.effectivePrice;
                    }
                    opportunityItemsToCreate.add(opportunityItem);
                }
            }
            insert opportunityItemsToCreate;
        }
    }
}
public class CPQAddDeploymentsController {

    private final CPQQuoteService quoteSrv = CPQQuoteService.getInstance();
    private final CPQQuoteQueryService quoteQuerySrv = CPQQuoteQueryService.getInstance();
    private final CPQProductService productSrv = CPQProductService.getInstance();
    private final CPQDeploymentSuggestionService deploymentSuggestionSrv = CPQDeploymentSuggestionService.getInstance();

    public PageReference calculateAndAddDeployments() {
        final Id quoteId = ApexPages.currentPage().getParameters().get('quoteId');
        final CPQQuote quote = quoteSrv.findQuoteById(quoteId);
        System.debug('--opp--'+quote);
        if (quote.numberOfTeams != 0 || !quote.legacyBasePlansAllowed) {
            final Map<Id, Integer> quantityByProductId = deploymentSuggestionSrv.getQuantityByProductIdMap(quote);
            final Map<Id, List<Id>> suggestedDeploymentsMap = deploymentSuggestionSrv.findSuggestedDeployments(
                    quantityByProductId,
                    quote
            );
            final List<Id> quoteItemIdsToDelete = new List<Id>();
            final Map<Id, SBQQ__QuoteLine__c> quoteItemsToCreate = new Map<Id, SBQQ__QuoteLine__c>();
            for (CPQQuoteLineItem item : quote.items) {
                if (item.isDeployment()) {
                    quoteItemIdsToDelete.add(item.id);
                }
                if (suggestedDeploymentsMap.containsKey(item.product.Id)) {
                    for (Id suggestedDeploymentId : suggestedDeploymentsMap.get(item.product.Id)) {
                        if (suggestedDeploymentId != null
                                && !quoteItemsToCreate.containsKey(suggestedDeploymentId)) {
                            quoteItemsToCreate.put(suggestedDeploymentId, createDeploymentQuoteLine(
                                    quoteId,
                                    suggestedDeploymentId,
                                    quote.currencyCode
                            ));
                        }
                    }
                }
            }
            if (!quoteItemIdsToDelete.isEmpty()) {
                quoteSrv.deleteQuoteLinesByIds(quoteItemIdsToDelete);
            }
            if (!quoteItemsToCreate.isEmpty()) {
                final Map<Id, Id> productOptionMap = findProductOptionMap(quoteItemsToCreate.keySet(), quote.legacyBasePlansAllowed);
                final Id deploymentsGroupId = quoteQuerySrv.findOneTimeGroupId(quote.id);
                final Id deploymentsBundleId = getDeploymentsBundleId(
                        quoteId,
                        deploymentsGroupId,
                        quote.currencyCode,
                        quote.legacyBasePlansAllowed
                );
                for (SBQQ__QuoteLine__c quoteLine : quoteItemsToCreate.values()) {
                    quoteLine.SBQQ__Group__c = deploymentsGroupId;
                    quoteLine.SBQQ__RequiredBy__c = deploymentsBundleId;
                    quoteLine.SBQQ__Number__c = 2;
                    quoteLine.SBQQ__ProductOption__c = productOptionMap.get(quoteLine.SBQQ__Product__c);
                }
                insert quoteItemsToCreate.values();
            }
        }
        return new PageReference('/apex/SBQQ__sb?id=' + quote.id);
    }

    private PricebookEntry findPricebookEntry(final Id productId, final String currencyCode) {
        return [
                SELECT Id, UnitPrice
                FROM PricebookEntry
                WHERE Pricebook2Id = :Settings__c.getOrgDefaults().StandardPriceBookId__c
                AND Product2Id = :productId
                AND CurrencyIsoCode = :currencyCode
        ];
    }

    private SBQQ__QuoteLine__c createDeploymentQuoteLine(final Id quoteId,
                                                         final Id productId,
                                                         final String currencyCode) {
        final PricebookEntry pricebookEntry = findPricebookEntry(productId, currencyCode);
        return new SBQQ__QuoteLine__c(
                SBQQ__Product__c = productId,
                SBQQ__Quote__c = quoteId,
                SBQQ__PricebookEntryId__c = pricebookEntry.Id,
                SBQQ__ListPrice__c = pricebookEntry.UnitPrice,
                SBQQ__NetPrice__c = pricebookEntry.UnitPrice,
                SBQQ__Quantity__c = 1,
                CurrencyIsoCode = currencyCode
        );
    }

    private Map<Id, Id> findProductOptionMap(final Set<Id> productIds,
                                             final Boolean legacyBasePlans) {
        final String psPackageProductCode = legacyBasePlans
                                            ? CPQProductService.ProfessionalServicesPackageLegacy
                                            : CPQProductService.ProfessionalServicesPackage;
        final List<SBQQ__ProductOption__c> productOptions = [
                SELECT Id, SBQQ__OptionalSKU__c
                FROM SBQQ__ProductOption__c
                WHERE SBQQ__OptionalSKU__c IN :productIds
                AND SBQQ__ConfiguredSKU__r.ProductCode = :psPackageProductCode
        ];
        final Map<Id, Id> productOptionMap = new Map<Id, Id>();
        if (!productOptions.isEmpty()) {
            for (SBQQ__ProductOption__c productOption : productOptions) {
                productOptionMap.put(productOption.SBQQ__OptionalSKU__c, productOption.Id);
            }
        }
        return productOptionMap;
    }

    private Id getDeploymentsBundleId(final Id quoteId,
                                      final Id deploymentsGroupId,
                                      final String currencyCode,
                                      final Boolean legacyBasePlans) {
        final Product2 psPackageProduct = productSrv.findProductByProductCode(legacyBasePlans
                                                                              ? CPQProductService.ProfessionalServicesPackageLegacy
                                                                              : CPQProductService.ProfessionalServicesPackage);
        final Id existingDeploymentsBundleId = quoteQuerySrv.findDeploymentsBundleId(quoteId);
        if (existingDeploymentsBundleId != null) {
            return existingDeploymentsBundleId;
        }
        final SBQQ__QuoteLine__c deploymentsBundle = createDeploymentQuoteLine(
                quoteId,
                psPackageProduct.Id,
                currencyCode
        );
        deploymentsBundle.SBQQ__Group__c = deploymentsGroupId;
        insert deploymentsBundle;
        return deploymentsBundle.Id;
    }
}
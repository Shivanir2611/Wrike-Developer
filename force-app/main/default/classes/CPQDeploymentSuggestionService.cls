public class CPQDeploymentSuggestionService {

    public static CPQDeploymentSuggestionService getInstance() {
        return (CPQDeploymentSuggestionService)ServiceLocator.getInstance(CPQDeploymentSuggestionService.class);
    }

    private CPQQuoteQueryService quoteQuerySrv = CPQQuoteQueryService.getInstance();
    private CPQProductService productSrv = CPQProductService.getInstance();
    private CPQSubscriptionService subscriptionSrv = CPQSubscriptionService.getInstance();

    public List<Product2> getMissingDeployments(final CPQQuote quote) {
        final List<Product2> quoteDeployments = getQuoteDeployments(quote.items);
        final List<Product2> requiredDeployments = getRequiredDeployments(quote);
        final List<Product2> missingDeployments = new List<Product2>();
        if (!requiredDeployments.isEmpty()) {
            for (Product2 requiredDeployment : requiredDeployments) {
                if (!hasRequiredDeployment(quoteDeployments, requiredDeployment, quote.legacyBasePlansAllowed)) {
                    missingDeployments.add(requiredDeployment);
                }
            }
        }
        return missingDeployments;
    }

    private List<Product2> getRequiredDeployments(final CPQQuote quote) {
        final Map<Id, Integer> quantityByProductId = getQuantityByProductIdMap(quote);
        final Map<Id, List<Id>> suggestedDeploymentIdsByProductIdMap = findSuggestedDeployments(
                quantityByProductId,
                quote
        );
        final Set<Id> productIds = new Set<Id>();
        for (Id productId : suggestedDeploymentIdsByProductIdMap.keySet()) {
            productIds.add(productId);
            productIds.addAll(suggestedDeploymentIdsByProductIdMap.get(productId));
        }
        final Map<Id, Product2> productMap = new Map<Id, Product2>(productSrv.findProductsByIds(productIds));
        final List<Product2> requiredDeployments = new List<Product2>();
        for (Id productId : suggestedDeploymentIdsByProductIdMap.keySet()) {
            final Integer thresholdQuantity = getThresholdQuantity(
                    productMap.get(productId).ProductCode,
                    quote.legacyBasePlansAllowed,
                    quote.getIsNewSubscription()
            );
            for (Id suggestedDeploymentId : suggestedDeploymentIdsByProductIdMap.get(productId)) {
                final Product2 suggestedDeployment = productMap.get(suggestedDeploymentId);
                if (quantityByProductId.get(productId) > thresholdQuantity
                        || productSrv.isWrikeAnalyzeStandard(suggestedDeployment.ProductCode)
                                && CPQSettings__c.getOrgDefaults().LegacyDeploymentsApprovalThreshold__c) {
                    requiredDeployments.add(suggestedDeployment);
                }
            }
        }
        return requiredDeployments;
    }

    public Map<Id, List<Id>> findSuggestedDeployments(final Map<Id, Integer> quantityByProductId,
                                                      final CPQQuote quote) {
        final List<Product2> products = productSrv.findProductsByIds(quantityByProductId.keySet());
        final Map<Id, List<Id>> suggestedDeploymentsMap = new Map<Id, List<Id>>();
        final Boolean pro200Allowed = UserService.getInstance().isUsUser(UserInfo.getUserId())
                || Settings__c.getOrgDefaults().EnablePro200Globally__c;
        final Id basePlanChangedContractId = quote.getIsRenewal() || quote.getIsRestructureNewQuote()
                                             ? quote.getChangedContractId()
                                             : null;
        final Boolean allowWrikeAnalyzeStandard = basePlanChangedContractId == null
                || !hasEnterprisePinnacle(products)
                || !subscriptionSrv.checkContractHasCurrentSubscription(basePlanChangedContractId, CPQProductService.WrikeAnalyze);
        for (Product2 product : products) {
            if (productSrv.isRenewable(product.SBQQ__SubscriptionType__c)) {
                final List<Product2> deployments = getDeploymentsForProduct(
                        quote,
                        product,
                        quantityByProductId.get(product.Id),
                        pro200Allowed
                );
                if (!deployments.isEmpty()) {
                    suggestedDeploymentsMap.put(product.Id, new List<Id>());
                    for (Product2 deployment : deployments) {
                        if (deployment != null
                                && (allowWrikeAnalyzeStandard
                                        || !productSrv.isWrikeAnalyzeStandard(deployment.ProductCode))) {
                            suggestedDeploymentsMap.get(product.Id).add(deployment.Id);
                        }
                    }
                }
            }
        }
        return suggestedDeploymentsMap;
    }

    private List<Product2> getDeploymentsForProduct(final CPQQuote quote,
                                                    final Product2 product,
                                                    final Integer quantity,
                                                    final Boolean pro200Allowed) {
        final Boolean seat = productSrv.isSeat(product);
        if (productSrv.isProfessionalLicenses(product.ProductCode) && pro200Allowed) {
            return new List<Product2>{productSrv.findDeploymentForProfessionalLicense(quantity, quote.legacyBasePlansAllowed)};
        }
        if (!quote.legacyBasePlansAllowed && seat && quantity <= 10) {
            final List<Product2> deployments = new List<Product2>();
            if (quantity > 0) {
                deployments.add(productSrv.findProductByProductCode(CPQProductService.SmartStart));
            }
            if (productSrv.isEnterprisePinnacle(product.ProductCode)) {
                deployments.add(productSrv.findProductByProductCode(CPQProductService.WrikeAnalyzeStandard));
            }
            return deployments;
        }
        if (quote.legacyBasePlansAllowed
                && (seat
                        && quote.numberOfTeams == 6
                        || quantity > 200)
                || !quote.legacyBasePlansAllowed
                        && seat
                        && quantity > 250) {
            return new List<Product2>{productSrv.findProductByProductCode(CPQProductService.CustomDeployment)};
        }
        if (seat && quote.legacyBasePlansAllowed && quote.numberOfTeams != 0) {
            return new List<Product2>{productSrv.findDeploymentBySeatsAndNumberOfTeams(quantity, quote.numberOfTeams)};
        }
        return productSrv.findDeploymentBySeatsAndParentProductId(quantity, product.Id);
    }

    public Map<Id, Integer> getQuantityByProductIdMap(final CPQQuote quote) {
        final Id contractId = quote.getChangedContractId();
        final Integer prevBasePlanQuantity = contractId == null
                                             ? 0
                                             : subscriptionSrv.getContractBasePlanQuantity(contractId);
        final Map<Id, Integer> quantityByItemId = new Map<Id, Integer>();
        for (CPQQuoteLineItem item : quote.items) {
            if (item.isTopLevel()) {
                final Boolean newSKUBasePlan = productSrv.isBasePlan(item.product.ProductCode);
                quantityByItemId.put(item.id, item.quantity - (newSKUBasePlan && prevBasePlanQuantity > 0
                                                               ? prevBasePlanQuantity
                                                               : 0));
                for (CPQQuoteLineItem otherItem : quote.items) {
                    final Integer currentQuantity = quantityByItemId.get(item.id);
                    if (item != otherItem
                            && item.product.Id == otherItem.product.Id
                            && item.effectiveStartDate <= otherItem.effectiveEndDate
                            && item.effectiveEndDate >= otherItem.effectiveEndDate) {
                        quantityByItemId.put(item.id, currentQuantity + otherItem.quantity);
                    }
                }
            }
        }
        final Map<Id, Integer> quantityByProductId = new Map<Id, Integer>();
        for (CPQQuoteLineItem item : quote.items) {
            if (item.isTopLevel()) {
                final Integer currentQuantity = quantityByProductId.get(item.product.Id);
                final Integer itemQuantity = quantityByItemId.get(item.id);
                if (currentQuantity == null || currentQuantity < itemQuantity) {
                    quantityByProductId.put(item.product.Id, itemQuantity);
                }
            }
        }
        return quantityByProductId;
    }

    private Boolean hasRequiredDeployment(final List<Product2> quoteDeployments,
                                          final Product2 requiredDeployment,
                                          final Boolean legacyBasePlansAllowed) {
        for (Product2 quoteDeployment : quoteDeployments) {
            if (quoteDeployment.MaxSeats__c >= requiredDeployment.MaxSeats__c) {
                if (quoteDeployment.Id == requiredDeployment.Id) {
                    return true;
                }
                if (!legacyBasePlansAllowed
                        && quoteDeployment.ParentProduct__c == requiredDeployment.ParentProduct__c) {
                    return true;
                }
                if (productSrv.isPinnacleB(requiredDeployment.ProductCode)
                        && productSrv.isPinnacleBCore(quoteDeployment.ProductCode)) {
                    return true;
                }
                if (requiredDeployment.Name.endsWithIgnoreCase('Remote')
                        && (quoteDeployment.Name.endsWithIgnoreCase('Onsite')
                                || quoteDeployment.Name.endsWithIgnoreCase('Remote'))) {
                    return true;
                }
                if (requiredDeployment.Name.split('Team')[0].split('Corporate')[0]
                        == quoteDeployment.Name.split('Team')[0].split('Corporate')[0]) {
                    return true;
                }
            }
        }
        return false;
    }

    private Boolean hasEnterprisePinnacle(final List<Product2> products) {
        for (Product2 product : products) {
            if (productSrv.isEnterprisePinnacle(product.ProductCode)) {
                return true;
            }
        }
        return false;
    }

    private Integer getThresholdQuantity(final String productCode,
                                         final Boolean legacyBasePlansAllowed,
                                         final Boolean newSubscription) {
        if (CPQSettings__c.getOrgDefaults().LegacyDeploymentsApprovalThreshold__c) {
            if (legacyBasePlansAllowed) {
                return 19;
            }
            if (productSrv.isProfessionalLicenses(productCode)) {
                return 25;
            }
            return 10;
        } else {
            if (newSubscription) {
                return 99;
            }
            return 29;
        }
    }

    private List<Product2> getQuoteDeployments(final List<CPQQuoteLineItem> items) {
        final Set<Id> quoteDeploymentIds = new Set<Id>();
        for (CPQQuoteLineItem item : items) {
            if (item.isDeployment()) {
                quoteDeploymentIds.add(item.product.Id);
            }
        }
        return productSrv.findProductsByIds(quoteDeploymentIds);
    }
}
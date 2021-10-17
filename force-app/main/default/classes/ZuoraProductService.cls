public with sharing class ZuoraProductService extends ZuoraProductValidationService{

    public static ZuoraProductService getInstance() {
        return (ZuoraProductService)ServiceLocator.getInstance(ZuoraProductService.class);
    }

    private CacheService cacheSrv = CacheService.getInstance();
    private ZuoraProductCatalogService zuoraProductCatalogSrv = ZuoraProductCatalogService.getInstance();

    public List<ZuoraProductCatalogService.ProductRatePlanWithCharge> filterRatePlansFromProduct(
            final ZuoraProductCatalogService.Product zProduct,
            final Integer newTerm,
            final Integer renewalTerm,
            final ZuoraCurrency quoteCurrency) {
        if (newTerm == null) {
            return zProduct.plans;
        }
        final List<ZuoraProductCatalogService.ProductRatePlanWithCharge> filteredProductRatePlans = new List<ZuoraProductCatalogService.ProductRatePlanWithCharge>();
        for (ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan : zProduct.plans) {
            if(productRatePlan.chargeType == 'Recurring') {
                final Integer recurringPeriodInMonth = getRecurringPeriodInMonth(productRatePlan.billingPeriodName);
                if (recurringPeriodInMonth != null) {
                    final Boolean isPeriodMultipleNewTerm = Math.mod(newTerm, recurringPeriodInMonth) == 0;
                    final Boolean isPeriodMultipleRenewalTerm = Math.mod(renewalTerm, recurringPeriodInMonth) == 0;
                    if (isPeriodMultipleNewTerm
                            && isPeriodMultipleRenewalTerm
                            && (quoteCurrency == ZuoraCurrency.USD || recurringPeriodInMonth == newTerm)
                            && (recurringPeriodInMonth > 1 || newTerm == 1)) {
                        filteredProductRatePlans.add(productRatePlan);
                    }
                }
            } else {
                filteredProductRatePlans.add(productRatePlan);
            }
        }
        return filteredProductRatePlans;
    }

    public String getRatePlanIdWithMaxRequrringPeriod(List<ZuoraProductCatalogService.ProductRatePlanWithCharge> productRatePlans) {
        if (productRatePlans == null || productRatePlans.isEmpty()) {
            return null;
        }

        Integer maxRecurringPeriod = 0;
        ZuoraProductCatalogService.ProductRatePlanWithCharge maxRecurringPeriodRatePlan = null;
        for (ZuoraProductCatalogService.ProductRatePlanWithCharge productRatePlan : productRatePlans) {
            Integer recurringPeriodInMonth = getRecurringPeriodInMonth(productRatePlan.billingPeriodName);
            if (recurringPeriodInMonth != null && recurringPeriodInMonth > maxRecurringPeriod) {
                maxRecurringPeriod = recurringPeriodInMonth;
                maxRecurringPeriodRatePlan = productRatePlan;
            }
        }
        if (maxRecurringPeriodRatePlan == null) {
            return null;
        }
        return maxRecurringPeriodRatePlan.productRatePlanId;
    }

    public Map<String, ZuoraProductCatalogService.Product> getZuoraProductCatalog(final ZuoraCurrency currencyCode) {
        final Map<ZuoraCurrency, Map<String, ZuoraProductCatalogService.Product>> productCache = cacheSrv.getProductCatalog();
        if (productCache == null) {
            productCache = updateZuoraProductCatalog();
        }
        return productCache.containsKey(currencyCode)
               ? productCache.get(currencyCode)
               : new Map<String, ZuoraProductCatalogService.Product>();
    }

    public Decimal findListPricePerUserPerMonth(final String productId,
                                                final String ratePlanId,
                                                final String serviceType,
                                                final ZuoraCurrency currencyCode) {
        final ZuoraProductCatalogService.Product product = findProductByIdOrServiceType(productId, serviceType, currencyCode);
        if(product != null && product.isSeatOrAddon()) {
            for(ZuoraProductCatalogService.ProductRatePlanWithCharge ratePlan : product.plans) {
                if(ratePlan.productRatePlanId == ratePlanId) {
                    final Integer billingPeriodInMonth = getRecurringPeriodInMonth(ratePlan.billingPeriodName);
                    if(billingPeriodInMonth > 0) {
                        final ZuoraObject.ZuoraRatePlanChargeTier tier = ratePlan.tiers[0];
                        if(tier.isPerUnit()) {
                            return tier.price.divide(billingPeriodInMonth, 2);
                        }
                        if(tier.endingUnit > 0) {
                            return (tier.price/tier.endingUnit).divide(billingPeriodInMonth, 2);
                        }
                    }
                }
            }
        }
        return null;
    }

    private  ZuoraProductCatalogService.Product findProductByIdOrServiceType(final String productId,
                                                                             final String serviceType,
                                                                             final ZuoraCurrency currencyCode) {
        final Map<String, ZuoraProductCatalogService.Product> productMap = getZuoraProductCatalog(currencyCode);
        if(productMap.containsKey(productId)) {
            return productMap.get(productId);
        }
        for(ZuoraProductCatalogService.Product product : productMap.values()) {
            if(product.serviceType == serviceType
                    && !product.plans.isEmpty()
                    && !product.plans[0].tiers.isEmpty()) {
                return product;
            }
        }
        return null;
    }

    public Map<ZuoraCurrency, Map<String, ZuoraProductCatalogService.Product>> updateZuoraProductCatalog() {
        final Map<ZuoraCurrency, Map<String, ZuoraProductCatalogService.Product>> productCache = new Map<ZuoraCurrency, Map<String, ZuoraProductCatalogService.Product>>();
        productCache.put(ZuoraCurrency.USD, zuoraProductCatalogSrv.getProductWithRatePlansChargesTiers(ZuoraCurrency.USD));
        productCache.put(ZuoraCurrency.EUR, zuoraProductCatalogSrv.getProductWithRatePlansChargesTiers(ZuoraCurrency.EUR));
        productCache.put(ZuoraCurrency.JPY, zuoraProductCatalogSrv.getProductWithRatePlansChargesTiers(ZuoraCurrency.JPY));
        cacheSrv.putProductCatalog(productCache);
        return productCache;
    }
}
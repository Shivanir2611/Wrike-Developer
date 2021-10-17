public class ZuoraProductCatalogService {

    public static final String LIST_PRICE_PER_BILLING_PERIOD = 'Per Billing Period';

    private final ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();

    public static ZuoraProductCatalogService getInstance() {
        return (ZuoraProductCatalogService)ServiceLocator.getInstance(ZuoraProductCatalogService.class);
    }

    public Map<String, Product> getProductWithRatePlansChargesTiers(final ZuoraCurrency currencyCode) {
        final String now = DateTime.now().format('yyyy-MM-dd');
        final List<ZuoraObject.ZuoraProduct> zProducts = zuoraRestQuerySrv.findProductsByEffectiveEndDate(now);
        final List<ZuoraObject.ZuoraRatePlan> zProductRatePlans = zuoraRestQuerySrv.findProductRatePlansByEffectiveEndDate(now);
        final List<ZuoraObject.ZuoraRatePlanCharge> zProductRatePlanCharges = zuoraRestQuerySrv.findProductsRatePlanCharges();
        final List<ZuoraObject.ZuoraRatePlanChargeTier> zProductRatePlanChargeTiers = zuoraRestQuerySrv.findProductsRatePlanChargeTiersByCurrency(currencyCode);

        final Map<String, Mapable> idToZproduct = createMapBetweenFieldAndZobject(zProducts);
        final Map<String, List<Mapable>> productIdToRatePlans = createMapBetweenFieldAndListZobject(zProductRatePlans);
        final Map<String, List<Mapable>> productRatePlanIdToCharge = createMapBetweenFieldAndListZobject(zProductRatePlanCharges);
        final Map<String, List<Mapable>> productRatePlanChargeIdToTiers = createMapBetweenFieldAndListZobject(zProductRatePlanChargeTiers);

        final Map<String, Set<String>> zuoraEnabledRatePlanMap = SettingsProvider.getZuoraEnabledRatePlanMap();
        final Set<String> zuoraEnabledDeploymentRatePlans = SettingsProvider.getZuoraEnabledDeploymentRatePlans();
        final Map<String, Product> idToProduct = new Map<String, Product>();

        for (String productId : idToZproduct.keySet()) {
            final ZuoraObject.ZuoraProduct product = (ZuoraObject.ZuoraProduct)idToZproduct.get(productId);
            final Product newProduct = new Product();
            newProduct.id = product.id;
            newProduct.name = product.name;
            newProduct.description = product.description;
            newProduct.serviceType = product.serviceType;
            newProduct.plans = new List<ProductRatePlanWithCharge>();
            final List<Mapable> ratePlans = productIdToRatePlans.get(productId);
            if (ratePlans != null) {
                final Set<String> enabledProductRatePlans = zuoraEnabledRatePlanMap.get(newProduct.name.trim().toLowerCase());
                for (Mapable ratePlan : ratePlans) {
                    final ZuoraObject.ZuoraRatePlan castedRatePlan = (ZuoraObject.ZuoraRatePlan)ratePlan;
                    final Boolean enabledProductRatePlan = enabledProductRatePlans == null
                            || enabledProductRatePlans.contains(castedRatePlan.name.trim().toLowerCase());
                    if(enabledProductRatePlan || isEnabledDeploymentRatePlan(zuoraEnabledDeploymentRatePlans, castedRatePlan.name)) {
                        final List<Mapable> ratePlanCharges = productRatePlanIdToCharge.get(castedRatePlan.Id);
                        if (ratePlanCharges != null && ratePlanCharges.size() == 1) { //rate plans without changes or with more then one charge are invalid for now.
                            final ProductRatePlanWithCharge newProductRatePlan = new ProductRatePlanWithCharge(castedRatePlan, (ZuoraObject.ZuoraRatePlanCharge)ratePlanCharges.get(0));
                            if (newProductRatePlan.listPriceBase == LIST_PRICE_PER_BILLING_PERIOD) {
                                newProductRatePlan.tiers = new List<ZuoraObject.ZuoraRatePlanChargeTier>();
                                newProduct.plans.add(newProductRatePlan);
                                final List<Mapable> tiers = productRatePlanChargeIdToTiers.get(newProductRatePlan.productRatePlanChargeId);
                                if (tiers != null && !tiers.isEmpty()) {
                                    for (Mapable tier : tiers) {
                                        newProductRatePlan.tiers.add((ZuoraObject.ZuoraRatePlanChargeTier)tier);
                                    }
                                    newProductRatePlan.tiers.sort();
                                    newProductRatePlan.minQuantity = (Integer)newProductRatePlan.tiers[0].startingUnit;
                                    newProductRatePlan.maxQuantity = (Integer)newProductRatePlan.tiers[newProductRatePlan.tiers.size() - 1].endingUnit;
                                }
                            }
                        }
                    }
                }
                if (newProduct.plans.size() > 0) {
                    newProduct.plans.sort();
                    idToProduct.put(productId, newProduct);
                }
            }
        }
        return idToProduct;
    }

    private static Boolean isEnabledDeploymentRatePlan(final Set<String> enabledRatePlans, final String ratePlan) {
        for(String enabledRatePlan : enabledRatePlans) {
            if(ratePlan.startsWith(enabledRatePlan)) {
                return true;
            }
        }
        return false;
    }

    private static Map<String, Mapable> createMapBetweenFieldAndZobject(List<Mapable> zuoraObjects) {
        Map<String, Mapable> fieldToZobject = new Map<String, Mapable>();
        for (Mapable zuoraObject : zuoraObjects) {
            fieldToZobject.put(zuoraObject.getKeyField(), zuoraObject);
        }
        return fieldToZobject;
    }

    private static Map<String, List<Mapable>> createMapBetweenFieldAndListZobject(List<Mapable> zuoraObjects) {
        Map<String, List<Mapable>> fieldToListZobjects = new Map<String, List<Mapable>>();
        for (Mapable zuoraObject : zuoraObjects) {
            List<Mapable> zObjectsForFieldValue = fieldToListZobjects.get(zuoraObject.getKeyField());
            if (zObjectsForFieldValue == null) {
                zObjectsForFieldValue = new List<Mapable>();
                fieldToListZobjects.put(zuoraObject.getKeyField(), zObjectsForFieldValue);
            }
            zObjectsForFieldValue.add(zuoraObject);
        }
        return fieldToListZobjects;
    }

    public interface Mapable {
        String getKeyField();
    }

    public class Product extends ZuoraObject.ZuoraProduct {
        public List<ProductRatePlanWithCharge> plans {get; set;}

        public Product() {
            this.plans = new List<ProductRatePlanWithCharge>();
        }

        public Boolean isCollaboratorsAddon() {
            return ZuoraProductService.getInstance().isCollaboratorsAddon(this.serviceType);
        }

        public Boolean isSelfStart() {
            return ZuoraProductService.getInstance().isSelfStart(this.name);
        }

        public Boolean isSmartStart() {
            return ZuoraProductService.getInstance().isSmartStart(this.name);
        }

        public Boolean isWrikeIntegrate() {
            return ZuoraProductService.getInstance().isWrikeIntegrate(this.name);
        }

        public Boolean isWrikePerformancePackage() {
            return ZuoraProductService.getInstance().isPerformancePackage(this.serviceType);
        }

        public Boolean isImplementation() {
            return ZuoraProductService.getInstance().isImplementation(this.serviceType);
        }
    }

    public class ProductRatePlanWithCharge extends ZuoraObject.ZuoraRatePlan {
        public String productRatePlanChargeId {get; set;}
        public String chargeType {get; set;}
        public String chargeModel {get; set;}
        public String billingPeriodName {get; set;}
        public Integer minQuantity {get; set;}
        public Integer maxQuantity {get; set;}
        public String listPriceBase {get; set;}
        public List<ZuoraObject.ZuoraRatePlanChargeTier> tiers {get; set;}

        public ProductRatePlanWithCharge() {
            this.tiers = new List<ZuoraObject.ZuoraRatePlanChargeTier>();
        }

        public ProductRatePlanWithCharge(final ZuoraObject.ZuoraRatePlan productRatePlan, final ZuoraObject.ZuoraRatePlanCharge productRatePlanCharge) {
            this.productRatePlanId = productRatePlan.id;
            this.name = productRatePlan.name;
            this.description = productRatePlan.description;
            if (productRatePlanCharge != null) {
                this.productRatePlanChargeId = productRatePlanCharge.id;
                this.chargeType = productRatePlanCharge.chargeType;
                this.chargeModel = productRatePlanCharge.chargeModel;
                this.billingPeriodName = productRatePlanCharge.billingPeriod;
                this.listPriceBase = productRatePlanCharge.listPriceBase;
            }
        }

        public override Integer compareTo(final Object other) {
            if (other == null) {
                return 1;
            }
            if (this == other) {
                return 0;
            }
            if (this.tiers.size() == 0) {
                return -1;
            }
            final ProductRatePlanWithCharge otherRatePlan = (ProductRatePlanWithCharge)other;
            if (otherRatePlan.tiers.size() == 0) {
                return 1;
            }
            return Integer.valueOf(this.tiers.get(0).price - otherRatePlan.tiers.get(0).price);
        }
    }
}
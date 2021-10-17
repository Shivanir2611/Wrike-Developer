public class ZuoraWrikeProductImportService {

    public static ZuoraWrikeProductImportService getInstance() {
        return (ZuoraWrikeProductImportService)ServiceLocator.getInstance(ZuoraWrikeProductImportService.class);
    }

    private final ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();

    public void importProducts() {
        final ProductService productSrv = ProductService.getInstance();
        final Map<String, Product2> existingProductMap = productSrv.getExistingProductMap();
        final Map<String, Map<String, Product2>> existingImplementationProductMap = productSrv.getExistingImplementationProductMap();

        final String now = DateTime.now().format('yyyy-MM-dd');
        final List<ZuoraObject.ZuoraProduct> zuoraProducts = zuoraRestQuerySrv.findAllProductsByEffectiveEndDate(now);

        final List<Product2> productsToInsert = new List<Product2>();
        final List<Product2> productsToUpdate = new List<Product2>();
        final Map<String, WrikePackage__c> wrikePackageByProductIdMap = new Map<String, WrikePackage__c>();

        for (ZuoraObject.ZuoraProduct zuoraProduct : zuoraProducts) {
            final Boolean isImplementation = zuoraProduct.serviceType == 'Implementation';
            if (isImplementation) {
                List<ZuoraObject.ZuoraRatePlan> ratePlans =
                        zuoraRestQuerySrv.findProductRatePlansByEffectiveEndDateAndProductId(now, zuoraProduct.id);
                final Map<String, Product2> ratePlanMap = existingImplementationProductMap.get(zuoraProduct.id);

                for (ZuoraObject.ZuoraRatePlan ratePlan : ratePlans) {
                    final Product2 existingImplementationProduct = ratePlanMap != null ? ratePlanMap.get(ratePlan.id) : null;
                    if (existingImplementationProduct == null) {
                        productsToInsert.add(createProduct(zuoraProduct, ratePlan));
                    } else if (!existingImplementationProduct.Name.contains(ratePlan.name)
                            || existingImplementationProduct.ZuoraProductName__c != zuoraProduct.name
                            || existingImplementationProduct.ZuoraRatePlanName__c != ratePlan.name) {
                        existingImplementationProduct.Name = zuoraProduct.name + ' – ' + ratePlan.name;
                        existingImplementationProduct.ZuoraProductName__c = zuoraProduct.name;
                        existingImplementationProduct.ZuoraRatePlanName__c = ratePlan.name;
                        productsToUpdate.add(existingImplementationProduct);
                    }
                }
            } else {
                if (!existingProductMap.containsKey(zuoraProduct.id)) {
                    final Product2 product = createProduct(zuoraProduct, null);
                    final Boolean isPackage = WrikeProduct.packageServiceTypes.contains(zuoraProduct.serviceType);
                    if (isPackage) {
                        wrikePackageByProductIdMap.put(zuoraProduct.id, new WrikePackage__c(Name = zuoraProduct.name));
                    }
                    productsToInsert.add(product);
                }
            }
        }
        if (!wrikePackageByProductIdMap.isEmpty()) {
            insert wrikePackageByProductIdMap.values();
            for (Product2 product : productsToInsert) {
                final WrikePackage__c wrikePackage = wrikePackageByProductIdMap.get(product.ZuoraProductId__c);
                if (wrikePackage != null) {
                    product.WrikePackage__c = wrikePackage.Id;
                }
            }
        }
        insert productsToInsert;
        update productsToUpdate;
    }

    private Product2 createProduct(final ZuoraObject.ZuoraProduct zuoraProduct, final ZuoraObject.ZuoraRatePlan ratePlan) {
        final Product2 product = new Product2();
        product.Name = zuoraProduct.name;
        product.ZuoraProductId__c = zuoraProduct.id;
        product.ZuoraName__c = zuoraProduct.name;
        product.ZuoraServiceType__c = zuoraProduct.serviceType;
        product.ProductCode = zuoraProduct.sku;
        product.ZuoraProductName__c = zuoraProduct.name;

        if (ratePlan != null) {
            product.ZuoraRatePlanId__c = ratePlan.id;
            product.Name = zuoraProduct.name + ' – ' + ratePlan.name;
            product.ZuoraRatePlanName__c = ratePlan.name;
        } else {
            product.Name = zuoraProduct.name;
        }
        return product;
    }
}
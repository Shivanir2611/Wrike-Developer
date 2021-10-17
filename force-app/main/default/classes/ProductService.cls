public class ProductService {

    public static ProductService getInstance() {
        return (ProductService)ServiceLocator.getInstance(ProductService.class);
    }

    private Map<String, Product2> existingProductMap;
    private Map<String, Map<String, Product2>> existingImplementationProductMap;
    private Map<Id, WrikeProduct> wrikeProductMap;

    public WrikeProduct findProductById(final Id productId) {
        if (this.wrikeProductMap == null) {
            this.wrikeProductMap = getWrikeProductMap();
        }
        final WrikeProduct wrikeProduct = this.wrikeProductMap.get(productId);
        if (wrikeProduct == null) {
            throw new ProductServiceException('WrikeProduct with id ' + productId + ' does not exist.');
        }
        return wrikeProduct;
    }

    public List<WrikeProduct> getProductRequiredDeployments(final WrikeProduct wrikeProduct,
                                                            final WrikeQuote quote) {
        final List<WrikeProduct> requiredDeployments = new List<WrikeProduct>();
        final Integer quantity = quote.getDeltaSeats(wrikeProduct.zuoraServiceType);
        if (wrikeProduct.isSeat()) {
            final WrikeProduct deployment = wrikeProduct.isProfessional(wrikeProduct.zuoraServiceType)
                    ? findDeploymentForProLicense(quantity)
                    : findDeploymentBySeatsAndNumberOfTeams(quantity, quote.numberOfTeams);
            if (deployment != null) {
                requiredDeployments.add(deployment);
            }
        } else {
            final List<WrikeProduct> deployments = findDeploymentBySeatsAndParentProductId(quantity, wrikeProduct.id);
            for (WrikeProduct deployment : deployments) {
                final String requiredProductServiceType = deployment.requiredProductServiceType;
                if (requiredProductServiceType == null
                        || quote.getAddedItemByServiceType(requiredProductServiceType) != null) {
                    requiredDeployments.add(deployment);
                }
            }
            if (wrikeProduct.isWrikePerformancePackage()) {
                for (WrikeProduct packageItem : wrikeProduct.wrikePackage.items) {
                    requiredDeployments.addAll(
                            findDeploymentBySeatsAndParentProductId(quantity, packageItem.id));
                }
            }
        }
        return requiredDeployments;
    }

    public Map<String, Product2> getExistingProductMap() {
        if (existingProductMap == null) {
            fillExistingProductMaps();
        }
        return existingProductMap;
    }

    public Map<String, Map<String, Product2>> getExistingImplementationProductMap() {
        if (existingImplementationProductMap == null) {
            fillExistingProductMaps();
        }
        return existingImplementationProductMap;
    }

    private List<WrikeProduct> findDeploymentBySeatsAndParentProductId(final Integer seats, final Id parentProductId) {
        final List<WrikeProduct> deployments = new List<WrikeProduct>();
        for (WrikeProduct product : wrikeProductMap.values()) {
            if (product.parentProductId == parentProductId
                    && product.maxSeats >= seats
                    && product.minSeats <= seats) {
                deployments.add(product);
            }
        }
        return deployments;
    }

    public WrikeProduct findDeploymentForProLicense(final Integer seats) {
        for (WrikeProduct product : wrikeProductMap.values()) {
            if(product.isDeployment() && product.matchProfessionalLicenseDeployment(seats, false) == 0) {
                return product;
            }
        }
        return null;
    }

    private WrikeProduct findDeploymentBySeatsAndNumberOfTeams(final Integer seats, final Integer numberOfTeams) {
        WrikeProduct deployment = null;
        for (WrikeProduct product : wrikeProductMap.values()) {
            if (product.maxSeats >= seats
                    && product.maxNumberOfTeams >= numberOfTeams
                    && product.name.contains('Remote')
                    && (deployment == null || deployment.maxSeats > product.maxSeats)) {
                deployment = product;
            }
        }
        return deployment;
    }

    private void fillExistingProductMaps() {
        this.existingProductMap = new Map<String, Product2>();
        this.existingImplementationProductMap = new Map<String, Map<String, Product2>>();

        final List<Product2> existingProducts = findAllProducts();

        for (Product2 existingProduct : existingProducts) {
            if (existingProduct.ZuoraServiceType__c == 'Implementation') {
                if (!this.existingImplementationProductMap.containsKey(existingProduct.ZuoraProductId__c)) {
                    this.existingImplementationProductMap.put(existingProduct.ZuoraProductId__c,
                            new Map<String, Product2>());
                }
                this.existingImplementationProductMap.get(existingProduct.ZuoraProductId__c).put(
                        existingProduct.ZuoraRateplanId__c, existingProduct);
            } else {
                this.existingProductMap.put(existingProduct.ZuoraProductId__c, existingProduct);
            }
        }
    }

    private Map<Id, WrikeProduct> getWrikeProductMap() {
        Map<Id, WrikeProduct> wrikeProductMap = CacheService.getInstance().getWrikeProducts();

        if (wrikeProductMap == null) {
            wrikeProductMap = new Map<Id, WrikeProduct>();

            final List<Product2> products = findAllProducts();
            final Map<Id, Id> packageIdProductIdMap = new Map<Id, Id>();

            for (Product2 product : products) {
                if (product.WrikePackage__c != null) {
                    packageIdProductIdMap.put(product.WrikePackage__c, product.Id);
                }

                if (!wrikeProductMap.containsKey(product.Id)) {
                    final WrikeProduct wrikeProduct = mapToWrikeProduct(product);
                    wrikeProductMap.put(wrikeProduct.id, wrikeProduct);
                }
            }

            final List<WrikePackage__c> wrikePackages = findAllWrikePackages();

            for (WrikePackage__c wrikePackage : wrikePackages) {
                final Id packageProductId = packageIdProductIdMap.get(wrikePackage.Id);
                final WrikeProduct packageProduct = wrikeProductMap.get(packageProductId);

                final List<WrikeProduct> items = new List<WrikeProduct>();

                for (WrikePackageItem__c wrikePackageItem : wrikePackage.Wrike_Package_Items__r) {
                    final WrikeProduct item = wrikeProductMap.get(wrikePackageItem.Product__c);
                    items.add(item);
                }

                packageProduct.wrikePackage = new WrikeProduct.WrikePackage(items);
            }
            CacheService.getInstance().putWrikeProducts(wrikeProductMap);
        }
        return wrikeProductMap;
    }

    private WrikeProduct mapToWrikeProduct(final Product2 product) {
        WrikeProduct wrikeProduct = new WrikeProduct();
        wrikeProduct.id = product.Id;
        wrikeProduct.name = product.Name;
        wrikeProduct.zuoraName = product.ZuoraName__c;
        wrikeProduct.zuoraServiceType = product.ZuoraServiceType__c;
        wrikeProduct.enabledLicenses = product.EnabledLicenses__c;
        wrikeProduct.zuoraProductId = product.ZuoraProductId__c;
        wrikeProduct.zuoraRatePlanId = product.ZuoraRateplanId__c;
        wrikeProduct.zuoraCategory = product.ZuoraCategory__c;
        wrikeProduct.sku = product.ProductCode;
        wrikeProduct.maxSeats = product.MaxSeats__c;
        wrikeProduct.minSeats = product.MinSeats__c;
        wrikeProduct.maxNumberOfTeams = product.MaxNumberOfTeams__c;
        wrikeProduct.parentProductId = product.ParentProduct__c;
        wrikeProduct.pg1 = product.PG1__c;
        wrikeProduct.pg2 = product.PG2__c;
        wrikeProduct.pg3 = product.PG3__c;
        wrikeProduct.deploymentExhibit = product.DeploymentExhibit__c;
        wrikeProduct.zuoraProductName = product.ZuoraProductName__c;
        wrikeProduct.zuoraRatePlanName = product.ZuoraRatePlanName__c;
        wrikeProduct.requiredProductServiceType = product.RequiredProductServiceType__c;
        return wrikeProduct;
    }

    @TestVisible
    private List<WrikePackage__c> findAllWrikePackages() {
        return [
                SELECT Id, (SELECT Product__c
                FROM Wrike_Package_Items__r)
                FROM WrikePackage__c
        ];
    }

    @TestVisible
    private List<Product2> findAllProducts() {
        return [
                SELECT Id, ProductCode, Name, IsPackage__c, QuoteMerge__c, WrikePackage__c, ZuoraCategory__c, ZuoraName__c,
                        ZuoraProductId__c, ZuoraRateplanId__c, ZuoraServiceType__c, EnabledLicenses__c, MaxSeats__c, MinSeats__c,
                        MaxNumberOfTeams__c, ParentProduct__c, PG1__c, PG2__c, PG3__c, DeploymentExhibit__c, ZuoraProductName__c,
                        ZuoraRatePlanName__c, RequiredProductServiceType__c
                FROM Product2
                WHERE ZuoraProductId__c != null
        ];
    }

    public class ProductServiceException extends Exception {
    }
}
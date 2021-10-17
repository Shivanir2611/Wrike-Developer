@IsTest
public class ProductServiceTest {

    @IsTest
    static void testFindProductById() {
        final Id addonId = createAndInsertAddon('Wrike Proof', '123');
        final Id packageProductId = createAndInsertPackage('Wrike for Marketers Package', addonId);

        final WrikeProduct packageProduct = ProductService.getInstance().findProductById(packageProductId);

        System.assertEquals(true, packageProduct.isPackage());
        System.assertEquals('Wrike for Marketers Package', packageProduct.name);
        System.assertNotEquals(null, packageProduct.wrikePackage);
        System.assert(!packageProduct.wrikePackage.items.isEmpty());
        final WrikeProduct packageItem = packageProduct.wrikePackage.items.get(0);
        System.assertEquals('Wrike Proof', packageItem.name);
    }

    @IsTest
    static void testGetExistingProductIdMaps() {
        final Id addonId = createAndInsertAddon('Wrike Proof', '123');
        final Id implementationProductId = createAndInsertImplementationProduct('Implementation Product', '456', '789');

        final ProductService productSrv = ProductService.getInstance();

        final Map<String, Product2> existingProductMap = productSrv.getExistingProductMap();
        System.assertNotEquals(null, existingProductMap);
        System.assertEquals(1, existingProductMap.size());
        System.assertEquals(addonId, existingProductMap.get('123').Id);

        final Map<String, Map<String, Product2>> existingImplementationProductMap = productSrv.getExistingImplementationProductMap();
        System.assertNotEquals(null, existingImplementationProductMap);
        System.assertEquals(1, existingImplementationProductMap.size());
        System.assertEquals(implementationProductId, existingImplementationProductMap.get('456').get('789').Id);
    }

    private static Id createAndInsertPackage(final String name, final Id itemId) {
        final WrikePackage__c wrikePackage = new WrikePackage__c();
        wrikePackage.Name = name;
        insert wrikePackage;

        final Product2 packageProduct = new Product2();
        packageProduct.WrikePackage__c = wrikePackage.Id;
        packageProduct.ZuoraProductId__c = '456';
        packageProduct.Name = name;
        insert packageProduct;

        final WrikePackageItem__c wrikePackageItem = new WrikePackageItem__c();
        wrikePackageItem.WrikePackage__c = wrikePackage.Id;
        wrikePackageItem.Product__c = itemId;
        insert wrikePackageItem;

        return packageProduct.Id;
    }

    private static Id createAndInsertAddon(final String name, final String zuoraProductId) {
        final Product2 addon = new Product2();
        addon.Name = name;
        addon.ZuoraServiceType__c = 'Addon';
        addon.ZuoraProductId__c = zuoraProductId;
        insert addon;

        return addon.Id;
    }

    private static Id createAndInsertImplementationProduct(final String name, final String zuoraProductId, final String zuoraRateplanId) {
        final Product2 implementationProduct = new Product2();
        implementationProduct.Name = name;
        implementationProduct.ZuoraServiceType__c = 'Implementation';
        implementationProduct.ZuoraRateplanId__c = zuoraRateplanId;
        implementationProduct.ZuoraProductId__c = zuoraProductId;
        insert implementationProduct;

        return implementationProduct.Id;
    }
}
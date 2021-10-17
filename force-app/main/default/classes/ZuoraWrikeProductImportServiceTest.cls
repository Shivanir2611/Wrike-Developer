@IsTest
public class ZuoraWrikeProductImportServiceTest {

    static {
        final List<ZuoraObject.ZuoraProduct> zuoraProducts = new List<ZuoraObject.ZuoraProduct>();

        final ZuoraObject.ZuoraProduct zuoraProduct1 = new ZuoraObject.ZuoraProduct();
        zuoraProduct1.id = '2c92c0f966a9b7430166ab03d14470fd';
        zuoraProduct1.name = 'Wrike Publish';
        zuoraProduct1.serviceType = 'DamAddon';
        zuoraProducts.add(zuoraProduct1);

        final ZuoraObject.ZuoraProduct zuoraProduct2 = new ZuoraObject.ZuoraProduct();
        zuoraProduct2.id = '2c92c0f9555cf10501555f48eee836c0';
        zuoraProduct2.name = 'Wrike Proof';
        zuoraProduct2.serviceType = 'ProofingAddon';
        zuoraProducts.add(zuoraProduct2);

        final ZuoraObject.ZuoraProduct zuoraProduct3 = new ZuoraObject.ZuoraProduct();
        zuoraProduct3.id = '2c92c0f86905128201690b5d9efe224c';
        zuoraProduct3.name = 'Wrike for Marketers Package';
        zuoraProduct3.serviceType = 'WrikeForMarketersPackage';
        zuoraProducts.add(zuoraProduct3);

        final ZuoraObject.ZuoraProduct zuoraProduct4 = new ZuoraObject.ZuoraProduct();
        zuoraProduct4.id = 'zuoraProduct4';
        zuoraProduct4.name = 'Implementation 123';
        zuoraProduct4.serviceType = 'Implementation';
        zuoraProducts.add(zuoraProduct4);

        final List<ZuoraObject.ZuoraRatePlan> zuoraRatePlans = new List<ZuoraObject.ZuoraRatePlan>();

        final ZuoraObject.ZuoraRatePlan zuoraRatePlan1 = new ZuoraObject.ZuoraRatePlan();
        zuoraRatePlan1.id = 'zuoraRatePlan1';
        zuoraRatePlan1.name = 'zuoraRatePlan1';
        zuoraRatePlan1.productId = 'zuoraProduct4';
        zuoraRatePlans.add(zuoraRatePlan1);

        final ZuoraObject.ZuoraRatePlan zuoraRatePlan2 = new ZuoraObject.ZuoraRatePlan();
        zuoraRatePlan2.id = 'zuoraRatePlan2';
        zuoraRatePlan2.name = 'zuoraRatePlan2';
        zuoraRatePlan2.productId = 'zuoraProduct4';
        zuoraRatePlans.add(zuoraRatePlan2);

        MockApi.setup()
                .mock(MockApi.zuoraRestQueryService().findAllProductsByEffectiveEndDate(null), zuoraProducts)
                .mock(MockApi.zuoraRestQueryService().findProductRatePlansByEffectiveEndDateAndProductId(null, null), zuoraRatePlans)
                .build();
    }

    @IsTest
    static void testImportProducts() {
        final ZuoraWrikeProductImportService zuoraWrikeProductImportSrv = ZuoraWrikeProductImportService.getInstance();
        zuoraWrikeProductImportSrv.importProducts();

        final ProductService productSrv = ProductService.getInstance();
        System.assertEquals(5, productSrv.findAllProducts().size());
        System.assertEquals(1, productSrv.findAllWrikePackages().size());

        ServiceLocator.setInstance(ProductService.class, new ProductService());
        zuoraWrikeProductImportSrv.importProducts();

        System.assertEquals(5, productSrv.findAllProducts().size());
    }
}
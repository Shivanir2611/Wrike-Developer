/**
 * Created by sofia.kanukova on 16/12/2019.
 */

@IsTest
public class ZuoraProductCatalogServiceTest {

    @IsTest
    static void testGetProductWithRatePlansChargesTiers() {
        final ZuoraObject.ZuoraProduct product = new ZuoraObject.ZuoraProduct();
        product.id = 'productId';
        product.name = 'productName';
        final ZuoraObject.ZuoraRatePlan productRatePlan = new ZuoraObject.ZuoraRatePlan();
        productRatePlan.id = 'productRatePlanId';
        productRatePlan.productId = 'productId';
        final ZuoraObject.ZuoraRatePlanCharge productRatePlanCharge = new ZuoraObject.ZuoraRatePlanCharge();
        productRatePlanCharge.id = 'productRatePlanChargeId';
        productRatePlanCharge.listPriceBase = 'Per Billing Period';
        productRatePlanCharge.productRatePlanId = 'productRatePlanId';
        final ZuoraObject.ZuoraRatePlanChargeTier productRatePlanChargeTier = new ZuoraObject.ZuoraRatePlanChargeTier();
        productRatePlanChargeTier.id = 'productRatePlanChargeTierId';
        productRatePlanChargeTier.productRatePlanChargeId = 'productRatePlanChargeId';

        final ZuoraRestQueryService zuoraRestQuerySrv = MockApi.zuoraRestQueryService();
        MockApi.setup()
                .mock(zuoraRestQuerySrv.findProductsByEffectiveEndDate('2020-12-16'),
                new List<ZuoraObject.ZuoraProduct> { product })
                .mock(zuoraRestQuerySrv.findProductRatePlansByEffectiveEndDate('2020-12-16'),
                new List<ZuoraObject.ZuoraRatePlan> { productRatePlan })
                .mock(zuoraRestQuerySrv.findProductsRatePlanCharges(),
                new List<ZuoraObject.ZuoraRatePlanCharge> { productRatePlanCharge })
                .mock(zuoraRestQuerySrv.findProductsRatePlanChargeTiersByCurrency(ZuoraCurrency.USD),
                new List<ZuoraObject.ZuoraRatePlanChargeTier> { productRatePlanChargeTier })
                .build();
        Test.startTest();
        final Map<String, ZuoraProductCatalogService.Product> productMap = ZuoraProductCatalogService.getInstance().getProductWithRatePlansChargesTiers(ZuoraCurrency.USD);
                Test.stopTest();

        System.assert(!productMap.isEmpty());
        System.assertEquals('productName', productMap.get('productId').name);
        System.assertEquals('productRatePlanChargeId', productMap.get('productId').plans.get(0).productRatePlanChargeId);
        System.assertEquals('productRatePlanChargeTierId', productMap.get('productId').plans.get(0).tiers.get(0).id);
    }
}
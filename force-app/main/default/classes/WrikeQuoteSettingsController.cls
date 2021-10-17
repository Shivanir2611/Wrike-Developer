public with sharing class WrikeQuoteSettingsController {

    private ZuoraProductService zuoraProductSrv;
    private ZuoraWrikeProductImportService zuoraWrikeProductImportSrv;
    private CacheService cacheSrv;

    public WrikeQuoteSettingsController() {
        this.zuoraProductSrv = ZuoraProductService.getInstance();
        this.zuoraWrikeProductImportSrv = ZuoraWrikeProductImportService.getInstance();
        this.cacheSrv = CacheService.getInstance();
    }

    public void updateZuoraProductCatalog() {
        zuoraProductSrv.updateZuoraProductCatalog();
    }

    public void importProducts() {
        zuoraWrikeProductImportSrv.importProducts();
    }

    public void resetProductsCache() {
        cacheSrv.removeWrikeProducts();
    }
}
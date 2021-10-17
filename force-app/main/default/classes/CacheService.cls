public with sharing class CacheService {

    public static CacheService getInstance() {
        return (CacheService)ServiceLocator.getInstance(CacheService.class);
    }

    private static final String ZUORA_PRODUCT_CATALOG_KEY = 'ZUORAPRODUCTCATALOG';
    private static final String ZUORA_TOKEN = 'ZUORATOKEN';
    private static final String WRIKE_PRODUCTS_KEY = 'WRIKEPRODUCTS';


    public Map<ZuoraCurrency, Map<String, ZuoraProductCatalogService.Product>> getProductCatalog() {
        return (Map<ZuoraCurrency, Map<String, ZuoraProductCatalogService.Product>>)getByKey(ZUORA_PRODUCT_CATALOG_KEY);
    }

    public void putProductCatalog(final Map<ZuoraCurrency, Map<String, ZuoraProductCatalogService.Product>> idToProductMap) {
        put(ZUORA_PRODUCT_CATALOG_KEY, idToProductMap);
    }

    public String getZuoraToken() {
        return (String)getByKey(ZUORA_TOKEN);
    }

    public void putZuoraToken(final String zuoraToken) {
        put(ZUORA_TOKEN, zuoraToken);
    }

    public Map<Id, WrikeProduct> getWrikeProducts() {
        return (Map<Id, WrikeProduct>)getByKey(WRIKE_PRODUCTS_KEY);
    }

    public void putWrikeProducts(final Map<Id, WrikeProduct> wrikeProductMap) {
        put(WRIKE_PRODUCTS_KEY, wrikeProductMap);
    }

    public void removeWrikeProducts() {
        remove(WRIKE_PRODUCTS_KEY);
    }

    private Object getByKey(String key) {
        return Cache.Org.get(key);
    }

    private void put(String key, Object value) {
        Cache.Org.put(key, value);
    }

    private void remove(String key) {
        Cache.Org.remove(key);
    }
}
public class ProductTriggerHandler {

    public static ProductTriggerHandler getInstance() {
        return (ProductTriggerHandler)ServiceLocator.getInstance(ProductTriggerHandler.class);
    }

    public void beforeDelete(final List<Product2> products) {
        for (Product2 product : products) {
            if (String.isNotBlank(product.ZuoraProductId__c)) {
                product.addError('This record must not be deleted. Id: ' + product.Id);
            }
        }
    }
}
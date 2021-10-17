@IsTest
public class ProductTriggerTest {

    @IsTest
    static void testProductIsNotDeleted() {
        final Product2 product = new Product2(
                Name = 'Test Product',
                ZuoraProductId__c = '123'
        );
        insert product;
        DatabaseService.Result result = DatabaseService.getInstance().deleteSObject(product.Id, true);

        System.assert(result.isSuccess() == false);
        System.assert(result.getErrorMessage().contains('This record must not be deleted. Id: ' + product.Id),
                result.getErrorMessage());
    }
}
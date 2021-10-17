@IsTest
public class CPQSubscriptionServiceTest {

    @IsTest
    static void testFindAccountActiveProducts() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = new Contract(
                AccountId = account.Id,
                Wrike_Account_ID__c = 123,
                Status = 'Draft'
        );
        insert contract;
        contract.Status = 'Activated';
        update contract;
        final Product2 product = new Product2(
                ProductCode = 'product',
                Name = 'Test Product'
        );
        insert product;
        insert new SBQQ__Subscription__c(
                SBQQ__Contract__c = contract.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__Quantity__c = 5,
                SBQQ__NetPrice__c = 10,
                SBQQ__RenewalPrice__c = 10,
                SBQQ__ProrateMultiplier__c = 1,
                SBQQ__SubscriptionStartDate__c = Date.today().addDays(-5),
                SBQQ__SubscriptionEndDate__c = Date.today().addDays(5)
        );
        insert new SBQQ__Subscription__c(
                SBQQ__Contract__c = contract.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__Quantity__c = 10,
                SBQQ__NetPrice__c = 20,
                SBQQ__RenewalPrice__c = 20,
                SBQQ__ProrateMultiplier__c = 1,
                SBQQ__SubscriptionStartDate__c = Date.today().addDays(-5),
                SBQQ__SubscriptionEndDate__c = Date.today().addDays(5)
        );
        final List<CPQSubscriptionService.SubscriptionProduct> subscriptionProducts =
                CPQSubscriptionService.getInstance().findAccountActiveProducts(123);
        System.assertEquals(1, subscriptionProducts.size());
        final CPQSubscriptionService.SubscriptionProduct subscriptionProduct = subscriptionProducts.get(0);
        System.assertEquals('Test Product', subscriptionProduct.name);
        System.assertEquals(15, subscriptionProduct.quantity);
        System.assertEquals(16.67, subscriptionProduct.avgEffectivePrice);
        System.assertEquals(16.67, subscriptionProduct.avgRenewalPrice);
    }

    @IsTest
    static void testCheckContractHasCurrentSubscription() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = new Contract(
                AccountId = account.Id,
                Wrike_Account_ID__c = 123,
                Status = 'Draft',
                EndDate = Date.today().addDays(5)
        );
        insert contract;
        contract.Status = 'Activated';
        update contract;
        final Product2 product = new Product2(
                ProductCode = 'product',
                Name = 'Test Product'
        );
        insert product;
        insert new SBQQ__Subscription__c(
                SBQQ__Contract__c = contract.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__Quantity__c = 5,
                SBQQ__NetPrice__c = 10,
                SBQQ__RenewalPrice__c = 10,
                SBQQ__ProrateMultiplier__c = 1,
                SBQQ__SubscriptionStartDate__c = Date.today().addDays(-5),
                SBQQ__SubscriptionEndDate__c = Date.today().addDays(5)
        );
        System.assert(CPQSubscriptionService.getInstance().checkContractHasCurrentSubscription(contract.Id, 'product'));
    }

    @IsTest
    static void testGetContractBasePlanQuantity() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = new Contract(
                AccountId = account.Id,
                Wrike_Account_ID__c = 123,
                Status = 'Draft',
                EndDate = Date.today().addDays(5)
        );
        insert contract;
        contract.Status = 'Activated';
        update contract;
        final Product2 product = new Product2(
                ProductCode = 'r-lic-base-Biz',
                Name = 'Test Product',
                PG1__c = 'License',
                PG2__c = 'Base Plans',
                PG3__c = 'Base'
        );
        insert product;
        insert new SBQQ__Subscription__c(
                SBQQ__Contract__c = contract.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__Quantity__c = 5,
                SBQQ__NetPrice__c = 10,
                SBQQ__RenewalPrice__c = 10,
                SBQQ__ProrateMultiplier__c = 1,
                SBQQ__SubscriptionStartDate__c = Date.today().addDays(-5),
                SBQQ__SubscriptionEndDate__c = Date.today().addDays(5)
        );
        System.assertEquals(5, CPQSubscriptionService.getInstance().getContractBasePlanQuantity(contract.Id));
    }
}
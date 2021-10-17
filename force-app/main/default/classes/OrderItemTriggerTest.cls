@IsTest
public class OrderItemTriggerTest {

    @IsTest
    static void testUpdateDatesFromQuoteLine() {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = 'Draft'
        );
        insert quote;
        final Product2 product = new Product2(
                Name = 'Test Product'
        );
        insert product;
        final SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id,
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addDays(5),
                SBQQ__Quantity__c = 5
        );
        insert quoteLine;
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
        insert pricebook;
        final Order order = new Order(
                AccountId = account.Id,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                Pricebook2Id = pricebook.Id
        );
        insert order;
        final PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(pricebook.Id, product.Id, 11.11);
        insert pricebookEntry;
        final OrderItem orderItem = new OrderItem(
                OrderId = order.Id,
                SBQQ__QuoteLine__c = quoteLine.Id,
                PricebookEntryId = pricebookEntry.Id,
                UnitPrice = 11.11,
                Quantity = 1
        );
        insert orderItem;

        final OrderItem updatedOrderItem = [
                SELECT Id, ServiceDate, EndDate
                FROM OrderItem
                WHERE Id = :orderItem.Id
        ];

        System.assertEquals(Date.today(), updatedOrderItem.ServiceDate);
        System.assertEquals(Date.today().addDays(5), updatedOrderItem.EndDate);
    }
}
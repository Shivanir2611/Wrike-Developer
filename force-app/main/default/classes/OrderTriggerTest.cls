@IsTest
public class OrderTriggerTest {

    @IsTest
    static void testUpdateOrderFromQuote() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Integer wrikeAccountId = 12345;
        final QS_Bill_To_Ship_To__c billTo = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, true);
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, false);
        insert shipTo;

        final SBQQ__Quote__c quote = insertQuote(billTo.Id, shipTo.Id, account.Id, wrikeAccountId);
        final Order order = new Order(
                AccountId = account.Id,
                SBQQ__Quote__c = quote.Id,
                OpportunityId = quote.SBQQ__Opportunity2__c,
                Status = 'Draft',
                EffectiveDate = Date.today()
        );
        insert order;

        final Order updatedOrder = findOrderById(order.Id);
        System.assertEquals(billTo.Id, updatedOrder.QS_Bill_To__c);
        System.assertEquals(shipTo.Id, updatedOrder.QS_Ship_To__c);
        System.assertEquals(wrikeAccountId, updatedOrder.WrikeAccountId__c);
    }

    @IsTest
    static void testCreateOfacChecks() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Integer wrikeAccountId = 12345;
        final QS_Bill_To_Ship_To__c billTo = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, true);
        insert billTo;

        final QS_Bill_To_Ship_To__c shipTo1 = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, false);
        insert shipTo1;

        final QS_Bill_To_Ship_To__c shipTo2 = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, false);
        insert shipTo2;

        final WrikeData__c wrikeData = TestDataFactory.createWrikeData(wrikeAccountId, false);
        insert wrikeData;

        insert(new OfacCheck__c(BillToShipTo__c = billTo.Id, WrikeAccountId__c = wrikeAccountId,
                Type__c = 'BillToShipTo'));

        final SBQQ__Quote__c quote1 = insertQuote(billTo.Id, shipTo1.Id, account.Id, wrikeAccountId);
        final Order order1 = new Order(
                AccountId = account.Id,
                SBQQ__Quote__c = quote1.Id,
                OpportunityId = quote1.SBQQ__Opportunity2__c,
                Status = 'Draft',
                EffectiveDate = Date.today()
        );
        final SBQQ__Quote__c quote2 = insertQuote(billTo.Id, shipTo2.Id, account.Id, wrikeAccountId);
        final Order order2 = new Order(
                AccountId = account.Id,
                SBQQ__Quote__c = quote2.Id,
                OpportunityId = quote2.SBQQ__Opportunity2__c,
                Status = 'Draft',
                EffectiveDate = Date.today()
        );
        insert new List<Order> { order1, order2 };

        final List<OfacCheck__c> ofacChecks = listOfacChecks();
        System.assertEquals(4, ofacChecks.size());
        OfacCheck__c billToCheck = null;
        OfacCheck__c shipToCheck1 = null;
        OfacCheck__c shipToCheck2 = null;
        OfacCheck__c ownerCheck = null;
        for(OfacCheck__c ofacCheck : ofacChecks) {
            if(ofacCheck.BillToShipTo__c == billTo.Id) {
                billToCheck = ofacCheck;
            } else if(ofacCheck.BillToShipTo__c == shipTo1.Id) {
                shipToCheck1 = ofacCheck;
            } else if(ofacCheck.BillToShipTo__c == shipTo2.Id) {
                shipToCheck2 = ofacCheck;
            } else if(ofacCheck.WrikeData__c == wrikeData.Id) {
                ownerCheck = ofacCheck;
            }
        }
        System.assertNotEquals(null, billToCheck);
        System.assertNotEquals(null, shipToCheck1);
        System.assertNotEquals(null, shipToCheck2);
        System.assertNotEquals(null, ownerCheck);

        final Order updatedOrder1 = findOrderById(order1.Id);
        final Order updatedOrder2 = findOrderById(order2.Id);
        System.assertEquals(billToCheck.Id, updatedOrder1.BillToCheck__c);
        System.assertEquals(shipToCheck1.Id, updatedOrder1.ShipToCheck__c);
        System.assertEquals(ownerCheck.Id, updatedOrder1.OwnerCheck__c);
        System.assertEquals(billToCheck.Id, updatedOrder2.BillToCheck__c);
        System.assertEquals(shipToCheck2.Id, updatedOrder2.ShipToCheck__c);
        System.assertEquals(ownerCheck.Id, updatedOrder2.OwnerCheck__c);
        System.assertEquals('BillToShipTo', shipToCheck1.Type__c);
        System.assertEquals('BillToShipTo', shipToCheck2.Type__c);
        System.assertEquals('Owner', ownerCheck.Type__c);
        System.assertEquals(wrikeAccountId, shipToCheck1.WrikeAccountId__c);
        System.assertEquals(wrikeAccountId, shipToCheck2.WrikeAccountId__c);
        System.assertEquals(wrikeAccountId, ownerCheck.WrikeAccountId__c);
    }

    @IsTest
    static void testOfacChecksForOrderWithOneAddress() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Integer wrikeAccountId = 12345;
        final QS_Bill_To_Ship_To__c billTo = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, true);
        insert billTo;

        final WrikeData__c wrikeData = TestDataFactory.createWrikeData(wrikeAccountId, false);
        insert wrikeData;

        final SBQQ__Quote__c quote = insertQuote(billTo.Id, null, account.Id, wrikeAccountId);
        final Order order = new Order(
                AccountId = account.Id,
                SBQQ__Quote__c = quote.Id,
                OpportunityId = quote.SBQQ__Opportunity2__c,
                Status = 'Draft',
                EffectiveDate = Date.today()
        );
        insert order;

        final List<OfacCheck__c> ofacChecks = listOfacChecks();
        System.assertEquals(2, ofacChecks.size());
        OfacCheck__c billToCheck = null;
        OfacCheck__c ownerCheck = null;
        for(OfacCheck__c ofacCheck : ofacChecks) {
            if(ofacCheck.BillToShipTo__c == billTo.Id) {
                billToCheck = ofacCheck;
            } else if(ofacCheck.WrikeData__c == wrikeData.Id) {
                ownerCheck = ofacCheck;
            }
        }
        System.assertNotEquals(null, billToCheck);
        System.assertNotEquals(null, ownerCheck);

        final Order updatedOrder = findOrderById(order.Id);
        System.assertEquals(billToCheck.Id, updatedOrder.BillToCheck__c);
        System.assertEquals(null, updatedOrder.ShipToCheck__c);
        System.assertEquals(ownerCheck.Id, updatedOrder.OwnerCheck__c);
    }

    @IsTest
    static void testDeleteActivatedOrder() {
        if (!OrganizationService.getInstance().isSandbox()) {
            final Pricebook2 priceBook = new Pricebook2(Name = 'Test PriceBook', IsActive = true);
            insert priceBook;
            final Account account = TestDataFactory.createAccount();
            insert account;
            final Order order = new Order(
                    Status = 'Draft',
                    AccountId = account.Id,
                    EffectiveDate = Date.today(),
                    Pricebook2Id = priceBook.Id
            );
            insert order;

            final Product2 product = new Product2(Name = 'Test Product');
            insert product;
            final Id priceBookEntryId = TestUtils.createPricebookEntry(product.Id, priceBook.Id, 10);
            insert new OrderItem(
                    Product2Id = product.Id,
                    PricebookEntryId = priceBookEntryId,
                    OrderId = order.Id,
                    UnitPrice = 10,
                    Quantity = 5
            );

            order.Status = 'Activated';
            update order;
            DatabaseService.Result result = DatabaseService.getInstance().deleteSObject(order.Id, true);
            System.assert(result.isSuccess() == false);
            System.assert(result.getErrorMessage().contains('Activated Order cannot be deleted. Id: ' + order.Id),
                    result.getErrorMessage());
        }
    }

    private static Order findOrderById(final Id id) {
        return [
                SELECT Id, QS_Bill_To__c, QS_Ship_To__c, WrikeAccountId__c, BillToCheck__c, ShipToCheck__c, OwnerCheck__c
                FROM Order
                WHERE Id = :id
        ];
    }

    private static List<OfacCheck__c> listOfacChecks() {
        return [
                SELECT Id, WrikeAccountId__c, Type__c, BillToShipTo__c, WrikeData__c
                FROM OfacCheck__c
        ];
    }

    private static SBQQ__Quote__c insertQuote(final Id billToId, final Id shipToId, final Id accountId, final Integer wrikeAccountId) {
        final Opportunity opportunity = TestDataFactory.createOpportunity(accountId, wrikeAccountId);
        insert opportunity;

        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                QS_Bill_To__c = billToId,
                QS_Ship_To__c = shipToId,
                WrikeAccountId__c = wrikeAccountId,
                SBQQ__Primary__c = true,
                SBQQ__Opportunity2__c = opportunity.Id
        );
        insert quote;

        return quote;
    }
}
@IsTest
public class BillToShipToFormControllerTest {

    @IsTest
    static void testGetFormByQuoteId() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(WrikeAccountId__c = 123, SBQQ__Account__c = account.Id);
        insert quote;
        final BillToShipToForm billToShipToForm = BillToShipToFormController.getFormByQuoteId(quote.Id);

        System.assertNotEquals(null, billToShipToForm.countryMap);
        System.assertNotEquals(null, billToShipToForm.usStateMap);
        System.assertNotEquals(null, billToShipToForm.canadaStateMap);

        System.assertEquals(true, billToShipToForm.billTo.QS_Invoice_via_Email__c);
        System.assertEquals(true, billToShipToForm.billTo.QS_Bill_To__c);
        System.assertEquals(quote.SBQQ__Account__c, billToShipToForm.billTo.QS_Account__c);
        System.assertEquals(quote.WrikeAccountId__c, billToShipToForm.billTo.Wrike_Account_ID__c);

        System.assertEquals(true, billToShipToForm.shipTo.QS_Ship_To__c);
        System.assertEquals(quote.SBQQ__Account__c, billToShipToForm.shipTo.QS_Account__c);
        System.assertEquals(quote.WrikeAccountId__c, billToShipToForm.shipTo.Wrike_Account_ID__c);
    }

    @IsTest
    static void testGetFormByAccountId() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final BillToShipToForm billToShipToForm = BillToShipToFormController.getFormByAccountId(account.Id);

        System.assertNotEquals(null, billToShipToForm.countryMap);
        System.assertNotEquals(null, billToShipToForm.usStateMap);
        System.assertNotEquals(null, billToShipToForm.canadaStateMap);

        System.assertEquals(true, billToShipToForm.billTo.QS_Invoice_via_Email__c);
        System.assertEquals(true, billToShipToForm.billTo.QS_Bill_To__c);
        System.assertEquals(account.Id, billToShipToForm.billTo.QS_Account__c);
        System.assertEquals(null, billToShipToForm.billTo.Wrike_Account_ID__c);

        System.assertEquals(true, billToShipToForm.shipTo.QS_Ship_To__c);
        System.assertEquals(account.Id, billToShipToForm.shipTo.QS_Account__c);
        System.assertEquals(null, billToShipToForm.shipTo.Wrike_Account_ID__c);
    }

    @IsTest
    static void testSaveContacts() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(WrikeAccountId__c = 123, SBQQ__Account__c = account.Id);
        insert quote;
        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
                QS_Bill_To__c = true,
                QS_Email__c = 'test1@email.test',
                QS_Account__c = account.Id
        );
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = new QS_Bill_To_Ship_To__c(
                QS_Ship_To__c = true,
                QS_Email__c = 'test2@email.test',
                QS_Account__c = account.Id
        );
        insert shipTo;
        final QS_Bill_To_Ship_To__c endCustomer = new QS_Bill_To_Ship_To__c(
                EndCustomer__c = true,
                QS_Email__c = 'test3@email.test',
                QS_Account__c = account.Id
        );
        insert endCustomer;

        BillToShipToFormController.saveContacts(
                quote.Id,
                new QS_Bill_To_Ship_To__c(Id = billTo.Id, QS_Email__c = 'test3@email.test'),
                new QS_Bill_To_Ship_To__c(Id = shipTo.Id, QS_Email__c = 'test4@email.test'),
                new QS_Bill_To_Ship_To__c(Id = endCustomer.Id, QS_Email__c = 'test5@email.test')
        );

        final SBQQ__Quote__c updatedQuote = findQuoteById(quote.Id);
        System.assertEquals(billTo.Id, updatedQuote.QS_Bill_To__c);
        System.assertEquals(shipTo.Id, updatedQuote.QS_Ship_To__c);
        System.assertEquals(endCustomer.Id, updatedQuote.EndCustomer__c);

        final QS_Bill_To_Ship_To__c updatedBillTo = findBillToShipToById(billTo.Id);
        System.assertEquals('test3@email.test', updatedBillTo.QS_Email__c);
        final QS_Bill_To_Ship_To__c updatedShipTo = findBillToShipToById(shipTo.Id);
        System.assertEquals('test4@email.test', updatedShipTo.QS_Email__c);
        final QS_Bill_To_Ship_To__c updatedEndCustomer = findBillToShipToById(endCustomer.Id);
        System.assertEquals('test5@email.test', updatedEndCustomer.QS_Email__c);
    }

    private static SBQQ__Quote__c findQuoteById(final Id quoteId) {
        return [
                SELECT Id, QS_Bill_To__c, QS_Ship_To__c, EndCustomer__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
    }

    private static QS_Bill_To_Ship_To__c findBillToShipToById(final Id contactId) {
        return [
                SELECT Id, QS_Email__c
                FROM QS_Bill_To_Ship_To__c
                WHERE Id = :contactId
        ];
    }
}
@IsTest
public class OFACCheckTriggerTest {

    @IsTest
    static void testBillingStatusUpdate() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final QS_Bill_To_Ship_To__c billTo = TestDataFactory.createBillToShipTo(account.Id, 123, true);
        insert billTo;
        final OfacCheck__c ofacCheck = new OfacCheck__c(
                BillToShipTo__c = billTo.Id,
                WrikeAccountId__c = billTo.Wrike_Account_ID__c,
                Type__c = 'BillToShipTo'
        );
        insert ofacCheck;
        System.assertEquals('Activated', findBillingStatus(ofacCheck.Id));
        Test.startTest();
        ofacCheck.CheckResult__c = 'Potential Match';
        update ofacCheck;
        System.assertEquals('Activated', findBillingStatus(ofacCheck.Id));
        ofacCheck.CheckResult__c = 'No Match';
        update ofacCheck;
        System.assertEquals('Pending', findBillingStatus(ofacCheck.Id));
        Test.stopTest();
    }

    private static String findBillingStatus(final Id ofacCheckId) {
        return [
               SELECT NetsuiteBillingStatus__c
               FROM OfacCheck__c
               WHERE Id = :ofacCheckId
        ]?.NetsuiteBillingStatus__c;
    }

    @IsTest
    static void testLastCheckDateUpdate() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Integer wrikeAccountId = 123;
        final QS_Bill_To_Ship_To__c billTo = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, true);
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, false);
        insert shipTo;
        final OfacCheck__c billToOfacCheck = new OfacCheck__c(
                BillToShipTo__c = billTo.Id,
                WrikeAccountId__c = wrikeAccountId,
                Type__c = 'BillToShipTo',
                LastCheckDate__c = Datetime.now().addDays(-1)
        );
        insert billToOfacCheck;
        final OfacCheck__c shipToOfacCheck = new OfacCheck__c(
                BillToShipTo__c = shipTo.Id,
                WrikeAccountId__c = wrikeAccountId,
                Type__c = 'BillToShipTo',
                LastCheckDate__c = Datetime.now().addDays(-1)
        );
        insert shipToOfacCheck;
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = wrikeAccountId
        );
        insert wrikeData;
        final OfacCheck__c ownerOfacCheck = new OfacCheck__c(
                WrikeData__c = wrikeData.Id,
                WrikeAccountId__c = wrikeAccountId,
                Type__c = 'Owner',
                LastCheckDate__c = Datetime.now().addDays(-1)
        );
        insert ownerOfacCheck;

        Test.startTest();
        System.assertEquals(false, findLastCheckDate(shipToOfacCheck.Id).isSameDay(Datetime.now()));
        System.assertEquals(false, findLastCheckDate(ownerOfacCheck.Id).isSameDay(Datetime.now()));
        billToOfacCheck.LastCheckDate__c = Datetime.now();
        billToOfacCheck.CheckResult__c = 'No Match';
        update billToOfacCheck;
        System.assertEquals(true, findLastCheckDate(shipToOfacCheck.Id).isSameDay(Datetime.now()));
        System.assertEquals(true, findLastCheckDate(ownerOfacCheck.Id).isSameDay(Datetime.now()));
        Test.stopTest();
    }

    private static Datetime findLastCheckDate(final Id ofacCheckId) {
        return [
               SELECT LastCheckDate__c
               FROM OfacCheck__c
               WHERE Id = :ofacCheckId
        ]?.LastCheckDate__c;
    }

    @IsTest
    static void testBillToShipToUpdate() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Integer wrikeAccountId = 12345;
        final QS_Bill_To_Ship_To__c billTo = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, true);
        insert billTo;
        billTo.NetSuiteSyncStatus__c = BillToShipToTriggerHandler.NetSuiteSyncStatus.PROCESSED.name();
        update billTo;

        final OfacCheck__c ofacCheck = new OfacCheck__c(
                BillToShipTo__c = billTo.Id,
                WrikeAccountId__c = wrikeAccountId,
                Type__c = 'BillToShipTo',
                CheckResult__c = 'Potential Match'
        );
        insert ofacCheck;

        ofacCheck.CheckResult__c = 'No Match';
        update ofacCheck;

        final QS_Bill_To_Ship_To__c billToAfterUpdate = [
                SELECT NetSuiteSyncStatus__c
                FROM QS_Bill_To_Ship_To__c
                WHERE Id = :billTo.Id
        ];
        System.assertEquals(BillToShipToTriggerHandler.NetSuiteSyncStatus.PENDING.name(), billToAfterUpdate.NetSuiteSyncStatus__c, 'Related BillToShipTo__c record was not updated!');
    }

    @IsTest
    static void testNoBillToShipToUpdate() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Integer wrikeAccountId = 12345;
        final QS_Bill_To_Ship_To__c billTo = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, true);
        insert billTo;
        billTo.NetSuiteSyncStatus__c = BillToShipToTriggerHandler.NetSuiteSyncStatus.PROCESSED.name();
        update billTo;

        final OfacCheck__c ofacCheck = new OfacCheck__c(
                BillToShipTo__c = billTo.Id,
                WrikeAccountId__c = wrikeAccountId,
                Type__c = 'BillToShipTo',
                CheckResult__c = 'Pending'
        );
        insert ofacCheck;

        ofacCheck.CheckResult__c = 'Potential Match';
        update ofacCheck;

        final QS_Bill_To_Ship_To__c billToAfterUpdate = [
                SELECT NetSuiteSyncStatus__c
                FROM QS_Bill_To_Ship_To__c
                WHERE Id = :billTo.Id
        ];
        System.assertEquals(BillToShipToTriggerHandler.NetSuiteSyncStatus.PROCESSED.name(), billToAfterUpdate.NetSuiteSyncStatus__c, 'Related BillToShipTo__c record got updated!');
    }
}
@IsTest
public class BillToShipToTriggerTest {

    @IsTest
    static void testUpdateLastUpdateDate() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final QS_Bill_To_Ship_To__c testAddress = TestDataFactory.createBillToShipTo(account.Id, 12345, true);
        insert testAddress;

        final Datetime lastUpdateDateAfterCreate = findLastBillingInfoUpdateDate();

        testAddress.QS_Company_Name__c = 'Company Name';
        update testAddress;

        final Datetime lastUpdateDateAfterUpdate = findLastBillingInfoUpdateDate();

        System.assertEquals(null, lastUpdateDateAfterCreate);
        System.assertNotEquals(null, lastUpdateDateAfterUpdate);
        System.assert(lastUpdateDateAfterUpdate.isSameDay(Datetime.now()));
    }

    @IsTest
    static void testLastUpdateDateNotUpdated() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final QS_Bill_To_Ship_To__c testAddress = TestDataFactory.createBillToShipTo(account.Id, 12345, true);
        insert testAddress;

        testAddress.QS_Fax__c = '12345';
        update testAddress;

        System.assertEquals(null, findLastBillingInfoUpdateDate());
    }

    @IsTest
    static void testRecordProcessing() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final QS_Bill_To_Ship_To__c testRecord = TestDataFactory.createBillToShipTo(account.Id, 12345, true);
        insert testRecord;
        final QS_Bill_To_Ship_To__c pendingRecordAfterInsert = findBillToShipTo();

        System.assertNotEquals(null, pendingRecordAfterInsert);
        System.assertNotEquals(null, pendingRecordAfterInsert.LastUpdateDate__c);
        System.assertEquals(BillToShipToTriggerHandler.NetSuiteSyncStatus.PENDING.name(), pendingRecordAfterInsert.NetSuiteSyncStatus__c);

        testRecord.NetSuite_Customer_ID__c = 'netsuite_id_2';
        testRecord.LastNetSuiteSyncDate__c = pendingRecordAfterInsert.LastUpdateDate__c;
        update testRecord;
        final QS_Bill_To_Ship_To__c processedRecord = findBillToShipTo();

        System.assertNotEquals(null, processedRecord);
        System.assertEquals(BillToShipToTriggerHandler.NetSuiteSyncStatus.PROCESSED.name(), processedRecord.NetSuiteSyncStatus__c);
    }

    static void testRecordNotProcessed() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final QS_Bill_To_Ship_To__c testRecord = TestDataFactory.createBillToShipTo(account.Id, 12345, true);
        insert testRecord;
        final QS_Bill_To_Ship_To__c pendingRecordAfterInsert = findBillToShipTo();
        System.assertNotEquals(null, pendingRecordAfterInsert);

        testRecord.NetSuite_Customer_ID__c = 'netsuite_id';
        testRecord.LastNetSuiteSyncDate__c = pendingRecordAfterInsert.LastUpdateDate__c.addMinutes(-1);
        update testRecord;
        final QS_Bill_To_Ship_To__c pendingRecordAfterWorkato = findBillToShipTo();

        System.assertNotEquals(null, pendingRecordAfterWorkato);
        System.assertEquals(BillToShipToTriggerHandler.NetSuiteSyncStatus.PENDING.name(), pendingRecordAfterWorkato.NetSuiteSyncStatus__c);
    }

    static void testRecordUpdateToPending() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final QS_Bill_To_Ship_To__c testRecord = TestDataFactory.createBillToShipTo(account.Id, 12345, true);
        insert testRecord;
        final QS_Bill_To_Ship_To__c pendingRecordAfterInsert = findBillToShipTo();
        System.assertNotEquals(null, pendingRecordAfterInsert);

        testRecord.NetSuite_Customer_ID__c = 'netsuite_id';
        testRecord.LastNetSuiteSyncDate__c = pendingRecordAfterInsert.LastUpdateDate__c;
        update testRecord;
        final QS_Bill_To_Ship_To__c processedRecord = findBillToShipTo();

        update testRecord;
        final QS_Bill_To_Ship_To__c processedRecordWithoutUpdate = findBillToShipTo();

        testRecord.QS_Invoice_via_Portal__c = true;
        update testRecord;
        final QS_Bill_To_Ship_To__c pendingRecordAfterUpdate = findBillToShipTo();

        System.assertNotEquals(null, processedRecord);
        System.assertNotEquals(null, processedRecordWithoutUpdate);
        System.assertNotEquals(null, pendingRecordAfterUpdate);

        System.assertEquals(BillToShipToTriggerHandler.NetSuiteSyncStatus.PROCESSED.name(), processedRecord.NetSuiteSyncStatus__c);
        System.assertEquals(BillToShipToTriggerHandler.NetSuiteSyncStatus.PROCESSED.name(), processedRecordWithoutUpdate.NetSuiteSyncStatus__c);
        System.assertEquals(BillToShipToTriggerHandler.NetSuiteSyncStatus.PENDING.name(), pendingRecordAfterUpdate.NetSuiteSyncStatus__c);
    }

    private static Datetime findLastBillingInfoUpdateDate() {
        return [SELECT LastBillingInfoUpdateDate__c FROM QS_Bill_To_Ship_To__c]?.LastBillingInfoUpdateDate__c;
    }

    private static QS_Bill_To_Ship_To__c findBillToShipTo() {
        return [SELECT NetSuiteSyncStatus__c, LastUpdateDate__c FROM QS_Bill_To_Ship_To__c];
    }
}
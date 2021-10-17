public class BillToShipToTriggerHandler {

    public static BillToShipToTriggerHandler getInstance() {
        return (BillToShipToTriggerHandler)ServiceLocator.getInstance(BillToShipToTriggerHandler.class);
    }
    public void onBeforeInsert(final List<QS_Bill_To_Ship_To__c> newRecords) {
        for(QS_Bill_To_Ship_To__c newRecord : newRecords) {
            newRecord.LastUpdateDate__c = Datetime.now();
        }
    }

    public void onBeforeUpdate(final Map<Id, QS_Bill_To_Ship_To__c> oldRecords, final Map<Id, QS_Bill_To_Ship_To__c> newRecords) {
        for(QS_Bill_To_Ship_To__c newRecord : newRecords.values()) {
            final QS_Bill_To_Ship_To__c oldRecord = oldRecords.get(newRecord.Id);
            if(newRecord.QS_City__c != oldRecord.QS_City__c
                    || newRecord.QS_State_Code__c != oldRecord.QS_State_Code__c
                    || newRecord.QS_Company_Name__c != oldRecord.QS_Company_Name__c
                    || newRecord.QS_Country_Code__c != oldRecord.QS_Country_Code__c
                    || newRecord.QS_Zip_Postal_Code__c != oldRecord.QS_Zip_Postal_Code__c
                    || newRecord.QS_Street_1__c != oldRecord.QS_Street_1__c
                    || newRecord.QS_Street_2__c != oldRecord.QS_Street_2__c) {
                newRecord.LastBillingInfoUpdateDate__c = Datetime.now();
            }
            if(newRecord.LastBillingInfoUpdateDate__c != oldRecord.LastBillingInfoUpdateDate__c
                    || newRecord.QS_Country__c != oldRecord.QS_Country__c
                    || newRecord.RegionState__c != oldRecord.RegionState__c
                    || newRecord.QS_Attention_To__c != oldRecord.QS_Attention_To__c
                    || newRecord.QS_Phone__c != oldRecord.QS_Phone__c
                    || newRecord.QS_Email__c != oldRecord.QS_Email__c
                    || newRecord.VATNumber__c != oldRecord.VATNumber__c
                    || newRecord.Billing_Comments__c != oldRecord.Billing_Comments__c
                    || newRecord.QS_Invoice_via_Email__c != oldRecord.QS_Invoice_via_Email__c
                    || newRecord.QS_Invoice_via_Portal__c != oldRecord.QS_Invoice_via_Portal__c
                    || newRecord.QS_Secondary_Email__c != oldRecord.QS_Secondary_Email__c) {
                newRecord.LastUpdateDate__c = Datetime.now();
                newRecord.NetSuiteSyncStatus__c = NetSuiteSyncStatus.PENDING.name();
            } else if(newRecord.LastNetSuiteSyncDate__c != null && newRecord.LastNetSuiteSyncDate__c >= oldRecord.LastUpdateDate__c) {
                newRecord.NetSuiteSyncStatus__c = NetSuiteSyncStatus.PROCESSED.name();
            }
        }
    }

    public enum NetSuiteSyncStatus {
            PENDING,
            PROCESSED
    }
}
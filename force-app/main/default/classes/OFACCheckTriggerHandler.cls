public class OFACCheckTriggerHandler {

    public static OFACCheckTriggerHandler getInstance() {
        return (OFACCheckTriggerHandler)ServiceLocator.getInstance(OFACCheckTriggerHandler.class);
    }

    public void beforeUpdate(final Map<Id, OfacCheck__c> oldMap,
                             final Map<Id, OfacCheck__c> newMap) {
        for(OfacCheck__c newRecord : newMap.values()){
            final OfacCheck__c oldRecord = oldMap.get(newRecord.Id);
            if(newRecord.CheckResult__c == 'No Match' && oldRecord.CheckResult__c == 'Potential Match') {
                newRecord.NetsuiteBillingStatus__c = 'Pending';
            }
        }
    }

    public void afterUpdate(final Map<Id, OfacCheck__c> oldMap, final Map<Id, OfacCheck__c> newMap) {
        final List<QS_Bill_To_Ship_To__c> btstToUpdate = new List<QS_Bill_To_Ship_To__c>();
        final List<Decimal> checkedWrikeAccountIds = new List<Decimal>();
        for(OfacCheck__c newRecord : newMap.values()) {
            final OfacCheck__c oldRecord = oldMap.get(newRecord.Id);
            final String newCheckResult = newRecord.CheckResult__c;
            final String oldCheckResult = oldRecord.CheckResult__c;
            if(newRecord.LastCheckDate__c != oldRecord.LastCheckDate__c
                    && newCheckResult == 'No Match'
                    && newRecord.WrikeAccountId__c > 0) {
                checkedWrikeAccountIds.add(newRecord.WrikeAccountId__c);
            }
            if(newRecord.BillToShipTo__c != null
                    && (((newCheckResult == 'No Match' || newCheckResult == 'Match') && oldCheckResult == 'Potential Match')
                            || (newCheckResult == 'Potential Match' && oldCheckResult == 'No Match'))) {
                btstToUpdate.add(new QS_Bill_To_Ship_To__c(
                        Id = newRecord.BillToShipTo__c,
                        LastUpdateDate__c = Datetime.now(),
                        NetSuiteSyncStatus__c = BillToShipToTriggerHandler.NetSuiteSyncStatus.PENDING.name()
                ));
            }
        }
        if(!checkedWrikeAccountIds.isEmpty()) {
            final List<OfacCheck__c> pendingRecords = [
                    SELECT Id
                    FROM OfacCheck__c
                    WHERE WrikeAccountId__c IN :checkedWrikeAccountIds
                      AND CheckResult__c = 'Pending'
                      AND (NOT(Id IN :newMap.keySet()))
            ];
            if(!pendingRecords.isEmpty()) {
                for(OfacCheck__c pendingRecord : pendingRecords) {
                    pendingRecord.LastCheckDate__c = Datetime.now();
                }
                update pendingRecords;
            }
        }

        update btstToUpdate;
    }
}
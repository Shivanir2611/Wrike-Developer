trigger BillToShipToTrigger on QS_Bill_To_Ship_To__c (before insert, before update) {

    final BillToShipToTriggerHandler handler = BillToShipToTriggerHandler.getInstance();

    if(Trigger.isBefore && Trigger.isInsert) {
        handler.onBeforeInsert(Trigger.new);
    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        handler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
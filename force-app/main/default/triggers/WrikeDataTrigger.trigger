trigger WrikeDataTrigger on WrikeData__c (before update) {
    final WrikeDataTriggerHandler handler = WrikeDataTriggerHandler.getInstance();
    if(Trigger.isBefore && Trigger.isUpdate) {
        handler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
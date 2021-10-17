trigger CPQQuoteLineTrigger on SBQQ__QuoteLine__c (before insert, before update) {

    final CPQQuoteLineTriggerHandler handler = CPQQuoteLineTriggerHandler.getInstance();

    if (Trigger.isBefore && Trigger.isInsert) {
        handler.beforeInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        handler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
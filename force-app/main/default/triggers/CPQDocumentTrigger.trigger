trigger CPQDocumentTrigger on SBQQ__QuoteDocument__c (after insert) {

    final CPQDocumentTriggerHandler handler = CPQDocumentTriggerHandler.getInstance();

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new);
    }
}
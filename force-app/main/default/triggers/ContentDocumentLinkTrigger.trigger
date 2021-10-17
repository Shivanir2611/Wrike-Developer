trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {

    final ContentDocumentLinkTriggerHandler handler = ContentDocumentLinkTriggerHandler.getInstance();

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new);
    }
}
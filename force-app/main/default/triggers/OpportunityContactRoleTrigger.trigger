trigger OpportunityContactRoleTrigger on OpportunityContactRole (after insert) {
    final OpportunityContactRoleTriggerHandler handler = OpportunityContactRoleTriggerHandler.getInstance();
    if(Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new);
    }
}
trigger CampaignMemberTrigger on CampaignMember (after insert, after update) {
    final CampaignMemberTriggerHandler handler = CampaignMemberTriggerHandler.getInstance();
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
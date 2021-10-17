trigger ApprovalTrigger on sbaa__Approval__c (after insert, after update) {

    if(Trigger.isAfter && Trigger.isInsert) {
        ApprovalTriggerHandler.getInstance().afterInsert(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isUpdate) {
        ApprovalTriggerHandler.getInstance().afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
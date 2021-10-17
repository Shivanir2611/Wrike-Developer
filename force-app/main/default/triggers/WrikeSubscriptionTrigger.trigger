trigger WrikeSubscriptionTrigger on Subscription__c (after insert, after update) {

	final WrikeSubscriptionTriggerHandler handler = WrikeSubscriptionTriggerHandler.getInstance();

	if (Trigger.isAfter && Trigger.isInsert) {
		handler.afterInsert(Trigger.new);
	}

	if (Trigger.isAfter && Trigger.isUpdate) {
		handler.afterUpdate(Trigger.newMap, Trigger.oldMap);
	}
}
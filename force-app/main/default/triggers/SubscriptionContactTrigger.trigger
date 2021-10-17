trigger SubscriptionContactTrigger on SubscriptionContact__c (after insert, after update) {

	if(Trigger.isAfter && Trigger.isInsert) {
		SubscriptionContactTriggerHandler.getInstance().afterInsert(Trigger.newMap);
	}

	if(Trigger.isAfter && Trigger.isUpdate) {
		SubscriptionContactTriggerHandler.getInstance().afterUpdate(Trigger.oldMap, Trigger.newMap);
	}
}
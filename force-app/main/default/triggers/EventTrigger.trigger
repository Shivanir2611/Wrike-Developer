trigger EventTrigger on Event__c (before insert) {

	final EventTriggerHandler handler = EventTriggerHandler.getInstance();

	if (Trigger.isBefore && Trigger.isInsert) {
		handler.onBeforeInsert(Trigger.new);
	}
}
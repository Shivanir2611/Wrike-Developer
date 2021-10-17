/*
 * Created by sofia.kanukova on 02/09/2019.
 */
public class EventTriggerHandler {

	public static EventTriggerHandler getInstance() {
		return (EventTriggerHandler)ServiceLocator.getInstance(EventTriggerHandler.class);
	}

	public void onBeforeInsert(List<Event__c> newEvents) {

		final EventQueryService eventQuerySrv = EventQueryService.getInstance();

		final List<Id> relatedLeadIds = new List<Id>();
		for (Event__c event : newEvents) {
			if (event.Type__c.equals('SupportRequest') && event.Lead__c != null) {
				relatedLeadIds.add(event.Lead__c);
			}
		}
		if (!relatedLeadIds.isEmpty()) {
			final Map<Id, Lead> leadMap = new Map<Id, Lead>([
					SELECT Id, OwnerId
					FROM Lead
					WHERE Id IN :relatedLeadIds
			]);
			final List<Event__c> relatedEvents = eventQuerySrv.listEventsForLeadList(relatedLeadIds);
			final List<Event__c> eventsToUpdate = new List<Event__c>();
			for (Event__c re : relatedEvents) {
				final Lead relatedLead = leadMap.get(re.Lead__c);
				if (relatedLead != null && !ApexUtils.isUser(relatedLead.OwnerId)) {
					eventsToUpdate.add(new Event__c(
							Id = re.Id,
							Status__c = 'Cancelled',
							Cancellation_Date__c = Datetime.now()
					));
				}
			}
			if (!eventsToUpdate.isEmpty()) {
				update eventsToUpdate;
			}
		}
	}
}
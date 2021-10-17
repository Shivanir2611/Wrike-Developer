/**
 * Created by anna.goreslavskaya on 11/04/17.
 */
public class EventQueryService {

    public static EventQueryService getInstance() {
        return (EventQueryService)ServiceLocator.getInstance(EventQueryService.class);
    }

    public Event__c findEventById(final Id eventId) {
        final List<Event__c> events = [
            SELECT Id, Qualification_Code__c, Status__c, Recycle_Date__c, Cancellation_Date__c
            FROM Event__c
            WHERE Id = :eventId
        ];
        if(events.isEmpty()) {
            return null;
        }
        return events[0];
    }

    public List<Event__c> listEventsForLeadList(final List<Id> leadIds) {
        return [
            SELECT Id, Lead__c, Qualification_Code__c, Status__c, Recycle_Date__c, Cancellation_Date__c
            FROM Event__c
            WHERE Lead__c IN :leadIds
        ];
    }
}
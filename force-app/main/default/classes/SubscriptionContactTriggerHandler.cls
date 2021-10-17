/*
 * Created by andrey.kuleshov on 11/06/2019.
 */
public class SubscriptionContactTriggerHandler {

	public static SubscriptionContactTriggerHandler getInstance() {
		return (SubscriptionContactTriggerHandler)ServiceLocator.getInstance(SubscriptionContactTriggerHandler.class);
	}

	public void afterInsert(final Map<Id, SubscriptionContact__c> newMap) {
		final Set<Id> contactIds = new Set<Id>();
		final Map<Id, Id> ownerContactMap = new Map<Id, Id>();
		for(SubscriptionContact__c record : newMap.values()) {
			if(record.WrikeUserType__c == 'Admin') {
				contactIds.add(record.Contact__c);
			}
			if(record.WrikeUserType__c == 'Owner') {
				ownerContactMap.put(record.Subscription__c, record.Contact__c);
			}
		}
		SubscriptionService.getInstance().updateWrikeOwnerContacts(ownerContactMap);
		ContactService.getInstance().createNotificationAboutNewAdmins(contactIds);
	}

	public void afterUpdate(final Map<Id, SubscriptionContact__c> oldMap,
							final Map<Id, SubscriptionContact__c> newMap) {
		final Set<Id> contactIds = new Set<Id>();
		final Map<Id, Id> ownerContactMap = new Map<Id, Id>();
		for(Id recordId : newMap.keySet()) {
			final SubscriptionContact__c oldRecord = oldMap.get(recordId);
			final SubscriptionContact__c newRecord = newMap.get(recordId);
			if(newRecord.WrikeUserType__c == 'Admin'
					&& oldRecord.WrikeUserType__c != 'Admin'
					&& oldRecord.WrikeUserType__c != 'Owner') {
				contactIds.add(newRecord.Contact__c);
			} else if(newRecord.WrikeUserType__c == 'Owner'
					&& oldRecord.WrikeUserType__c != 'Owner') {
				ownerContactMap.put(newRecord.Subscription__c, newRecord.Contact__c);
			}
		}
		SubscriptionService.getInstance().updateWrikeOwnerContacts(ownerContactMap);
		ContactService.getInstance().createNotificationAboutNewAdmins(contactIds);
	}
}
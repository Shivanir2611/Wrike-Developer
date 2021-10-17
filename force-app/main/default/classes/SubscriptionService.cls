/*
 * Created by Andrey Kuleshov
 */
public class SubscriptionService {

	public static SubscriptionService getInstance() {
		return (SubscriptionService)ServiceLocator.getInstance(SubscriptionService.class);
	}

	public void updateWrikeOwnerContacts(final Map<Id, Id> subscriptionOwnerContactMap) {
		if(!subscriptionOwnerContactMap.isEmpty()) {
			final List<Subscription__c> subscriptions = new List<Subscription__c>();
			for(Id subscriptionId : subscriptionOwnerContactMap.keySet()) {
				subscriptions.add(new Subscription__c(
						Id = subscriptionId,
						Wrike_Owner__c = subscriptionOwnerContactMap.get(subscriptionId)
				));
			}
			update subscriptions;
		}
	}
}
/**
 * Created by andrey.kuleshov on 23/07/2018.
 */
public class LeadContactsController extends AbstractPagingWithSortingController {
	private final ContactQueryService contactQuerySrv = ContactQueryService.getInstance();
	private final LeadQueryService leadQuerySrv = LeadQueryService.getInstance();
	private final SubscriptionQueryService subscriptionQuerySrv = SubscriptionQueryService.getInstance();
	private final Id leadId;
	private List<Contact> contacts;
	private Map<Decimal, Subscription__c> activeSubscriptionMap;

	public LeadContactsController(final ApexPages.StandardController controller) {
		super(Schema.Contact.sObjectType, 5, Schema.Contact.Name, false);
		this.leadId = controller.getId();
		final Lead lead = leadQuerySrv.findLeadById(leadId);
		final List<Contact> contactsByEmail = contactQuerySrv.listSubscriptionContactsByEmail(lead.Email);
		this.activeSubscriptionMap = getActiveSubscriptionMap(contactsByEmail);
		this.contacts = new List<Contact>();
		for(Contact contact : contactsByEmail) {
			if(activeSubscriptionMap.containsKey(contact.Wrike_Account_Id__c)) {
				this.contacts.add(contact);
			}
		}
		setTotal(this.contacts.size());
	}

	private Map<Decimal, Subscription__c> getActiveSubscriptionMap(final List<Contact> contactsByEmail) {
		final Set<Decimal> wrikeAccountIds = new Set<Decimal>();
		for(Contact contact : contactsByEmail) {
			wrikeAccountIds.add(contact.Wrike_Account_Id__c);
		}
		final List<Subscription__c> subscriptions = subscriptionQuerySrv.listActiveSubscriptionsByWrikeAccountIds(wrikeAccountIds);
		final Map<Decimal, Subscription__c> subscriptionMap = new Map<Decimal, Subscription__c>();
		for(Subscription__c subscription : subscriptions) {
			subscriptionMap.put(subscription.Wrike_Account_Id__c, subscription);
		}
		return subscriptionMap;
	}

	public List<Contact> getContacts() {
		return (List<Contact>)getRecords();
	}

	protected override List<SObject> getRecords() {
		return getSortedRecords((List<SObject>)this.contacts);
	}

	public Map<Decimal, Subscription__c> getActiveSubscriptionMap() {
		return activeSubscriptionMap;
	}

	public LeadContactsController getController() {
		return this;
	}
}
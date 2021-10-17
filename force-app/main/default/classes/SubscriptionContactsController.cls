/**
 * Created by andrey.kuleshov on 10/07/2018.
 */
public class SubscriptionContactsController extends AbstractPagingWithSortingController {
	private final SubscriptionQueryService subscriptionQuerySrv = SubscriptionQueryService.getInstance();
	private final ContactQueryService contactQuerySrv = ContactQueryService.getInstance();
	private final Id subscriptionId;
	private final Subscription__c subscription;
	private List<Contact> contacts;

	public SubscriptionContactsController(final ApexPages.StandardController controller) {
		super(Schema.Contact.sObjectType, 10, Schema.Contact.Name, false);
		this.subscriptionId = controller.getId();
		this.subscription = subscriptionQuerySrv.findSubscriptionById(subscriptionId);
		this.contacts = contactQuerySrv.listAccountContactsByWrikeAccountId(subscription.Account__c, subscription.Wrike_Account_Id__c);
		setTotal(this.contacts.size());
	}

	public List<Contact> getContacts() {
		return (List<Contact>)getRecords();
	}

	public override List<sObject> getRecords() {
		return getSortedRecords((List<sObject>)this.contacts);
	}

	public SubscriptionContactsController getController() {
		return this;
	}

	public PageReference save() {
		final Map<Id, Contact> existingContactMap = new Map<Id, Contact>(
				contactQuerySrv.listAccountContactsByWrikeAccountId(
						subscription.Account__c,
						subscription.Wrike_Account_Id__c));
		final List<Contact> contactsToUpdate = new List<Contact>();
		for(Contact contact : contacts) {
			final Contact existingContact = existingContactMap.get(contact.Id);
			if(existingContact != null
					&& (existingContact.VOC_Role__c != contact.VOC_Role__c
							|| existingContact.VOC_Do_Not_Survey__c != contact.VOC_Do_Not_Survey__c)) {
				contactsToUpdate.add(new Contact(
					Id = contact.Id,
					VOC_Role__c = contact.VOC_Role__c,
					VOC_Do_Not_Survey__c = contact.VOC_Do_Not_Survey__c
				));
			}
		}
		if(!contactsToUpdate.isEmpty()) {
			update contactsToUpdate;
		}
		return null;
	}

	public PageReference cancel() {
		this.contacts = contactQuerySrv.listAccountContactsByWrikeAccountId(
				subscription.Account__c,
				subscription.Wrike_Account_Id__c);
		return null;
	}
}
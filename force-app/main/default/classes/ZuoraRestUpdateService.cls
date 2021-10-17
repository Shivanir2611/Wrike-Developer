public class ZuoraRestUpdateService {

    public static ZuoraRestUpdateService getInstance() {
        return (ZuoraRestUpdateService)ServiceLocator.getInstance(ZuoraRestUpdateService.class);
    }

    private final ZuoraRestApi zuoraApi = ZuoraRestApi.getInstance();

    public String createBillingContact(final String zuoraAccountId,
                                       final BillingInfo billingInfo,
                                       final String companyName) {
        final ZuoraObject.ZuoraContact billContact = new ZuoraObject.ZuoraContact();
        billContact.accountId = zuoraAccountId;
        billContact.firstName = billingInfo.firstName;
        billContact.lastName = billingInfo.lastName;
        billContact.workEmail = billingInfo.email;
        billContact.country = billingInfo.country;
        billContact.state = billingInfo.state != null ? billingInfo.state : '';
        billContact.city = billingInfo.city;
        billContact.address1 = billingInfo.address1;
        billContact.address2 = billingInfo.address2;
        billContact.postalCode = billingInfo.zip;
        billContact.companyName = companyName;
        return zuoraApi.createObject(billContact, 'Contact');
    }


    public void updateContact(final String contactId,
                              final BillingInfo billingInfo,
                              final String companyName) {
        final ZuoraObject.ZuoraContact billContact = new ZuoraObject.ZuoraContact();
        billContact.id = contactId;
        billContact.country = billingInfo.country;
        billContact.state = billingInfo.state != null ? billingInfo.state : '';
        billContact.city = billingInfo.city;
        billContact.address1 = billingInfo.address1;
        billContact.address2 = billingInfo.address2;
        billContact.postalCode = billingInfo.zip;
        billContact.companyName = companyName;
        zuoraApi.updateObject(billContact, 'Contact');
    }

    public void updateSubscriptionPurchaseOrderNumber(final String subscriptionId,
                                          final String purchaseOrderNumber) {
        final ZuoraObject.ZuoraSubscription subscription = new ZuoraObject.ZuoraSubscription();
        subscription.id = subscriptionId;
        if (String.isNotBlank(purchaseOrderNumber)) {
            subscription.purchaseOrderNumber = purchaseOrderNumber;
        } else {
            subscription.fieldsToNull = new Set<String>{ 'PurchaseOrderNumber__c' };
        }
        zuoraApi.updateObject(subscription, 'Subscription');
    }
}
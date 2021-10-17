public class ZuoraService {

    private static final Logger log = Logger.create(ZuoraService.class);

    private static final String checkPaymentMethodId;

    public static ZuoraService getInstance() {
        return (ZuoraService)ServiceLocator.getInstance(ZuoraService.class);
    }

    private final ZuoraRestApi zuoraApi = ZuoraRestApi.getInstance();
    private final ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();
    private final ZuoraRestUpdateService zuoraRestUpdateSrv = ZuoraRestUpdateService.getInstance();

    public void updatePaymentInfo(final String zuoraAccountId,
                                  final Boolean activationRequired,
                                  final BillingInfo billingInfo,
                                  final String creditCardId,
                                  final String vatNumber,
                                  final String paymentTerm,
                                  final String companyName) {
        final Map<String, ZuoraObject.ZuoraContact> contacts = zuoraRestQuerySrv.findContactMap(zuoraAccountId);
        final ZuoraObject.ZuoraContact firstContact = contacts.isEmpty() ? null : contacts.values().get(0);
        final ZuoraObject.ZuoraContact existingContact =
        String.isBlank(billingInfo.email) ? firstContact : contacts.get(billingInfo.email);
        final String existingContactId = existingContact != null ? existingContact.id : null;
        if (existingContactId != null) {
            zuoraRestUpdateSrv.updateContact(existingContactId, billingInfo, companyName);
        }
        final String billingContactId = (existingContactId != null)
                                        ? existingContactId
                                        : zuoraRestUpdateSrv.createBillingContact(zuoraAccountId, billingInfo,
                companyName);
        final ZuoraObject.ZuoraAccount account = zuoraRestQuerySrv.findZuoraAccountById(zuoraAccountId);
        if (account != null) {
            final Boolean creditCard = creditCardId != null;
            final String existingPaymentMethodId = account.defaultPaymentMethodId;
            final String existingVatNumber = account.vatNumber;
            final String billToId = account.billToId;
            final String soldToId = account.soldToId;
            final String newPaymentMethodId =
            creditCard ? creditCardId : zuoraRestQuerySrv.getCheckPaymentMethodId(checkPaymentMethodId);
            final Boolean paymentMethodIdUpdate = newPaymentMethodId != existingPaymentMethodId;
            final Boolean vatNumberUpdate = String.isNotBlank(vatNumber) && vatNumber != existingVatNumber;
            final ZuoraObject.ZuoraAccount updatedAccount = new ZuoraObject.ZuoraAccount();
            updatedAccount.id = zuoraAccountId;
            if (creditCard) {
                updatedAccount.paymentTerm = 'Due Upon Receipt';
                updatedAccount.communicationProfileId =
                        Settings__c.getInstance().Zuora_Default_Communication_Profile_Id__c;
            } else {
                updatedAccount.paymentTerm =
                (paymentTerm == 'Net 45' || paymentTerm == 'Net 60') ? paymentTerm : 'Net 30';
                updatedAccount.communicationProfileId =
                        Settings__c.getInstance().Zuora_Invoice_Communication_Profile_Id__c;
            }
            if (paymentMethodIdUpdate) {
                updatedAccount.autoPay = creditCard;
                updatedAccount.defaultPaymentMethodId = newPaymentMethodId;
            }
            if (vatNumberUpdate) {
                updatedAccount.vatNumber = vatNumber;
            }
            if (billingInfo.taxExempt == true && String.isNotBlank(billingInfo.taxExemptCertificateId)) {
                updatedAccount.taxExemptStatus = 'Yes';
                updatedAccount.taxExemptCertificateID = billingInfo.taxExemptCertificateId;
            }
            if (billToId != billingContactId) {
                updatedAccount.billToId = billingContactId;
            }
            if (soldToId != billingContactId) {
                updatedAccount.soldToId = billingContactId;
            }
            if (String.isNotBlank(companyName) && !companyName.startsWith('Unknown <')) {
                updatedAccount.companyName = companyName;
            }
            final Boolean draftAccount = account.status == 'Draft';
            if (draftAccount && activationRequired) {
                updatedAccount.status = 'Active';
            }
            zuoraApi.updateObject(updatedAccount, 'Account');
        }
    }

    public void generateInvoice(final String zuoraAccountId, final Date invoiceDate, final Date targetDate) {
        log.infoToLog('Generate invoice... ' + zuoraAccountId,
                        ' Invoice Date: ' + String.valueOf(invoiceDate) +
                        ' Target Date: ' + String.valueOf(targetDate));
        try {
            final ZuoraObject.ZuoraInvoice invoice = new ZuoraObject.ZuoraInvoice();
            invoice.accountId = zuoraAccountId;
            invoice.invoiceDate = String.valueOf(invoiceDate);
            invoice.targetDate = String.valueOf(targetDate);
            final Map<String, Object> generateResult = zuoraApi.generate(invoice);
            final Boolean isSuccess = (Boolean)generateResult.get('Success');
            if (isSuccess) {
                final ZuoraObject.ZuoraInvoice postedInvoice = new ZuoraObject.ZuoraInvoice();
                postedInvoice.id = (String)generateResult.get('Id');
                postedInvoice.status = 'Posted';
                final String id = zuoraApi.updateObject(postedInvoice, 'Invoice');
                System.assertEquals(id, (String)generateResult.get('Id'));
            }
            log.infoToLog('Generate invoice... success: ' + isSuccess, 'Invoice id: ' + generateResult.get('Id'));
        } catch(Exception e) {
            log.errorToLog('Invoice generation error: ' + zuoraAccountId, e.getMessage());
        }
    }

    public BillingInfo findBillingInfo(final String zuoraAccountId) {
        final ZuoraObject.ZuoraAccount account = zuoraRestQuerySrv.findAccountSoldToIdAndVatNumber(zuoraAccountId);
        final BillingInfo billingInfo = new BillingInfo();
        if (account == null) {
            return billingInfo;
        }
        final String zuoraSoldToContactId = account.soldToId;
        final ZuoraObject.ZuoraContact billingContact = zuoraRestQuerySrv.findBillingContact(zuoraSoldToContactId, zuoraAccountId);
        if (billingContact == null) {
            return billingInfo;
        }
        billingInfo.firstName = billingContact.firstName;
        billingInfo.lastName = billingContact.lastName;
        billingInfo.email = billingContact.workEmail;
        final String countryFullName = billingContact.country;
        billingInfo.countryFullName = countryFullName;
        billingInfo.country = CountryUtil.findCountryCodeByValue(countryFullName);
        final String stateFullName = billingContact.state;
        billingInfo.stateFullName = stateFullName;
        billingInfo.state = CountryUtil.findStateCodeByValue(stateFullName);
        billingInfo.city = billingContact.city;
        billingInfo.address1 = billingContact.address1;
        billingInfo.address2 = billingContact.address2;
        billingInfo.zip = billingContact.postalCode;
        billingInfo.contactId = billingContact.id;
        billingInfo.vatNumber = account.vatNumber;
        return billingInfo;
    }
}
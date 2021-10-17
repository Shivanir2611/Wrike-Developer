public class BillToShipToService {

    public static BillToShipToService getInstance() {
        return (BillToShipToService)ServiceLocator.getInstance(BillToShipToService.class);
    }

    private final CPQQuoteQueryService quoteQuerySrv = CPQQuoteQueryService.getInstance();
    private final BillToShipToQueryService billToShipToQuerySrv = BillToShipToQueryService.getInstance();

    public BillToShipToForm findBillToShipToByQuoteId(final Id quoteId) {
        final SBQQ__Quote__c quote = quoteQuerySrv.findWithBillToShipToById(quoteId);
        final BillToShipToForm billToShipToForm = new BillToShipToForm();

        if (quote.QS_Bill_To__r != null) {
            billToShipToForm.billTo = quote.QS_Bill_To__r;
        } else if (quote.WrikeAccountId__c != null) {
            billToShipToForm.billTo =
                    billToShipToQuerySrv.findContact(quote.SBQQ__Account__c, quote.WrikeAccountId__c, 'Bill To');
        }
        if (billToShipToForm.billTo == null) {
            billToShipToForm.billTo = createBlankContact(quote.SBQQ__Account__c, quote.WrikeAccountId__c, 'Bill To');
        }

        if (quote.QS_Ship_To__r != null) {
            billToShipToForm.shipTo = quote.QS_Ship_To__r;
        } else if (quote.WrikeAccountId__c != null) {
            billToShipToForm.shipTo =
                    billToShipToQuerySrv.findContact(quote.SBQQ__Account__c, quote.WrikeAccountId__c, 'Ship To');
        }
        if (billToShipToForm.shipTo == null) {
            billToShipToForm.shipTo = createBlankContact(quote.SBQQ__Account__c, quote.WrikeAccountId__c, 'Ship To');
        }

        if (quote.ResellerAccount__c != null) {
            if (quote.EndCustomer__r != null) {
                billToShipToForm.endCustomer = quote.EndCustomer__r;
            } else if (quote.WrikeAccountId__c != null) {
                billToShipToForm.endCustomer =
                        billToShipToQuerySrv.findContact(quote.SBQQ__Account__c, quote.WrikeAccountId__c,
                                'End Customer');
            }
            if (billToShipToForm.endCustomer == null) {
                billToShipToForm.endCustomer =
                        createBlankContact(quote.SBQQ__Account__c, quote.WrikeAccountId__c, 'End Customer');
            }
        }
        return billToShipToForm;
    }

    public BillToShipToForm findBillToShipToByAccountId(final Id accountId) {
        final BillToShipToForm billToShipToForm = new BillToShipToForm();
        final QS_Bill_To_Ship_To__c billToContact = billToShipToQuerySrv.findLastContactByAccountId(accountId, true, false);
        billToShipToForm.billTo = billToContact == null
                                  ? createBlankContact(accountId, null, 'Bill To')
                                  : billToContact;
        final QS_Bill_To_Ship_To__c shipToContact = billToShipToQuerySrv.findLastContactByAccountId(accountId, false, true);
        billToShipToForm.shipTo = shipToContact == null
                                  ? createBlankContact(accountId, null, 'Ship To')
                                  : shipToContact;
        return billToShipToForm;
    }

    public Id upsertContact(final QS_Bill_To_Ship_To__c contact) {
        return Database.upsert(contact).getId();
    }

    public void updateWrikeAccountId(final Id contactId, final Decimal wrikeAccountId) {
        update new QS_Bill_To_Ship_To__c(
                Id = contactId,
                Wrike_Account_ID__c = wrikeAccountId
        );
    }

    public Id getPartnerContactId(final QS_Bill_To_Ship_To__c quoteContact,
                                  final Id partnerAccountId,
                                  final Id customerAccountId,
                                  final Boolean billTo,
                                  final Boolean shipTo) {
        final QS_Bill_To_Ship_To__c partnerContact =
                billToShipToQuerySrv.findLastContactByAccountId(partnerAccountId, billTo, shipTo);
        if (partnerContact != null) {
            if (quoteContact != null && quoteContact.PartnerAccount__c == partnerAccountId) {
                update cloneContactFromPartner(quoteContact.Id, partnerContact, partnerAccountId, customerAccountId);
                return quoteContact.Id;
            } else {
                final QS_Bill_To_Ship_To__c connectedPartnerContact =
                        billToShipToQuerySrv.findContactByAccountIdAndPartnerAccountId(customerAccountId,
                                partnerAccountId, billTo, shipTo);
                final QS_Bill_To_Ship_To__c clonedContact =
                        cloneContactFromPartner(null, partnerContact, partnerAccountId, customerAccountId);
                if (connectedPartnerContact != null) {
                    clonedContact.Id = connectedPartnerContact.Id;
                    update clonedContact;
                } else {
                    insert clonedContact;
                }
                return clonedContact.Id;
            }
        }
        return null;
    }

    private QS_Bill_To_Ship_To__c cloneContactFromPartner(final Id contactId,
                                                          final QS_Bill_To_Ship_To__c partnerContact,
                                                          final Id partnerAccountId,
                                                          final Id customerAccountId) {
        final QS_Bill_To_Ship_To__c clonedContact = partnerContact.clone();
        clonedContact.Id = contactId;
        clonedContact.QS_Account__c = customerAccountId;
        clonedContact.PartnerAccount__c = partnerAccountId;
        return clonedContact;
    }

    private QS_Bill_To_Ship_To__c createBlankContact(final Id accountId,
                                                     final Decimal wrikeAccountId,
                                                     final String type) {
        final Boolean billTo = 'Bill To'.equalsIgnoreCase(type);
        final Boolean shipTo = 'Ship To'.equalsIgnoreCase(type);
        final Boolean endCustomer = 'End Customer'.equalsIgnoreCase(type);
        return new QS_Bill_To_Ship_To__c(
                QS_Account__c = accountId,
                Wrike_Account_ID__c = wrikeAccountId,
                QS_Bill_To__c = billTo,
                QS_Ship_To__c = shipTo,
                EndCustomer__c = endCustomer,
                QS_Invoice_via_Email__c = billTo
        );
    }
}
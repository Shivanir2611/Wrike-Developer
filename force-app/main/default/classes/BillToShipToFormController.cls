public with sharing class BillToShipToFormController {

    private final static CPQQuoteService quoteSrv = CPQQuoteService.getInstance();
    private final static BillToShipToService billToShipToSrv = BillToShipToService.getInstance();

    @AuraEnabled
    public static BillToShipToForm getFormByQuoteId(final String quoteId) {
        return billToShipToSrv.findBillToShipToByQuoteId(quoteId);
    }

    @AuraEnabled
    public static BillToShipToForm getFormByAccountId(final Id accountId) {
        return billToShipToSrv.findBillToShipToByAccountId(accountId);
    }

    @AuraEnabled
    public static void saveContacts(final Id quoteId,
                                    final QS_Bill_To_Ship_To__c billTo,
                                    final QS_Bill_To_Ship_To__c shipTo,
                                    final QS_Bill_To_Ship_To__c endCustomer) {
        System.assert(EmailUtil.isValidEmail(billTo.QS_Email__c), 'Bill To email is invalid: ' + billTo.QS_Email__c);
        System.assert(EmailUtil.isValidEmail(shipTo.QS_Email__c), 'Ship To email is invalid: ' + shipTo.QS_Email__c);

        final Id billToId = billToShipToSrv.upsertContact(billTo);
        final Id shipToId = billToShipToSrv.upsertContact(shipTo);
        final Id endCustomerId = endCustomer == null
                                 ? null
                                 : billToShipToSrv.upsertContact(endCustomer);
        if (quoteId != null) {
            quoteSrv.updateBillToShipTo(quoteId, billToId, shipToId, endCustomerId);
        }
    }
}
public class DocuSignStatusTriggerHandler {

    public static DocuSignStatusTriggerHandler getInstance() {
        return (DocuSignStatusTriggerHandler)ServiceLocator.getInstance(DocuSignStatusTriggerHandler.class);
    }

    private static Map<String, String> quoteStatusByDocuSignStatus = new Map<String, String> {
            'Completed' => CPQQuote.DocuSignSigned,
            'Declined' => CPQQuote.DocuSignDeclined,
            'Voided' => CPQQuote.DocumentGenerated
    };

    public void afterInsert(final List<dsfs__DocuSign_Status__c> statuses) {
        final List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for (dsfs__DocuSign_Status__c status : statuses) {
            if (status.Quote__c != null) {
                quotes.add(new SBQQ__Quote__c(
                        Id = status.Quote__c,
                        DocuSignStatus__c = status.Id
                ));
            }
        }
        if (!quotes.isEmpty()) {
            update quotes;
        }
    }

    public void afterUpdate(final Map<Id, dsfs__DocuSign_Status__c> oldMap, final Map<Id, dsfs__DocuSign_Status__c> newMap) {
        final List<dsfs__DocuSign_Status__c> statuses = newMap.values();
        final Map<Id, String> quoteIdStatusMap = new Map<Id, String>();
        for (dsfs__DocuSign_Status__c status : statuses) {
            final dsfs__DocuSign_Status__c oldStatus = oldMap.get(status.Id);
            if (status.Quote__c != null && isStatusChanged(status, oldStatus)) {
                quoteIdStatusMap.put(status.Quote__c, status.dsfs__Envelope_Status__c);
            }
        }
        final List<SBQQ__Quote__c> quotes = [
                SELECT Id, SBQQ__Status__c
                FROM SBQQ__Quote__c
                WHERE Id IN :quoteIdStatusMap.keySet()
        ];
        final List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : quotes) {
            if (CPQQuote.DocuSignSent.equals(quote.SBQQ__Status__c)) {
                final String status = quoteIdStatusMap.get(quote.Id);
                quotesToUpdate.add(new SBQQ__Quote__c(
                        Id = quote.Id,
                        SBQQ__Status__c = quoteStatusByDocuSignStatus.get(status)
                ));
            }
        }
        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }

    private Boolean isStatusChanged(final dsfs__DocuSign_Status__c status,
                                    final dsfs__DocuSign_Status__c oldStatus) {
        return (status.dsfs__Envelope_Status__c == 'Completed'
                || status.dsfs__Envelope_Status__c == 'Declined'
                || status.dsfs__Envelope_Status__c == 'Voided')
                && oldStatus.dsfs__Envelope_Status__c != status.dsfs__Envelope_Status__c;
    }
}
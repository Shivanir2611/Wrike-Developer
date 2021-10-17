public class DocuSignEnvelopeTriggerHandler {

    public static DocuSignEnvelopeTriggerHandler getInstance() {
        return (DocuSignEnvelopeTriggerHandler)ServiceLocator.getInstance(DocuSignEnvelopeTriggerHandler.class);
    }

    public void afterUpdate(final Map<Id, dsfs__DocuSign_Envelope__c> oldMap, final Map<Id, dsfs__DocuSign_Envelope__c> newMap) {
        final List<dsfs__DocuSign_Envelope__c> envelopes = newMap.values();
        final List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for (dsfs__DocuSign_Envelope__c envelope : envelopes) {
            final dsfs__DocuSign_Envelope__c oldEnvelope = oldMap.get(envelope.Id);
            if (envelope.dsfs__Source_Object__c != null
                    && Id.valueOf(envelope.dsfs__Source_Object__c).getSobjectType() == SBQQ__Quote__c.getSObjectType()
                    && oldEnvelope.dsfs__DocuSign_Envelope_Sent__c == null
                    && envelope.dsfs__DocuSign_Envelope_Sent__c != null) {
                quotes.add(new SBQQ__Quote__c(
                        Id = envelope.dsfs__Source_Object__c,
                        SBQQ__Status__c = CPQQuote.DocuSignSent,
                        DocuSignEnvelope__c = envelope.Id
                ));
            }
        }
        if (!quotes.isEmpty()) {
            update quotes;
        }
    }
}
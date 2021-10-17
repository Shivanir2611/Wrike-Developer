/*
 * Created by sofia.kanukova on 05/09/2019.
 */
public class QuoteDocuSignMatchingJob implements Database.Batchable<SObject>, Schedulable {

	public void execute(final SchedulableContext context) {
		Database.executeBatch(this);
	}

	public Database.QueryLocator start(final Database.BatchableContext context) {
		return Database.getQueryLocator([
				SELECT Id, Pdf_Id__c
				FROM Quote__c
				WHERE Pdf_Id__c != NULL
				AND CompletedDocuSign__c = NULL
		]);
	}

	public void execute(final Database.BatchableContext context, final List<Quote__c> quotes) {
		final Map<String, Quote__c> quoteByAttachmentId = new Map<String, Quote__c>();
		for (Quote__c quote : quotes) {
			quoteByAttachmentId.put(quote.Pdf_Id__c, quote);
		}

		final List<dsfs__DocuSign_Envelope_Document__c> docs = [
				SELECT dsfs__DocuSign_EnvelopeID__r.dsfs__DocuSign_Envelope_ID__c, dsfs__Attachment_ID__c
				FROM dsfs__DocuSign_Envelope_Document__c
				WHERE dsfs__Attachment_ID__c in :quoteByAttachmentId.keySet()
				AND dsfs__DocuSign_EnvelopeID__r.dsfs__DocuSign_Envelope_ID__c != NULL
		];

		Map<String, String> attachmentIdByEnvelopeId = new Map<String, String>();

		for (dsfs__DocuSign_Envelope_Document__c doc : docs) {
			attachmentIdByEnvelopeId.put(doc.dsfs__DocuSign_EnvelopeID__r.dsfs__DocuSign_Envelope_ID__c.toUpperCase(),
					doc.dsfs__Attachment_ID__c);
		}

		final List<dsfs__DocuSign_Status__c> statuses = [
				SELECT Id, dsfs__DocuSign_Envelope_ID__c
				FROM dsfs__DocuSign_Status__c
				WHERE dsfs__DocuSign_Envelope_ID__c IN :attachmentIdByEnvelopeId.keySet()
				AND dsfs__Envelope_Status__c = 'Completed'
				ORDER BY CreatedDate ASC
		];

		Map<Id, Quote__c> quotesToUpdate = new Map<Id, Quote__c>();
		for (dsfs__DocuSign_Status__c status : statuses) {
			final String attachmentId = attachmentIdByEnvelopeId.get(status.dsfs__DocuSign_Envelope_ID__c.toUpperCase());
			Quote__c quote = quoteByAttachmentId.get(attachmentId);
			quote.CompletedDocuSign__c = status.Id;
			quotesToUpdate.put(quote.Id, quote);
		}
		update quotesToUpdate.values();
	}

	public void finish(final Database.BatchableContext context) {}
}
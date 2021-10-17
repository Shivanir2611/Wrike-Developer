/*
 * Created by sofia.kanukova on 05/09/2019.
 */
@IsTest
public class QuoteDocuSignMatchingJobTest {

	@IsTest
	static void testUpdateQuotesWithCompletedStatus() {
		final Quote__c quote = createAndInsertQuote();
		final dsfs__DocuSign_Envelope__c envelope = createAndInsertEnvelope();
		createAndInsertDocument(quote.Pdf_Id__c, envelope.Id);
		final dsfs__DocuSign_Status__c status = createAndInsertStatus(envelope.Id, 'Completed');

		Test.startTest();
		Database.executeBatch(new QuoteDocuSignMatchingJob());
		Test.stopTest();

		Quote__c updatedQuote = findQuote(quote.Id);

		System.assertEquals(status.Id, updatedQuote.CompletedDocuSign__c);
	}

	@IsTest
	static void testUpdateQuotesWithDeclinedStatus() {
		final Quote__c quote = createAndInsertQuote();
		final dsfs__DocuSign_Envelope__c envelope = createAndInsertEnvelope();
		createAndInsertDocument(quote.Pdf_Id__c, envelope.Id);
		final dsfs__DocuSign_Status__c status = createAndInsertStatus(envelope.Id, 'Declined');

		Test.startTest();
		Database.executeBatch(new QuoteDocuSignMatchingJob());
		Test.stopTest();

		Quote__c updatedQuote = findQuote(quote.Id);

		System.assertEquals(null, updatedQuote.CompletedDocuSign__c);
	}

	@IsTest
	static void testUpdateQuotesWithSeveralStatuses() {
		final Quote__c quote = createAndInsertQuote();
		final dsfs__DocuSign_Envelope__c envelope1 = createAndInsertEnvelope();
		createAndInsertDocument(quote.Pdf_Id__c, envelope1.Id);
		final dsfs__DocuSign_Envelope__c envelope2 = createAndInsertEnvelope();
		createAndInsertDocument(quote.Pdf_Id__c, envelope2.Id);

		createAndInsertStatus(envelope1.Id, 'Completed');
		createAndInsertStatus(envelope2.Id, 'Completed');
		final dsfs__DocuSign_Status__c lastInsertedStatus = createAndInsertStatus(envelope2.Id, 'Completed');

		Test.startTest();
		Database.executeBatch(new QuoteDocuSignMatchingJob());
		Test.stopTest();

		Quote__c updatedQuote = findQuote(quote.Id);

		System.assertEquals(lastInsertedStatus.Id, updatedQuote.CompletedDocuSign__c);
	}

	private static Quote__c createAndInsertQuote() {
		Account account = TestDataFactory.createAccount();
		TestUtils.insertAndAssert(account);

		Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 100);
		TestUtils.insertAndAssert(opportunity);

		final Quote__c quote = new Quote__c();
		quote.Opportunity__c = opportunity.Id;
		TestUtils.insertAndAssert(quote);

		final Attachment pdf = new Attachment();
		pdf.ParentId = quote.Id;
		pdf.Body = EncodingUtil.base64Decode('a');
		pdf.Name = 'a';
		TestUtils.insertAndAssert(pdf);

		quote.Pdf_Id__c = pdf.Id;
		TestUtils.updateAndAssert(quote);

		return quote;
	}

	private static dsfs__DocuSign_Envelope__c createAndInsertEnvelope() {
		dsfs__DocuSign_Envelope__c envelope = new dsfs__DocuSign_Envelope__c();
		TestUtils.insertAndAssert(envelope);
		envelope.dsfs__DocuSign_Envelope_ID__c = envelope.Id;
		TestUtils.updateAndAssert(envelope);
		return envelope;
	}

	private static dsfs__DocuSign_Envelope_Document__c createAndInsertDocument(Id attachmentId, Id envelopeId) {
		dsfs__DocuSign_Envelope_Document__c doc = new dsfs__DocuSign_Envelope_Document__c();
		doc.dsfs__Attachment_ID__c = attachmentId;
		doc.dsfs__DocuSign_EnvelopeID__c = envelopeId;
		TestUtils.insertAndAssert(doc);
		return doc;
	}

	private static dsfs__DocuSign_Status__c createAndInsertStatus(Id envelopeId, String envelopeStatus) {
		dsfs__DocuSign_Status__c status = new dsfs__DocuSign_Status__c();
		status.dsfs__DocuSign_Envelope_ID__c = envelopeId;
		status.dsfs__Envelope_Status__c = envelopeStatus;
		TestUtils.insertAndAssert(status);
		return status;
	}

	private static Quote__c findQuote(final Id quoteId) {
		return [
				SELECT Id, CompletedDocuSign__c
				FROM Quote__c
				WHERE Id = :quoteId
		];
	}
}
@IsTest
private class OpportunityWrikeQuotesControllerTest {

    @TestSetup
    static void setup() {
        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 1000);
        TestUtils.insertAndAssert(testOpportunity);
    }

    @IsTest
    static void testGetEmptyWrikeQuotesWithDocuSign() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities.get(0));
        OpportunityWrikeQuotesController wrikeQuotesController = new OpportunityWrikeQuotesController(standardController);

        System.assertEquals(0, wrikeQuotesController.getWrikeQuotesWithDocuSign().size());
    }

    @IsTest
    static void testWrikeQuotesWithSignedFile() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote = TestDataFactory.createQuote(opportunities.get(0).Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(subscriptionQuote);

        Attachment pdf = TestDataFactory.createAttachment(subscriptionQuote.Id);
        TestUtils.insertAndAssert(pdf);

        subscriptionQuote.Pdf_Id__c = pdf.Id;
        TestUtils.updateAndAssert(subscriptionQuote);

        final dsfs__DocuSign_Status__c docuSignStatus = TestDataFactory.createDocuSignStatus(subscriptionQuote.Id, 'Completed');
        TestUtils.insertAndAssert(docuSignStatus);

        final Id documentId = TestDataFactory.createFile(docuSignStatus.Id, subscriptionQuote.Name + '.pdf');

        final OpportunityWrikeQuotesController controller = new OpportunityWrikeQuotesController(new ApexPages.StandardController(opportunities.get(0)));

        System.assertEquals(1, controller.getWrikeQuotesWithDocuSign().size());
        System.assertEquals(12, controller.getWrikeQuotesWithDocuSign().get(0).newTerm);
        System.assertEquals('Completed', controller.getWrikeQuotesWithDocuSign().get(0).docuSignEnvelopeStatus);
        System.assertEquals(pdf.Id, controller.getWrikeQuotesWithDocuSign().get(0).pdfId);
        System.assertEquals(documentId, controller.getWrikeQuotesWithDocuSign().get(0).signedPdfId);
    }

    @IsTest
    static void testGet1WrikeQuotesWithDocuSign() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote = TestDataFactory.createQuote(opportunities.get(0).Id, 12, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(subscriptionQuote);

        Attachment pdf = TestDataFactory.createAttachment(subscriptionQuote.Id);
        TestUtils.insertAndAssert(pdf);

        subscriptionQuote.Pdf_Id__c = pdf.Id;
        TestUtils.updateAndAssert(subscriptionQuote);

        dsfs__DocuSign_Status__c docuSignStatus = TestDataFactory.createDocuSignStatus(subscriptionQuote.Id, 'Completed');
        TestUtils.insertAndAssert(docuSignStatus);

        Attachment signedPdf = TestDataFactory.createAttachment(docuSignStatus.Id);
        TestUtils.insertAndAssert(signedPdf);

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities.get(0));
        OpportunityWrikeQuotesController wrikeQuotesController = new OpportunityWrikeQuotesController(standardController);

        System.assertEquals(1, wrikeQuotesController.getWrikeQuotesWithDocuSign().size());
        System.assertEquals(12, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(0).newTerm);
        System.assertEquals('Completed', wrikeQuotesController.getWrikeQuotesWithDocuSign().get(0).docuSignEnvelopeStatus);
        System.assertEquals(pdf.Id, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(0).pdfId);
        System.assertEquals(signedPdf.Id, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(0).signedPdfId);
    }

    @IsTest
    static void testGet3WrikeQuotesWithDocuSign() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Quote__c subscriptionQuote1 = TestDataFactory.createQuote(opportunities.get(0).Id, 1, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(subscriptionQuote1);

        Attachment pdf1 = TestDataFactory.createAttachment(subscriptionQuote1.Id);
        TestUtils.insertAndAssert(pdf1);

        subscriptionQuote1.Pdf_Id__c = pdf1.Id;
        TestUtils.updateAndAssert(subscriptionQuote1);

        dsfs__DocuSign_Status__c docuSignStatus1 = TestDataFactory.createDocuSignStatus(subscriptionQuote1.Id, 'Completed');
        TestUtils.insertAndAssert(docuSignStatus1);

        Attachment signedPdf = TestDataFactory.createAttachment(docuSignStatus1.Id);
        TestUtils.insertAndAssert(signedPdf);

        Quote__c subscriptionQuote2 = TestDataFactory.createQuote(opportunities.get(0).Id, 2, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(subscriptionQuote2);

        Attachment pdf2 = TestDataFactory.createAttachment(subscriptionQuote2.Id);
        TestUtils.insertAndAssert(pdf2);

        subscriptionQuote2.Pdf_Id__c = pdf2.Id;
        TestUtils.updateAndAssert(subscriptionQuote2);

        dsfs__DocuSign_Status__c docuSignStatus2 = TestDataFactory.createDocuSignStatus(subscriptionQuote2.Id, 'Sent');
        TestUtils.insertAndAssert(docuSignStatus2);

        Quote__c subscriptionQuote3 = TestDataFactory.createQuote(opportunities.get(0).Id, 3, WrikeQuote.QuoteType.SUBSCRIPTION, null);
        TestUtils.insertAndAssert(subscriptionQuote3);

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities.get(0));
        OpportunityWrikeQuotesController wrikeQuotesController = new OpportunityWrikeQuotesController(standardController);

        System.assertEquals(3, wrikeQuotesController.getWrikeQuotesWithDocuSign().size());
        System.assertEquals(1, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(0).newTerm);
        System.assertEquals(2, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(1).newTerm);
        System.assertEquals(3, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(2).newTerm);
        System.assertEquals('Completed', wrikeQuotesController.getWrikeQuotesWithDocuSign().get(0).docuSignEnvelopeStatus);
        System.assertEquals('Sent', wrikeQuotesController.getWrikeQuotesWithDocuSign().get(1).docuSignEnvelopeStatus);
        System.assertEquals(null, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(2).docuSignEnvelopeStatus);
        System.assertEquals(pdf1.Id, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(0).pdfId);
        System.assertEquals(pdf2.Id, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(1).pdfId);
        System.assertEquals(null, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(2).pdfId);
        System.assertEquals(signedPdf.Id, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(0).signedPdfId);
        System.assertEquals(null, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(1).signedPdfId);
        System.assertEquals(null, wrikeQuotesController.getWrikeQuotesWithDocuSign().get(2).signedPdfId);
    }
}
@IsTest
private class WrikeQuoteEmailControllerTest {

    @IsTest
    static void testMain() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 100);
        TestUtils.insertAndAssert(testOpportunity);

        Contact testContact = TestDataFactory.createContact(testAccount.Id);
        TestUtils.insertAndAssert(testContact);

        OpportunityContactRole testOpportunityContactRole =
            TestDataFactory.createOpportunityContactRole(testContact.Id, testOpportunity.Id);
        TestUtils.insertAndAssert(testOpportunityContactRole);

        Attachment pdf = TestDataFactory.createAttachment(testOpportunity.Id);
        TestUtils.insertAndAssert(pdf);

        Quote__c wQuote = TestDataFactory.insertDraftAmendmentQuote(testOpportunity.Id);
        wQuote.Pdf_Id__c = pdf.Id;
        TestUtils.updateAndAssert(wQuote);

        ApexPages.currentPage().getParameters().put('contactId', testContact.Id);
        ApexPages.currentPage().getParameters().put('attachId', pdf.Id);

        Test.startTest();

        ApexPages.StandardController standardController =  new ApexPages.StandardController(wQuote);
        WrikeQuoteEmailController emailController = new WrikeQuoteEmailController(standardController);
        System.assertEquals(wQuote.Id, emailController.getQuote().Id);

        QuoteEmailComponentController emailComponentController = new QuoteEmailComponentController();
        emailComponentController.pageController = emailController;

        emailComponentController.back();

        List<Attachment> attachments = emailComponentController.getAttachments();
        System.assertEquals(1, attachments.size());

        List<Contact> quoteContacts = emailComponentController.getContacts();
        System.assertEquals(1, quoteContacts.size());
        System.assertEquals(testContact.Id, quoteContacts.get(0).Id);

        emailComponentController.selectedContact = null;
        emailComponentController.selectContact();
        Contact selectedContact = emailComponentController.getSelectedContact();
        System.assertEquals(testContact.Id, selectedContact.Id);

        emailComponentController.send();

        emailComponentController.removeAttachment();
        attachments = emailComponentController.getAttachments();
        System.assertEquals(0, attachments.size());

        Test.stopTest();
    }
}
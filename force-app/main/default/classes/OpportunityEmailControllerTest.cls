@IsTest
private class OpportunityEmailControllerTest {

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

        ApexPages.currentPage().getParameters().put('contactId', testContact.Id);
        ApexPages.currentPage().getParameters().put('attachId', pdf.Id);

        Test.startTest();

        ApexPages.StandardController standardController =  new ApexPages.StandardController(testOpportunity);
        OpportunityEmailController emailController = new OpportunityEmailController(standardController);

        QuoteEmailComponentController emailComponentController = new QuoteEmailComponentController();
        emailComponentController.pageController = emailController;

        emailComponentController.back();

        List<Attachment> attachments = emailComponentController.getAttachments();
        System.assertEquals(1, attachments.size());

        List<Contact> quoteContacts = emailComponentController.getContacts();
        System.assertEquals(1, quoteContacts.size());
        System.assertEquals(testContact.Id, quoteContacts.get(0).Id);

        Contact selectedContact = emailComponentController.getSelectedContact();
        System.assertEquals(testContact.Id, selectedContact.Id);

        emailComponentController.send();

        emailComponentController.selectedContact = null;
        emailComponentController.selectContact();

        emailComponentController.removeAttachment();
        attachments = emailComponentController.getAttachments();
        System.assertEquals(0, attachments.size());

        Test.stopTest();
    }
}
@IsTest
private class OpportunityVatNumberControllerTest {

    private static final Logger log = Logger.create(OpportunityVatNumberControllerTest.class);

    @testSetup
    static void setup() {
        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Contact testContact = TestDataFactory.createContact(testAccount.Id);
        TestUtils.insertAndAssert(testContact);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, testContact.Id);
        TestUtils.insertAndAssert(testOpportunity);
    }

    @IsTest
    static void billingInfoFromFromContactTest() {
        List<Contact> contacts = TestUtils.getContacts();
        System.assertEquals(1, contacts.size());

        contacts[0].MailingCountryCode = 'IE';
        contacts[0].MailingCountry = 'Ireland';
        TestUtils.updateAndAssert(contacts[0]);

        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Test.setMock(WebServiceMock.class, new CheckVatMock());
        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities[0]);
        OpportunityVatNumberController vatController = new OpportunityVatNumberController(standardController);
        vatController.getCountries();
        vatController.goToBillingAddressForm();
        vatController.cancel();

        vatController.billingAddress.vatNumber = '123';
        PageReference sumbitRedirect = vatController.submit();
        System.assertEquals(null, sumbitRedirect, 'Vat should be invalid.');

        vatController.billingAddress.vatNumber = 'IE123';
        sumbitRedirect = vatController.submit();
        System.assertNotEquals(null, sumbitRedirect, 'Vat should be valid.');
        
        Test.stopTest();
    }

    @IsTest
    static void billingInfoFromFromContactNonEUTest() {
        List<Contact> contacts = TestUtils.getContacts();
        System.assertEquals(1, contacts.size());

        contacts[0].MailingCountryCode = 'US';
        contacts[0].MailingCountry = 'United States';
        TestUtils.updateAndAssert(contacts[0]);

        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Test.setMock(WebServiceMock.class, new CheckVatMock());
        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities[0]);
        OpportunityVatNumberController vatController = new OpportunityVatNumberController(standardController);

        vatController.billingAddress.vatNumber = '123';
        PageReference sumbitRedirect = vatController.submit();
        System.assertEquals(null, sumbitRedirect, 'Non EU country.');

        Test.stopTest();
    }

    @IsTest
    static void contactWithoutBillingInfoTest() {
        List<Contact> contacts = TestUtils.getContacts();
        System.assertEquals(1, contacts.size());

        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        opportunities[0].Billing_Contact__c = null;
        TestUtils.updateAndAssert(opportunities[0]);

        Test.setMock(WebServiceMock.class, new CheckVatMock());
        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities[0]);
        OpportunityVatNumberController vatController = new OpportunityVatNumberController(standardController);

        vatController.billingAddress.vatNumber = 'IE123';
        PageReference sumbitRedirect = vatController.submit();
        System.assertEquals(null, sumbitRedirect, 'Country is empty.');

        vatController.billingAddress.country = 'IE';
        sumbitRedirect = vatController.submit();
        System.assertNotEquals(null, sumbitRedirect, 'Vat should be valid.');

        Test.stopTest();
    }

    @IsTest
    static void contactWithoutBillingInfoServiceNotAvalibleTest() {
        List<Contact> contacts = TestUtils.getContacts();
        System.assertEquals(1, contacts.size());

        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Test.setMock(WebServiceMock.class, new CheckVatMock());
        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities[0]);
        OpportunityVatNumberController vatController = new OpportunityVatNumberController(standardController);

        vatController.billingAddress.vatNumber = 'exception';
        vatController.billingAddress.country = 'IE';
        PageReference sumbitRedirect = vatController.submit();
        System.assertNotEquals(null, sumbitRedirect, 'Vat is invalid, but service should be unavalible.');

        Test.stopTest();
    }
}
@IsTest
private class OpportunityBillingAddressControllerTest {

    @testSetup
    static void setup() {
        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Contact testContact = TestDataFactory.createContact(testAccount.Id);
        testContact.MailingCountryCode = 'IE';
        testContact.MailingCountry = 'Ireland';
        testContact.MailingCity = 'City';
        testContact.MailingStreet = 'Street';
        testContact.MailingPostalCode = '000000';
        TestUtils.insertAndAssert(testContact);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, testContact.Id);
        TestUtils.insertAndAssert(testOpportunity);

        OpportunityContactRole testOpportunityContactRole =
            TestDataFactory.createOpportunityContactRole(testContact.Id, testOpportunity.Id);
        TestUtils.insertAndAssert(testOpportunityContactRole);
    }

    @IsTest
    static void billingInfoFromFromContactTest() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Test.setMock(WebServiceMock.class, new CheckVatMock());
        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities[0]);
        OpportunityBillingAddressController addressController = new OpportunityBillingAddressController(standardController);
        addressController.getCountries();
        addressController.getStates();
        addressController.back();

        BillingInfo billingInfo = addressController.getBillingAddress();
        System.assert(addressController.getPopulated(), 'Billing info should be populated.');

        billingInfo.vatNumber = '123';
        System.assertEquals(null, addressController.save(), 'Vat should be invalid.');
        billingInfo.vatNumber = 'IE123';
        System.assertNotEquals(null, addressController.save(), 'Vat should be valid.');
        Test.stopTest();
    }

    @IsTest
    static void opportunityWithoutBillingContactTest() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        opportunities[0].Billing_Contact__c = null;
        TestUtils.updateAndAssert(opportunities[0]);

        List<OpportunityContactRole> opportunityContactRoles = TestUtils.getOpportunityContactRoles();
        TestUtils.deleteAndAssert(opportunityContactRoles);

        Test.setMock(WebServiceMock.class, new CheckVatMock());
        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities[0]);
        OpportunityBillingAddressController addressController = new OpportunityBillingAddressController(standardController);


        BillingInfo billingInfo = addressController.getBillingAddress();
        billingInfo.firstName = TestDataFactory.TEST_NAME;
        billingInfo.lastName = TestDataFactory.TEST_NAME;
        billingInfo.email = TestDataFactory.TEST_EMAIL;
        billingInfo.country = 'IE';
        billingInfo.countryFullName = 'Ireland';
        billingInfo.city = 'City';
        billingInfo.address1 = 'Street';
        billingInfo.zip = '000000';
        System.assert(addressController.getPopulated(), 'Billing info should be populated.');
        System.assertNotEquals(null, addressController.save(), 'All data should be valid.');

        Test.stopTest();
    }

}
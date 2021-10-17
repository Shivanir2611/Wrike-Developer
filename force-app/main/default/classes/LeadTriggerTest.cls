@IsTest
public class LeadTriggerTest {

    @IsTest
    static void testActivityDataCreated() {
        final Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                CountryCode = 'US'
        );
        insert lead;
        System.assert([SELECT Activity_Data__c FROM Lead WHERE Id = :lead.Id].Activity_Data__c != null, 'Activity data was not created.');
    }

    @IsTest
    static void testUnrecycledLeadActivityDataCreated() {
        final Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                CountryCode = 'US',
                Status = LeadService.RECYCLE_STATUS,
                Recycle_Reasons__c = 'Recycle Workflow',
                Follow_Up_Timeframe__c = '15 Days',
                OwnerId = WrikeConstants.RLQ_ID
        );
        insert lead;
        lead.Activity_Data__c = null;
        update lead;
        lead.Status = 'Open';
        lead.OwnerId = WrikeConstants.GLQ_ID;
        update lead;
        System.assert([SELECT Activity_Data__c FROM Lead WHERE Id = :lead.Id].Activity_Data__c != null, 'Activity data was not created.');
    }

    @IsTest
    static void testOriginalLeadSource() {
        final Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Mobile',
                Lead_Sub_Source__c = 'Android',
                CountryCode = 'US'
        );
        insert lead;
        final Lead createdLead = [SELECT Original_Lead_Source__c FROM Lead WHERE Id = :lead.Id][0];
        System.assertEquals('Mobile', createdLead.Original_Lead_Source__c, 'Original lead source was not set.');
        update new Lead(Id = lead.Id, LeadSource = 'Web');
        final Lead updatedLead = [SELECT Original_Lead_Source__c FROM Lead WHERE Id = :lead.Id][0];
        System.assertEquals('Mobile', createdLead.Original_Lead_Source__c, 'Original lead source should not be changed.');
    }

    @IsTest
    static void testNewLead() {
        final Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                CountryCode = 'US'
        );

        Test.startTest();
        insert lead;
        Test.stopTest();

        final Lead createdLead = [
                SELECT CountryCode__c, Region__c
                FROM Lead
                WHERE Id = :lead.Id
        ];
        System.assertEquals('US', createdLead.CountryCode__c);
        System.assertEquals('North America', createdLead.Region__c);
    }

    @IsTest
    static void testCountryCodeUpdate() {
        final Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            LeadSource = 'Web',
            Lead_Sub_Source__c = 'Web'
        );
        insert lead;

        Test.startTest();
        update new Lead(
            Id = lead.Id,
            CountryCode = 'US'
        );
        Test.stopTest();

        final Lead updatedLead = [
            SELECT CountryCode__c, Region__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals('US', updatedLead.CountryCode__c);
        System.assertEquals('North America', updatedLead.Region__c);
    }

    @IsTest
    static void testCustomCountryCodePopulated() {
        final Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            LeadSource = 'Web',
            Lead_Sub_Source__c = 'Web',
            Country = 'France'
        );
        insert lead;

        final Lead createdLead = [
            SELECT CountryCode__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals('FR', createdLead.CountryCode__c);
    }

    @IsTest
    static void testCountryUpdate() {
        final Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            LeadSource = 'Web',
            Lead_Sub_Source__c = 'Web'
        );
        insert lead;

        Test.startTest();
        update new Lead(
            Id = lead.Id,
            Country = 'France'
        );
        Test.stopTest();

        final Lead updatedLead = [
            SELECT CountryCode__c, Region__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        System.assertEquals('FR', updatedLead.CountryCode__c);
    }

    @IsTest
    static void testWrikeDataChanged() {
        final WrikeData__c wrikeData1 = new WrikeData__c(
                Wrike_Account_Id__c = 1
        );
        final WrikeData__c wrikeData2 = new WrikeData__c(
                Wrike_Account_Id__c = 2
        );
        insert wrikeData1;
        insert wrikeData2;
        final Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                Wrike_Account_Id__c = 1,
                Wrike_Data__c = wrikeData1.Id
        );
        insert lead;

        Test.startTest();
        lead.Wrike_Account_Id__c = 2;
        update lead;
        Test.stopTest();

        final Lead updatedLead = [
                SELECT Wrike_Data__c
                FROM Lead
                WHERE Id = :lead.Id
        ];
        System.assertEquals(wrikeData2.Id, updatedLead.Wrike_Data__c, 'WrikeData was not updated for new wrike account id');
    }

    @IsTest
    static void testUpdatedWithExistingWrikeData() {
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = 1
        );
        insert wrikeData;
        final Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook'
        );
        insert lead;

        Test.startTest();
        lead.Wrike_Account_Id__c = 1;
        update lead;
        Test.stopTest();

        final Lead updatedLead = [
                SELECT Wrike_Data__c
                FROM Lead
                WHERE Id = :lead.Id
        ];
        System.assertEquals(wrikeData.Id, updatedLead.Wrike_Data__c, 'WrikeData should be set');
    }

    @IsTest
    static void testWrikeDataCreated() {
        final Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook'
        );
        insert lead;

        Test.startTest();
        lead.Wrike_Account_Id__c = 1;
        update lead;
        Test.stopTest();

        final Lead updatedLead = [
                SELECT Wrike_Data__r.Wrike_Account_Id__c
                FROM Lead
                WHERE Id = :lead.Id
        ];
        System.assert(updatedLead.Wrike_Data__r != null, 'WrikeData should be created.');
        System.assertEquals(1, updatedLead.Wrike_Data__r.Wrike_Account_Id__c, 'Wrike Account Id of Wrike Data is not valid.');
    }

    @IsTest
    static void testWrikeDataRemoved() {
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = 1
        );
        insert wrikeData;
        final Lead lead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                Wrike_Account_Id__c = 1,
                Wrike_Data__c = wrikeData.Id
        );
        insert lead;

        Test.startTest();
        lead.Wrike_Account_Id__c = null;
        update lead;
        Test.stopTest();

        final Lead updatedLead = [
                SELECT Wrike_Data__c
                FROM Lead
                WHERE Id = :lead.Id
        ];
        System.assertEquals(null, updatedLead.Wrike_Data__c, 'WrikeData should be updated to null');
    }

    @IsTest
    static void testEmailDomains() {
        final String freeDomain = 'aol.com';
        final String paidDomain = '1aol.com';

        final Lead lead1 = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                Email = 'lead1@' + freeDomain
        );
        final Lead lead2 = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                Email = 'lead2@' + paidDomain
        );

        final Lead lead3 = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook'
        );

        insert(new List<Lead>{lead1, lead2, lead3});

        final Map<Id, Lead> leads = new Map<Id, Lead>(
                [SELECT Id, Email_Domain__c, Corporate_Email__c
                FROM Lead
                WHERE Id = :lead1.Id OR Id = :lead2.Id OR Id = :lead3.Id]);

        System.assert(String.isBlank(leads.get(lead1.Id).Email_Domain__c), 'Free email domain is not blank');
        System.assert(String.isNotBlank(leads.get(lead2.Id).Email_Domain__c), 'Paid email domain is blank');
        System.assert(String.isBlank(leads.get(lead3.Id).Email_Domain__c), 'Blank email domain is not blank');
        System.assert(leads.get(lead2.Id).Email_Domain__c == paidDomain, 'Email domain is incorrect');
        System.assert(!(leads.get(lead1.Id).Corporate_Email__c), 'Free email marked as corporate');
        System.assert(leads.get(lead2.Id).Corporate_Email__c, 'Paid email not marked as corporate');
        System.assert(!(leads.get(lead3.Id).Corporate_Email__c), 'Blank email marked as corporate');

        lead1.Email = 'lead1@' + paidDomain;
        lead2.Email = 'lead2@' + freeDomain;

        update(new List<Lead>{lead1, lead2});

        final Map<Id, Lead> updatedLeads = new Map<Id, Lead>(
                [SELECT Id, Email_Domain__c, Corporate_Email__c
                FROM Lead
                WHERE Id = :lead1.Id OR Id = :lead2.Id]);

        System.assert(String.isBlank(updatedLeads.get(lead2.Id).Email_Domain__c), 'Free email domain is not blank after update');
        System.assert(String.isNotBlank(updatedLeads.get(lead1.Id).Email_Domain__c), 'Paid email domain is blank after update');
        System.assert(updatedLeads.get(lead1.Id).Email_Domain__c == paidDomain, 'Email domain is incorrect after update');
        System.assert(!(updatedLeads.get(lead2.Id).Corporate_Email__c), 'Free email marked as corporate after update');
        System.assert(updatedLeads.get(lead1.Id).Corporate_Email__c, 'Paid email not marked as corporate after update');
    }

    @IsTest
    static void testExistingAccountByDomain() {
        final Account account1 = TestDataFactory.createAccount('Account1');
        account1.Email_Domain__c = 'team.wrike.com';
        final Account account2 = TestDataFactory.createAccount('Account2');
        account2.Email_Domain__c = 'wrike.com';
        insert TestDataFactory.createSettings();
        System.runAs(TestUtils.getActiveUser()) {
            insert account1;
            insert account2;
        }
        final Lead lead1 = new Lead(
                Email = 'test.user@team.wrike.com',
                FirstName = 'Test',
                LastName = 'Lead 1',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook'
        );
        insert lead1;
        final Lead lead2 = new Lead(
                Email = 'test.user@wrike.com',
                FirstName = 'Test',
                LastName = 'Lead 2',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook'
        );
        insert lead2;

        final Lead udpatedLead1 = [
                SELECT Id, Account__c
                FROM Lead
                WHERE Id = :lead1.Id
        ];
        final Lead udpatedLead2 = [
                SELECT Id, Account__c
                FROM Lead
                WHERE Id = :lead2.Id
        ];
        System.assertEquals(account1.Id, udpatedLead1.Account__c);
        System.assertEquals(account2.Id, udpatedLead2.Account__c);
    }

    @IsTest
    static void testExistingAccountByBusinessDomain() {
        final Account account1 = TestDataFactory.createAccount('Account1');
        account1.Email_Domain__c = 'team.wrike.com';
        final Account account2 = TestDataFactory.createAccount('Account2');
        account2.Email_Domain__c = 'wrike.com';
        insert TestDataFactory.createSettings();
        System.runAs(TestUtils.getActiveUser()) {
            insert account1;
            insert account2;
        }
        final Lead lead1 = new Lead(
                Email = 'test.user@gmail.com',
                FirstName = 'Test',
                LastName = 'Lead 1',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                Business_Domain__c = 'team.wrike.com'
        );
        insert lead1;
        final Lead lead2 = new Lead(
                Email = 'test.user@yandex.ru',
                FirstName = 'Test',
                LastName = 'Lead 2',
                Company = 'Test Company',
                LeadSource = 'Web',
                Lead_Sub_Source__c = 'eBook',
                Business_Domain__c = 'wrike.com'
        );
        insert lead2;
        final Lead udpatedLead1 = [
                SELECT Id, Account__c
                FROM Lead
                WHERE Id = :lead1.Id
        ];
        final Lead udpatedLead2 = [
                SELECT Id, Account__c
                FROM Lead
                WHERE Id = :lead2.Id
        ];
        System.assertEquals(account1.Id, udpatedLead1.Account__c);
        System.assertEquals(account2.Id, udpatedLead2.Account__c);
    }

    @IsTest
    static void testSetCountryDataBeforeInsert() {
        CountryData__c ruCountryData = TestDataFactory.createCountryData('RU', 123.4567);
        CountryData__c usCountryData = TestDataFactory.createCountryData('US', 1.23);
        CountryData__c defaultCountryData = TestDataFactory.createCountryData('--', 0.01);
        List<CountryData__c> countryDataToInsert = new List<CountryData__c>{ruCountryData, usCountryData, defaultCountryData};
        TestUtils.insertAndAssert(countryDataToInsert);

        Lead ruLead = TestDataFactory.createLead();
        ruLead.Country = 'Russian Federation';
        ruLead.CountryCode = 'RU';
        Lead usLead = TestDataFactory.createLead();
        usLead.CountryCode = 'US';
        Lead testLead = TestDataFactory.createLead();
        testLead.Country = null;
        testLead.CountryCode = null;

        Test.startTest();

        TestUtils.insertAndAssert(new List<Lead> {ruLead, usLead, testLead});

        Test.stopTest();

        List<Lead> leadsAfterInsert = TestUtils.findLeads();
        System.assertEquals(ruCountryData.Id, leadsAfterInsert.get(0).CountryData__c);
        System.assertEquals(usCountryData.Id, leadsAfterInsert.get(1).CountryData__c);
        System.assertEquals(defaultCountryData.Id, leadsAfterInsert.get(2).CountryData__c);
    }

    @IsTest
    static void testSetCountryDataBeforeUpdate() {
        CountryData__c ruCountryData = TestDataFactory.createCountryData('RU', 123.4567);
        CountryData__c usCountryData = TestDataFactory.createCountryData('US', 1.23);
        CountryData__c defaultCountryData = TestDataFactory.createCountryData('--', 0.01);
        List<CountryData__c> countryDataToInsert = new List<CountryData__c>{ruCountryData, usCountryData, defaultCountryData};
        TestUtils.insertAndAssert(countryDataToInsert);

        Lead ruLead = TestDataFactory.createLead();
        ruLead.Country = null;
        ruLead.CountryCode = null;
        Lead usLead = TestDataFactory.createLead();
        usLead.Country = null;
        usLead.CountryCode = null;
        Lead testLead = TestDataFactory.createLead();
        testLead.Country = null;
        testLead.CountryCode = null;

        Test.startTest();

        TestUtils.insertAndAssert(new List<Lead> {ruLead, usLead, testLead});

        List<Lead> leadsAfterInsert = TestUtils.findLeads();
        System.assertEquals(defaultCountryData.Id, leadsAfterInsert.get(0).CountryData__c);
        System.assertEquals(defaultCountryData.Id, leadsAfterInsert.get(1).CountryData__c);
        System.assertEquals(defaultCountryData.Id, leadsAfterInsert.get(2).CountryData__c);

        ruLead.Country = 'Russian Federation';
        ruLead.CountryCode = 'RU';
        TestUtils.updateAndAssert(ruLead);

        Test.stopTest();

        leadsAfterInsert = TestUtils.findLeads();
        System.assertEquals(ruCountryData.Id, leadsAfterInsert.get(0).CountryData__c);
        System.assertEquals(defaultCountryData.Id, leadsAfterInsert.get(1).CountryData__c);
        System.assertEquals(defaultCountryData.Id, leadsAfterInsert.get(2).CountryData__c);
    }

    @IsTest
    static void testEmailDataPopulated() {
        final String email = 'testemaildata@address.com';
        TestUtils.insertAndAssert(TestDataFactory.createLead(null, email));
        final Lead createdLead = TestUtils.findLeadByEmail(email).get(0);
        final Id emailDataId = createdLead.EmailData__c;
        System.assertNotEquals(null, emailDataId);
        TestUtils.updateAndAssert(new Lead(
                Id = createdLead.Id,
                Email = 'testemaildata2@address.com'
        ));
        final Lead updatedLead = TestUtils.findLeadById(createdLead.Id);
        System.assertNotEquals(emailDataId, updatedLead.EmailData__c);
        System.assertEquals(false, updatedLead.HasOptedOutOfEmail);
    }

    @IsTest
    static void testExistingEmailData() {
        final String email = 'testemaildata@address.com';
        final EmailData__c emailData = new EmailData__c(
            Email__c = email
        );
        Database.upsert(emailData, Schema.EmailData__c.Email__c);
        final Lead lead = TestDataFactory.createLead(null, email);
        lead.HasOptedOutOfEmail = true;
        TestUtils.insertAndAssert(lead);
        final Lead createdLead = TestUtils.findLeadById(lead.Id);
        System.assertEquals(emailData.Id, createdLead.EmailData__c);
        System.assertEquals(true, createdLead.HasOptedOutOfEmail);
    }

    @IsTest
    static void testUpdateContactOnEmailChange() {
        final String initialEmail = 'testemail1@address.com';
        final Contact contact1 = TestDataFactory.createContact(null, 'Test', initialEmail);
        insert contact1;
        final String updatedEmail = 'testemail2@address.com';
        final Contact contact2 = TestDataFactory.createContact(null, 'Test', updatedEmail);
        insert contact2;

        insert TestDataFactory.createLead(null, initialEmail);
        final Lead lead = TestUtils.findLeadByEmail(initialEmail).get(0);
        System.assertEquals(contact1.Id, lead.Contact__c);

        lead.Contact__c = null;
        update lead;

        lead.Email = updatedEmail;
        update lead;
        final Lead updatedLead = TestUtils.findLeadByEmail(updatedEmail).get(0);
        System.assertEquals(contact2.Id, updatedLead.Contact__c);
    }

    @IsTest
    static void testInsertWithTrialRequest() {
        insert new Settings__c(TrialProcessingEnabled__c = true);
        final Lead lead = TestDataFactory.createLead();
        lead.Last_Trial_Start_Date__c = Datetime.now();
        lead.Last_Trial_Account_Id__c = 123;
        insert lead;

        final List<Request__c> requests = findRequests(lead.Id);
        System.assert(!requests.isEmpty());
        System.assert(requests.size() == 1);
        final Request__c request = requests.get(0);
        System.assertEquals(request.Name, 'Trial - New - ' + lead.FirstName + ' ' + lead.LastName);
        System.assertEquals('Trial', request.Type__c);
        System.assertEquals('New', request.Subtype__c);
        System.assertEquals('Pending', request.Status__c);
        System.assertEquals(123, request.WrikeAccountId__c);
    }

    @IsTest
    static void testUpdateLastTrialStartDate() {
        insert new Settings__c(TrialProcessingEnabled__c = true);
        final Lead lead = TestDataFactory.createLead();
        lead.Last_Trial_Start_Date__c = Datetime.now().addDays(-10);
        lead.Last_Trial_Account_Id__c = 123;
        insert lead;

        final List<Request__c> newRequests = findRequests(lead.Id);
        System.assert(!newRequests.isEmpty());
        System.assert(newRequests.size() == 1);
        final Request__c newRequest = newRequests.get(0);
        System.assertEquals('Trial - New - ' + lead.FirstName + ' ' + lead.LastName, newRequest.Name);
        System.assertEquals('Trial', newRequest.Type__c);
        System.assertEquals('New', newRequest.Subtype__c);
        System.assertEquals('Pending', newRequest.Status__c);
        System.assertEquals(123, newRequest.WrikeAccountId__c);
        delete newRequest;

        LeadTriggerHandler.requestsCreated = false;
        lead.Last_Trial_Start_Date__c = Datetime.now();
        lead.Last_Trial_Account_Id__c = 456;
        update lead;

        final List<Request__c> restartRequests = findRequests(lead.Id);
        System.assert(!restartRequests.isEmpty());
        System.assert(restartRequests.size() == 1);
        final Request__c restartRequest = restartRequests.get(0);
        System.assertEquals('Trial - Restart - ' + lead.FirstName + ' ' + lead.LastName, restartRequest.Name);
        System.assertEquals('Trial', restartRequest.Type__c);
        System.assertEquals('Restart', restartRequest.Subtype__c);
        System.assertEquals('Pending', restartRequest.Status__c);
        System.assertEquals(456, restartRequest.WrikeAccountId__c);
    }

    @IsTest
    static void testLastTrialStartedLessThan7DaysAgo() {
        insert new Settings__c(TrialProcessingEnabled__c = true);
        final Lead lead = TestDataFactory.createLead();
        lead.Last_Trial_Start_Date__c = Datetime.now().addDays(-5);
        lead.Last_Trial_Account_Id__c = 123;
        insert lead;

        final List<Request__c> newRequests = findRequests(lead.Id);
        System.assert(!newRequests.isEmpty());
        System.assert(newRequests.size() == 1);
        final Request__c newRequest = newRequests.get(0);
        System.assertEquals('Trial - New - ' + lead.FirstName + ' ' + lead.LastName, newRequest.Name);
        System.assertEquals('Trial', newRequest.Type__c);
        System.assertEquals('New', newRequest.Subtype__c);
        System.assertEquals('Pending', newRequest.Status__c);
        System.assertEquals(123, newRequest.WrikeAccountId__c);
        delete newRequest;

        LeadTriggerHandler.requestsCreated = false;
        lead.Last_Trial_Start_Date__c = Datetime.now();
        lead.Last_Trial_Account_Id__c = 456;
        update lead;

        final List<Request__c> restartRequests = findRequests(lead.Id);
        System.assert(!restartRequests.isEmpty());
        System.assert(restartRequests.size() == 1);
        final Request__c restartRequest = restartRequests.get(0);
        System.assertEquals('Trial - Restart - ' + lead.FirstName + ' ' + lead.LastName, restartRequest.Name);
        System.assertEquals('Trial', restartRequest.Type__c);
        System.assertEquals('Restart', restartRequest.Subtype__c);
        System.assertEquals('Completed', restartRequest.Status__c);
        System.assertEquals(456, restartRequest.WrikeAccountId__c);
    }

    @IsTest
    static void testLastTrialStartedOlderThan2Weeks() {
        insert new Settings__c(TrialProcessingEnabled__c = true);
        final Lead lead = TestDataFactory.createLead();
        lead.Last_Trial_Start_Date__c = Datetime.now().addDays(-20);
        lead.Last_Trial_Account_Id__c = 123;
        insert lead;

        final List<Request__c> newRequests = findRequests(lead.Id);
        System.assert(!newRequests.isEmpty());
        System.assert(newRequests.size() == 1);
        final Request__c newRequest = newRequests.get(0);
        System.assertEquals('Trial - New - ' + lead.FirstName + ' ' + lead.LastName, newRequest.Name);
        System.assertEquals('Trial', newRequest.Type__c);
        System.assertEquals('New', newRequest.Subtype__c);
        System.assertEquals('Completed', newRequest.Status__c);
        System.assertEquals(123, newRequest.WrikeAccountId__c);
    }

    @IsTest
    static void testUpdateWithNotTrialRequest() {
        final Lead lead = TestDataFactory.createLead();
        insert lead;

        System.assert(findRequests(lead.Id).isEmpty());

        LeadTriggerHandler.requestsCreated = false;
        lead.Last_request_type__c = 'Not Trial';
        lead.Last_request_subtype__c = 'Request';
        lead.Last_request_wrike_account_ID__c = 123;
        lead.Last_request_date__c = Datetime.now();
        update lead;

        final List<Request__c> requests = findRequests(lead.Id);
        System.assert(!requests.isEmpty());
        System.assert(requests.size() == 1);
        final Request__c request = requests.get(0);
        System.assertEquals(request.Name, 'Not Trial - Request - ' + lead.FirstName + ' ' + lead.LastName);
        System.assertEquals(lead.Last_request_type__c, request.Type__c);
        System.assertEquals(lead.Last_request_subtype__c, request.Subtype__c);
        System.assertEquals(lead.Last_request_wrike_account_ID__c, request.WrikeAccountId__c);
        System.assertEquals('Completed', request.Status__c);
    }

    @IsTest
    static void testUpdateMarketingAssignment() {
        final Lead lead = TestDataFactory.createLead();
        insert lead;

        System.assert(findRequests(lead.Id).isEmpty());

        LeadTriggerHandler.requestsCreated = false;
        lead.MarketingAssignmentId__c = '12345';
        update lead;

        final List<Request__c> requests = findRequests(lead.Id);
        System.assert(!requests.isEmpty());
        System.assert(requests.size() == 1);
        final Request__c request = requests.get(0);
        System.assertEquals('MarketingAssignment - ' + lead.FirstName + ' ' + lead.LastName, request.Name);
        System.assertEquals('MarketingAssignment', request.Type__c);
        System.assertEquals(null, request.WrikeAccountId__c);
        System.assertEquals('Pending', request.Status__c);
    }

    @IsTest
    static void testLeadBecamePaid() {
        insert new Settings__c(PaidProcessingEnabled__c = true);
        final Lead lead = TestDataFactory.createLead();
        lead.Wrike_Account_Id__c = 123;
        insert lead;

        System.assert(findRequests(lead.Id).isEmpty());

        LeadTriggerHandler.requestsCreated = false;
        lead.Wrike_Account_Status__c = 'Paid';
        update lead;

        final List<Request__c> requests = findRequests(lead.Id);
        System.assert(!requests.isEmpty());
        System.assert(requests.size() == 1);
        final Request__c request = requests.get(0);
        System.assertEquals('Paid - ' + lead.FirstName + ' ' + lead.LastName, request.Name);
        System.assertEquals('Paid', request.Type__c);
        System.assertEquals(123, request.WrikeAccountId__c);
        System.assertEquals('Pending', request.Status__c);
    }

    @IsTest
    static void testPaidProcessingDisabled() {
        final Lead lead = TestDataFactory.createLead();
        insert lead;

        LeadTriggerHandler.requestsCreated = false;
        lead.Wrike_Account_Status__c = 'Paid';
        update lead;

        System.assert(findRequests(lead.Id).isEmpty());
    }

    @IsTest
    static void testTrialProcessingDisabled() {
        final Lead lead = TestDataFactory.createLead();
        lead.Last_Trial_Start_Date__c = Datetime.now();
        lead.Last_Trial_Account_Id__c = 123;
        insert lead;

        System.assert(findRequests(lead.Id).isEmpty());
    }

    @IsTest
    static void testScoreDataPopulated() {
        final String email = 'testemaildata@address.com';
        TestUtils.insertAndAssert(TestDataFactory.createLead(null, email));
        final Lead createdLead = TestUtils.findLeadByEmail(email).get(0);
        final Id scoreDataId = createdLead.Scoring_Data__c;
        System.assertNotEquals(null, scoreDataId);
        TestUtils.updateAndAssert(new Lead(
            Id = createdLead.Id,
            Email = 'testemaildata2@address.com'
        ));
        final Lead updatedLead = TestUtils.findLeadById(createdLead.Id);
        System.assertNotEquals(scoreDataId, updatedLead.Scoring_Data__c);
    }

    @IsTest
    static void testExistingScoringData() {
        final String email = 'testemaildata@address.com';
        final Scoring_Data__c scoringData = new Scoring_Data__c(
            Email__c = email
        );
        Database.upsert(scoringData, Schema.Scoring_Data__c.Email__c);
        final Lead lead = TestDataFactory.createLead(null, email);
        TestUtils.insertAndAssert(lead);
        final Lead createdLead = TestUtils.findLeadById(lead.Id);
        System.assertEquals(scoringData.Id, createdLead.Scoring_Data__c);
    }

    @IsTest
    static void testLeadAssignCodeUpdated() {
        insert new Settings__c(PaidProcessingEnabled__c = true);
        final Lead lead = TestDataFactory.createLead();
        lead.Wrike_Account_Id__c = 123;
        insert lead;

        System.assert(findRequests(lead.Id).isEmpty());

        LeadTriggerHandler.requestsCreated = false;
        lead.Assign_Code__c = 'Test Assign Code';
        update lead;

        final List<Request__c> requests = findRequests(lead.Id);
        System.assert(!requests.isEmpty());
        System.assert(requests.size() == 1);
        final Request__c request = requests.get(0);
        System.assertEquals('AssignCodeUpdate - ' + lead.FirstName + ' ' + lead.LastName, request.Name);
        System.assertEquals('AssignCodeUpdate', request.Type__c);
        System.assertEquals(123, request.WrikeAccountId__c);
        System.assertEquals('Pending', request.Status__c);
    }

    @IsTest
    static void testSelfManagedTrialStart() {
        final Lead lead = TestDataFactory.createLead();
        lead.Wrike_Account_Id__c = 123;
        insert lead;

        System.assert(findRequests(lead.Id).isEmpty());

        LeadTriggerHandler.requestsCreated = false;
        lead.Last_Trial_Action_Source__c = 'AccountManagement';
        lead.Last_Trial_Product__c = 'resource,';
        update lead;

        final List<Request__c> requests = findRequests(lead.Id);
        System.assert(!requests.isEmpty());
        System.assert(requests.size() == 1);
        final Request__c request = requests.get(0);
        System.assertEquals('SelfManagedTrial - ' + lead.FirstName + ' ' + lead.LastName, request.Name);
        System.assertEquals('SelfManagedTrial', request.Type__c);
        System.assertEquals(lead.Last_Trial_Product__c, request.Comment__c);
        System.assertEquals(123, request.WrikeAccountId__c);
        System.assertEquals('Pending', request.Status__c);
    }

    @IsTest
    static void testHighMarketoScoreForRecycledLead() {
        final Lead lead = TestDataFactory.createLead(WrikeConstants.RLQ_ID);
        lead.Wrike_Account_Id__c = 123;
        lead.CountryCode = 'US';
        lead.TechMotion__c = 'Outbound';
        TestUtils.insertAndAssert(lead);

        System.assert(findRequests(lead.Id).isEmpty());

        lead.mkto71_Lead_Score__c = 100;
        LeadTriggerHandler.requestsCreated = false;
        TestUtils.updateAndAssert(lead);

        final List<Request__c> requests = findRequests(lead.Id);
        System.assert(!requests.isEmpty());
        System.assertEquals(1, requests.size());
        final Request__c request = requests.get(0);
        System.assertEquals('HighMarketoScore - ' + lead.FirstName + ' ' + lead.LastName, request.Name);
        System.assertEquals('HighMarketoScore', request.Type__c);
        System.assertEquals(123, request.WrikeAccountId__c);
        System.assertEquals('Pending', request.Status__c);
    }

    private static List<Request__c> findRequests(final Id leadId) {
        return [
                SELECT Id, Name, Type__c, Subtype__c, Status__c, WrikeAccountId__c, Comment__c
                FROM Request__c
                WHERE Lead__c = :leadId
        ];
    }
}
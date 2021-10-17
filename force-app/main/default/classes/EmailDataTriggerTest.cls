/**
 * @author Andrey Kuleshov
 */
@IsTest
public class EmailDataTriggerTest {

    @IsTest
    static void testRelatedLeadUpdated() {
        final String email = 'emaildata@test.com';
        final EmailData__c emailData = new EmailData__c(Email__c = email);
        TestUtils.insertAndAssert(emailData);
        final Lead lead = TestDataFactory.createLead(null, email);
        lead.Company = 'Unknown <' + email + '>';
        TestUtils.insertAndAssert(lead);
        emailData.Phone__c = '+1234567899';
        emailData.JobTitle__c = 'APEX Developer';
        emailData.Industry__c = 'High Tech';
        emailData.CompanyName__c = 'WrikeTeam';
        emailData.CompanySize__c = 999;
        emailData.ReferralCode__c = 'ABC';
        emailData.CountryCode__c = 'US';
        emailData.StateCode__c = 'CA';
        emailData.City__c = 'San Jose';
        emailData.UnsubscribedDate__c = DateTime.now();
        TestUtils.updateAndAssert(emailData);
        final Lead updatedLead = TestUtils.findLeadById(lead.Id);
        System.assertEquals('+1234567899', updatedLead.Phone);
        System.assertEquals('APEX Developer', updatedLead.Title);
        System.assertEquals('High Tech', updatedLead.Industry);
        System.assertEquals('WrikeTeam', updatedLead.Company);
        System.assertEquals(999, updatedLead.NumberOfEmployees);
        System.assertEquals('ABC', updatedLead.Referral_Code__c);
        System.assertEquals('US', updatedLead.CountryCode);
        System.assertEquals('CA', updatedLead.StateCode);
        System.assertEquals('San Jose', updatedLead.City);
        System.assertEquals(true, updatedLead.HasOptedOutOfEmail);
    }

    @IsTest
    static void testRelatedLeadNotUpdated() {
        final String email = 'emaildata@test.com';
        final EmailData__c emailData = new EmailData__c(Email__c = email);
        TestUtils.insertAndAssert(emailData);
        final Lead lead = TestDataFactory.createLead(null, email);
        lead.Phone = '+987654321';
        lead.Title = 'CEO';
        lead.Industry = 'High Tech';
        lead.NumberOfEmployees = 2000;
        lead.CountryCode = 'US';
        lead.StateCode = 'CA';
        lead.City = 'San Jose';
        lead.Referral_Code__c = 'ABC';
        TestUtils.insertAndAssert(lead);
        final Lead createdLead = TestUtils.findLeadById(lead.Id);
        final Datetime lastModifiedDate = createdLead.LastModifiedDate;
        emailData.Phone__c = '+1234567899';
        emailData.JobTitle__c = 'APEX Developer';
        emailData.Industry__c = 'High Tech';
        emailData.CompanyName__c = 'WrikeTeam';
        emailData.CompanySize__c = 999;
        emailData.CountryCode__c = 'US';
        emailData.StateCode__c = 'CA';
        emailData.City__c = 'San Jose';
        TestUtils.updateAndAssert(emailData);
        final Lead updatedLead = TestUtils.findLeadById(lead.Id);
        System.assertEquals(lastModifiedDate, updatedLead.LastModifiedDate, 'Last Modified Date should not be changed.');
    }

    @IsTest
    static void testRelatedContactUpdated() {
        final String email = 'emaildata@test.com';
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final EmailData__c emailData = new EmailData__c(Email__c = email);
        TestUtils.insertAndAssert(emailData);
        final Contact contact = TestDataFactory.createContact(account.Id, 'Test', email);
        TestUtils.insertAndAssert(contact);
        emailData.UnsubscribedDate__c = Datetime.now();
        TestUtils.updateAndAssert(emailData);
        final Contact updatedContact = TestUtils.findContactById(contact.Id);
        System.assertEquals(true, updatedContact.HasOptedOutOfEmail);
    }
}
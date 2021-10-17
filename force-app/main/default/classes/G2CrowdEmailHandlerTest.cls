@IsTest
public class G2CrowdEmailHandlerTest {

    @TestSetup
    static void setup() {
        insert new Campaign(Name = 'HT-GM-LLP-G2 Leads-2019Q4');
    }

    @IsTest
    static void testEmailParsing() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.htmlBody = getEmailText();
        new G2CrowdEmailHandler().handleInboundEmail(email, new Messaging.InboundEnvelope());

        final List<Lead> leads = TestUtils.findLeadByEmail('test123@gmail.com');
        System.assert(!leads.isEmpty(), 'Lead not created.');
        final Lead lead = leads[0];
        System.assertEquals('G2Crowd', lead.Lead_Sub_Source__c);
        System.assertEquals('Test First Name', lead.FirstName);
        System.assertEquals('Test Last Name', lead.LastName);
        System.assertEquals('test.company.name', lead.Website);
        System.assertEquals('Accounting', lead.Industry);
        System.assertEquals('123456789', lead.Phone);
        System.assertEquals('Myself only', lead.Self_Selected_Employee_Size__c);
        System.assertEquals('AU', lead.CountryCode);
        System.assertEquals('Australia', lead.Country);
        System.assertEquals('Rosehill', lead.City);
        System.assertEquals('00GF0000002QrZf', lead.OwnerId);
        System.assert(!lead.Notes.isEmpty());
        final Note note = lead.Notes[0];
        System.assertEquals('Requested a Custom Quote', note.Body);
    }

    @IsTest
    static void testEmailParsingWithoutLinks() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.htmlBody = 'Full Name: Test First Name Test Last Name <br/>' +
        'First Name: Test First Name <br/>\n' +
        'Last Name: Test Last Name <br/>\n' +
        'Business Email: te=\n' +
        'st123@gmail.com <br/>\n' +
        'Company: test.company.name=\n' +
        '<br/>\n' +
        '<p>Feel free to follow up';
        new G2CrowdEmailHandler().handleInboundEmail(email, new Messaging.InboundEnvelope());

        final List<Lead> leads = TestUtils.findLeadByEmail('test123@gmail.com');
        System.assert(!leads.isEmpty(), 'Lead not created.');
        final Lead lead = leads[0];
        System.assertEquals('G2Crowd', lead.Lead_Sub_Source__c);
        System.assertEquals('Test First Name', lead.FirstName);
        System.assertEquals('Test Last Name', lead.LastName);
        System.assertEquals('test.company.name', lead.Website);
    }

    @IsTest
    static void testLeadUpdate() {
        insert new Lead(Email = 'test123@gmail.com',
                        LastName = '-',
                        OwnerId = WrikeConstants.RLQ_ID,
                        Company = 'test.com.au',
                        LeadSource = 'Web',
                        Lead_Sub_Source__c = 'Web'
        );

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.htmlBody = getEmailText();
        new G2CrowdEmailHandler().handleInboundEmail(email, new Messaging.InboundEnvelope());

        final List<Lead> leads = TestUtils.findLeadByEmail('test123@gmail.com');
        final Lead updatedLead = leads[0];
        System.assertEquals('Open', updatedLead.Status);
        System.assertEquals(WrikeConstants.GLQ_ID, updatedLead.OwnerId);
        System.assertEquals('test.com.au', updatedLead.Company);
        System.assertEquals('-', updatedLead.LastName);
        System.assertEquals('test.company.name', updatedLead.Website);
        System.assert(!updatedLead.Notes.isEmpty());
        final Note note = updatedLead.Notes[0];
        System.assertEquals('Requested a Custom Quote', note.Body);
    }

    private static String getEmailText() {
        return [
                SELECT Body
                FROM StaticResource
                WHERE Name = 'G2CrowdEmail'
        ].Body.toString();
    }
}
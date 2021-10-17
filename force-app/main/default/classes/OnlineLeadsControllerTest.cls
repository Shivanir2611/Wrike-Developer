@IsTest
public class OnlineLeadsControllerTest {

    @IsTest
    static void testGetLeads() {
        System.runAs(TestUtils.getWrikeIntegrationUser()) {
            final OnlineLeadsController olc = new OnlineLeadsController();
            final List<Lead> noLeads = olc.getLeads();
            System.assert(noLeads.isEmpty());

            final Lead testLead = insertOnlineLead();
            olc.refreshLeads();
            final List<Lead> leads = olc.getLeads();
            System.assert(!leads.isEmpty());
            System.assert(leads.get(0).Id == testLead.Id);
        }
    }

    private static Lead insertOnlineLead() {
        final Lead testLead = TestDataFactory.createLead();
        final WrikeData__c wData = new WrikeData__c(
                Wrike_Account_Id__c = 1,
                License_Name__c = 'Test'
        );
        insert wData;
        final UserData__c udata = new UserData__c(
                Wrike_User_Id__c = testLead.Wrike_User_Id__c,
                Online__c = true,
                Online_Date__c = DateTime.now().addHours(-12));
        insert udata;
        testLead.Wrike_Data__c = wData.Id;
        testLead.Wrike_User_Data__c = udata.Id;
        testLead.Phone = '12345';
        testLead.LeadSource = 'Web';
        testLead.Lead_Sub_Source__c = 'eBook';
        insert testLead;
        return testLead;
    }
}
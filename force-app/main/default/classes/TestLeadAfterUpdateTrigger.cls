@IsTest
public class TestLeadAfterUpdateTrigger {

	@IsTest
	static void testLeadConversion() {
		final Lead lead = TestDataFactory.createLead();
		insert lead;
		final Account account = TestDataFactory.createAccount();
		insert account;
		final Database.LeadConvert leadConvert = new Database.LeadConvert();
		leadConvert.setConvertedStatus(findConvertedStatus());
		leadConvert.setDoNotCreateOpportunity(false);
		leadConvert.setLeadId(lead.Id);
		leadConvert.setAccountId(account.Id);
		final Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConvert);
		System.assertEquals(true, leadConvertResult.isSuccess());
		final List<Key_Players_Influencers__c> buyerMapRecords = findBuyerMapRecords(leadConvertResult.getOpportunityId());
		System.assertEquals(1, buyerMapRecords.size());
		System.assertEquals(leadConvertResult.getContactId(), buyerMapRecords.get(0).Name__c);
		System.assertEquals(true, buyerMapRecords.get(0).Primary__c);
	}

    @IsTest
    static void testLeadConversionToExistingRecords() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contact contact = TestDataFactory.createContact(account.Id);
        insert contact;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, contact.Id);
        insert opportunity;
        final Key_Players_Influencers__c buyerMap = new Key_Players_Influencers__c(
            Opportunity__c = opportunity.Id,
            Name__c = contact.Id,
            Primary__c = true
        );
        insert buyerMap;
        final Lead lead = TestDataFactory.createLead();
        insert lead;
        final Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setConvertedStatus(findConvertedStatus());
        leadConvert.setLeadId(lead.Id);
        leadConvert.setAccountId(account.Id);
        leadConvert.setContactId(contact.Id);
        leadConvert.setOpportunityId(opportunity.Id);
        final Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConvert);
        System.assertEquals(true, leadConvertResult.isSuccess());
        final List<Key_Players_Influencers__c> buyerMapRecords = findBuyerMapRecords(leadConvertResult.getOpportunityId());
        System.assertEquals(1, buyerMapRecords.size());
        System.assertEquals(leadConvertResult.getContactId(), buyerMapRecords.get(0).Name__c);
        System.assertEquals(true, buyerMapRecords.get(0).Primary__c);
    }

	@IsTest
	static void testTaskReassignment() {
		final List<User> users = [SELECT Id FROM User WHERE IsActive = true];
		final Lead lead = new Lead(
				OwnerId = users[0].Id,
				FirstName = 'Test',
				LastName = 'Lead',
				Company = 'Test Company',
				LeadSource = 'Web',
				Lead_Sub_Source__c = 'Request'
		);
		insert lead;
		final Task task = new Task(
				OwnerId = users[0].Id,
				WhoId = lead.Id,
				Status = 'Open',
				Subject = 'Test Task',
				ActivityDate = Date.today()
		);
		insert task;

		test.startTest();
		lead.OwnerId = users[1].Id;
		update lead;
		test.stopTest();

		System.assert([SELECT OwnerId FROM Task WHERE Id = :task.Id][0].OwnerId == users[1].Id,
				'Task was not reassigned');
	}

	@IsTest
	static void testSfAdminTaskReassignment() {
		final List<User> users = [SELECT Id FROM User WHERE IsActive = true];
		final Lead lead = new Lead(
				OwnerId = users[0].Id,
				FirstName = 'Test',
				LastName = 'Lead',
				Company = 'Test Company',
				LeadSource = 'Web',
				Lead_Sub_Source__c = 'Request'
		);
		insert lead;
		final Task task = new Task(
				OwnerId = WrikeConstants.SF_ADMIN_ID,
				WhoId = lead.Id,
				Status = 'Open',
				Subject = 'Test Task',
				ActivityDate = Date.today()
		);
		insert task;

		test.startTest();
		lead.OwnerId = users[1].Id;
		update lead;
		test.stopTest();

		System.assert([SELECT OwnerId FROM Task WHERE Id = :task.Id][0].OwnerId == users[1].Id,
				'Task was not reassigned');
	}

	@isTest
	static void testRelatedEventsCancelOnRecycle() {

		final String supportLeadQueueId =
				GroupService.getInstance().getQueueIdByDevNameOrNull(GroupService.SUPPORT_LEAD_QUEUE);
		final EventQueryService eventQuerySrv = EventQueryService.getInstance();

		final Event_Data__c eventData = new Event_Data__c();
		insert eventData;

		final Lead testLead = TestDataFactory.createLead(supportLeadQueueId);
		testLead.Event_Data__c = eventData.Id;
		insert testLead;

		final Event__c supportRequest =
				TestDataFactory.createSupportEvent(testLead.id, eventData.Id, 'GeneralSalesRequest');
		insert supportRequest;

		final Event__c initialRequest = eventQuerySrv.findEventById(supportRequest.Id);
		System.assert(!initialRequest.Status__c.equals('Cancelled'), 'Status is incorrect');
		System.assert(initialRequest.Recycle_Date__c == null, 'Recycle date must be empty');

		testLead.Status = LeadService.RECYCLE_STATUS;
		testLead.Recycle_Reasons__c = 'Recycle Workflow';
		testLead.Recycle_Sub_Reason__c = 'Automated Recycle';
		testLead.Follow_Up_Timeframe__c = '15 Days';
		testLead.Last_Recycled_Date__c = Datetime.now();
		testLead.OwnerId = WrikeConstants.RLQ_ID;
		update testLead;

		final Event__c cancelledRequest = eventQuerySrv.findEventById(supportRequest.Id);
		System.assert(cancelledRequest.Status__c.equals('Cancelled'), 'Status is incorrect');
		System.assert(cancelledRequest.Recycle_Date__c != null, 'Recycle date must be set');
		System.assert(cancelledRequest.Recycle_Date__c.date().isSameDay(Date.today()), 'Recycle date is incorrect');
	}

	private static String findConvertedStatus() {
		final LeadStatus convertStatus = [
			SELECT Id, MasterLabel
			FROM LeadStatus
			WHERE IsConverted = true
			LIMIT 1
		];
		return convertStatus.MasterLabel;
	}

    private static List<Key_Players_Influencers__c> findBuyerMapRecords(Id opportunityId){
        return [
            SELECT Name__c, Primary__c
            FROM Key_Players_Influencers__c
            WHERE Opportunity__c =: opportunityId   
        ];
    }
}
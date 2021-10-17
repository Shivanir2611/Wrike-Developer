/*
 * Created by sofia.kanukova on 02/09/2019.
 */

@IsTest
public class EventTriggerHandlerTest {
	@IsTest
	public static void testRelatedEventsCancel() {
		final String supportLeadQueueId =  GroupService.getInstance().getQueueIdByDevNameOrNull(GroupService.SUPPORT_LEAD_QUEUE);
		final EventQueryService eventQuerySrv = EventQueryService.getInstance();

		final Event_Data__c eventData = new Event_Data__c();
		insert eventData;

		final Lead testLead = TestDataFactory.createLead(supportLeadQueueId);
		testLead.Event_Data__c = eventData.Id;
		insert testLead;

		Test.setCreatedDate(testLead.Id, Datetime.now().addDays(-1));

		final Event__c request1 = TestDataFactory.createSupportEvent(testLead.id, eventData.Id,'GeneralSalesRequest');
		insert request1;

		final Event__c initialRequest = eventQuerySrv.findEventById(request1.Id);
		System.assert(initialRequest.Cancellation_Date__c == null, 'Cancellation date must be empty');
		System.assert(!initialRequest.Status__c.equals('Cancelled'), 'Status is incorrect');

		final Event__c request2 = TestDataFactory.createSupportEvent(testLead.id, eventData.Id,'GeneralSalesRequest');
		insert request2;

		testLead.OwnerId = TestUtils.getActiveUser().Id;
		update testLead;

		final Event__c request3 = TestDataFactory.createSupportEvent(testLead.id, eventData.Id,'GeneralSalesRequest');
		insert request3;

		final Event__c cancelledRequest = eventQuerySrv.findEventById(request1.Id);
		System.assert(cancelledRequest.Cancellation_Date__c != null, 'Cancellation date must be set');
		System.assert(cancelledRequest.Status__c.equals('Cancelled'), 'Status is incorrect');
		System.assert(cancelledRequest.Cancellation_Date__c.date().isSameDay(Date.today()), 'Cancellation date is incorrect');

		final Event__c nonCancelledRequest = eventQuerySrv.findEventById(request2.Id);
		System.assert(nonCancelledRequest.Cancellation_Date__c == null, 'Cancellation date must be empty');
		System.assert(!nonCancelledRequest.Status__c.equals('Cancelled'), 'Status is incorrect');
	}

	@IsTest
	public static void testEventQualificationFormulaForLead() {
		final String supportLeadQueueId =  GroupService.getInstance().getQueueIdByDevNameOrNull(GroupService.SUPPORT_LEAD_QUEUE);
		final EventQueryService eventQuerySrv = EventQueryService.getInstance();

		final Event_Data__c leadEventData = new Event_Data__c();
		insert leadEventData;

		final Lead testLead = TestDataFactory.createLead(supportLeadQueueId);
		testLead.Event_Data__c = leadEventData.Id;
		insert testLead;

		Test.setCreatedDate(testLead.Id, Datetime.now().addDays(-1));

		final Event__c request1 = TestDataFactory.createSupportEvent(testLead.id, leadEventData.Id,'GeneralSalesRequest');
		insert request1;

		final Event__c request2 = TestDataFactory.createSupportEvent(testLead.id, leadEventData.Id, 'GeneralSalesRequest');
		insert request2;

		testLead.OwnerId = TestUtils.getActiveUser().Id;
		update testLead;

		final Event__c request3 = TestDataFactory.createSupportEvent(testLead.id, leadEventData.Id, 'GeneralSalesRequest');
		insert request3;

		Test.setCreatedDate(request1.Id, Datetime.now().addHours(-3));
		Test.setCreatedDate(request2.Id, Datetime.now().addHours(-2));
		Test.setCreatedDate(request3.Id, Datetime.now().addHours(1));

		final Event__c cancelledRequest = eventQuerySrv.findEventById(request1.Id);
		System.assert(cancelledRequest.Qualification_Code__c.equals('UNQUALIFIED_CANCELLED'), 'Qualification Code is incorrect');

		final Event__c qualifiedRequest = eventQuerySrv.findEventById(request2.Id);
		System.assert(qualifiedRequest.Qualification_Code__c.equals('QUALIFIED'), 'Qualification Code is incorrect');

		final Event__c unqualifiedRequest = eventQuerySrv.findEventById(request3.Id);
		System.assert(unqualifiedRequest.Qualification_Code__c.equals('UNQUALIFIED_ALREADY_ASSIGNED'), 'Qualification Code is incorrect');

		testLead.OwnerId = supportLeadQueueId;
		final Event__c qualifiedRequest2 = eventQuerySrv.findEventById(request2.Id);
		System.assert(qualifiedRequest2.Qualification_Code__c.equals('QUALIFIED'), 'Qualification Code is incorrect');

		final Event__c unqualifiedRequest2 = eventQuerySrv.findEventById(request3.Id);
		System.assert(unqualifiedRequest2.Qualification_Code__c.equals('UNQUALIFIED_ALREADY_ASSIGNED'), 'Qualification Code is incorrect');
	}

	@IsTest
	public static void testEventQualificationFormulaForAccount() {
		final String supportLeadQueueId =  GroupService.getInstance().getQueueIdByDevNameOrNull(GroupService.SUPPORT_LEAD_QUEUE);
		final EventQueryService eventQuerySrv = EventQueryService.getInstance();

		final Event_Data__c accountEventData = new Event_Data__c();
		insert accountEventData;

		final Account account = TestDataFactory.createAccount();
		account.Event_Data__c = accountEventData.Id;
		insert account;

		final Opportunity upgradeOpportunity = TestDataFactory.createOpportunity(account.Id, 12345);
		final Opportunity otherOpportunity = TestDataFactory.createOpportunity(account.Id, 12345);
		insert upgradeOpportunity;
		insert otherOpportunity;

		final Event__c request1 = TestDataFactory.createSupportEvent(account.id, otherOpportunity.id, accountEventData.id, 'GeneralSalesRequest');
		insert request1;

		final Event__c request2 = TestDataFactory.createSupportEvent(account.id, upgradeOpportunity.id, accountEventData.id, 'UpgradeRequest');
		insert request2;

		final Event__c qualifiedRequest = eventQuerySrv.findEventById(request2.Id);
		System.assert(qualifiedRequest.Qualification_Code__c.equals('QUALIFIED'), 'Qualification Code is incorrect');

		final Event__c unqualifiedRequest = eventQuerySrv.findEventById(request1.Id);
		System.assert(unqualifiedRequest.Qualification_Code__c.equals('UNQUALIFIED_ALREADY_ASSIGNED'), 'Qualification Code is incorrect');
	}
}
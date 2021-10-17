@IsTest
public class OpportunityValidationControllerTest {

    @TestSetup
    static void setup() {
        TestDataFactory.insertSettings();
    }

    @IsTest
    static void testValidateAmendment() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 1000);
        insert opportunity;

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        final ZuoraObject.ZuoraAccount zuoraAccount = TestDataFactory.zuoraAccount()
                .setAccountNumber('1000')
                .build();
        final ZuoraObject.ZuoraSubscriptionWithRatePlans subscription = TestDataFactory.fullZuoraSubscription().build();
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findZuoraAccountByWrikeAccountId(1000), zuoraAccount)
                .mockStrict(MockApi.zuoraRestQueryService().findAllSubscriptionsByZuoraAccountId(zuoraAccount.id),
                new List<ZuoraObject.ZuoraSubscriptionWithRatePlans> { subscription })
                .build();

        Test.startTest();
        final OpportunityValidationResult result = OpportunityValidationController.validate(opportunity.Id);
        System.assert(result.message == null, result.message);
        System.assertEquals(true, result.isAmendment);
        System.assertEquals(zuoraAccount.id, result.zuoraAccount.id);
        System.assert(result.zuoraSubscription != null);
        System.assert(result.zuoraSubscriptionProducts != null);
        System.assert(result.zuoraSubscriptionProducts.size() == 1);
        Test.stopTest();
    }

    @IsTest
    static void testValidateNoZuoraAccount() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 1000);
        insert opportunity;

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findZuoraAccountByWrikeAccountId(1000), null)
                .build();

        Test.startTest();
        final OpportunityValidationResult result = OpportunityValidationController.validate(opportunity.Id);
        System.assert(result.message == null);
        System.assertEquals(true, result.isNewSubscription);
        Test.stopTest();
    }

    @IsTest
    static void testValidateNewSubscription() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 1000);
        insert opportunity;

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findZuoraAccountByWrikeAccountId(1000), new ZuoraObject.ZuoraAccount())
                .mock(MockApi.zuoraRestQueryService().findAllSubscriptionsByZuoraAccountId(null), new List<ZuoraObject.ZuoraSubscriptionWithRatePlans>())
                .build();

        Test.startTest();
        final OpportunityValidationResult result = OpportunityValidationController.validate(opportunity.Id);
        System.assert(result.message == null, result.message);
        System.assertEquals(true, result.isNewSubscription);
        Test.stopTest();
    }

    @IsTest
    static void testValidateOutbound() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, null, null);
        insert opportunity;

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();
        final OpportunityValidationResult result = OpportunityValidationController.validate(opportunity.Id);
        System.assert(result.message == null, result.message);
        System.assertEquals(true, result.isOutbound);
        Test.stopTest();
    }

    @IsTest
    static void testValidateSent() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, null, null);
        insert opportunity;
        insert new Quote__c(Status__c = 'SENT', Opportunity__c = opportunity.Id);

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();
        final OpportunityValidationResult result = OpportunityValidationController.validate(opportunity.Id);
        System.assert(result.message == null, result.message);
        System.assertEquals(true, result.isSent);
        Test.stopTest();
    }

    @IsTest
    static void testValidateMoreThanOneSubscription() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 1000);
        insert opportunity;

        final ZuoraObject.ZuoraAccount zuoraAccount = TestDataFactory.zuoraAccount()
                .setAccountNumber('1000')
                .build();
        final ZuoraObject.ZuoraSubscriptionWithRatePlans subscription1 = TestDataFactory.fullZuoraSubscription().build();
        final ZuoraObject.ZuoraSubscriptionWithRatePlans subscription2 = TestDataFactory.fullZuoraSubscription().build();
        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findZuoraAccountByWrikeAccountId(1000), zuoraAccount)
                .mockStrict(MockApi.zuoraRestQueryService().findAllSubscriptionsByZuoraAccountId(zuoraAccount.id),
                new List<ZuoraObject.ZuoraSubscriptionWithRatePlans> { subscription1, subscription2 })
                .build();

        Test.startTest();
        final OpportunityValidationResult result = OpportunityValidationController.validate(opportunity.Id);
        System.assert(result.message != null, result);
        System.assert(result.message.contains('has more than one subscription in Zuora'), result.message);
        Test.stopTest();
    }
}
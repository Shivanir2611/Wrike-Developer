@IsTest
public class OpportunityZuoraValidationControllerTest {

    private final static ZuoraObject.ZuoraAccount zuoraAccount = TestDataFactory.zuoraAccount()
            .setAccountNumber('100')
            .build();

    @TestSetup
    static void setup() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 100);
        TestUtils.insertAndAssert(testOpportunity);
    }

    static {
        final ZuoraObject.ZuoraSubscriptionWithRatePlans fullZuoraSubscription =
                TestDataFactory.fullZuoraSubscription().build();
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findZuoraAccountByWrikeAccountId(100), zuoraAccount)
                .mockStrict(MockApi.zuoraRestQueryService().findAllSubscriptionsByZuoraAccountId(zuoraAccount.id),
                new List<ZuoraObject.ZuoraSubscriptionWithRatePlans> { fullZuoraSubscription })
                .build();
    }

    @IsTest
    static void testSuccessInit() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities.get(0));
        OpportunityZuoraValidationController opportunityValidationController = new OpportunityZuoraValidationController(standardController);

        System.assert(opportunityValidationController.getIsAmendment());
        System.assert(!opportunityValidationController.getIsSent());
        System.assertEquals(null, opportunityValidationController.getErrorMessage());
        System.assertEquals(1, opportunityValidationController.getSubscriptionProducts().size());
        System.assertNotEquals(null, opportunityValidationController.getSubscription());
        System.assertNotEquals(null, opportunityValidationController.getZuoraAccount());

        Test.stopTest();
    }

    @IsTest
    static void testInitWithoutZuoraAccount() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findZuoraAccountByWrikeAccountId(100), null)
                .build();

        Test.startTest();
        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities.get(0));
        OpportunityZuoraValidationController opportunityValidationController = new OpportunityZuoraValidationController(standardController);

        System.assertNotEquals(null, opportunityValidationController.getErrorMessage());
        System.assertEquals(null, opportunityValidationController.getZuoraAccount());

        Test.stopTest();
    }

    @IsTest
    static void testInitWithoutZuoraSubscription() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findAllSubscriptionsByZuoraAccountId(zuoraAccount.id),
                new List<ZuoraObject.ZuoraSubscriptionWithRatePlans>())
                .build();

        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities.get(0));
        OpportunityZuoraValidationController opportunityValidationController = new OpportunityZuoraValidationController(standardController);

        System.assertNotEquals(null, opportunityValidationController.getErrorMessage());
        System.assertNotEquals(null, opportunityValidationController.getZuoraAccount());
        System.assertEquals(null, opportunityValidationController.getSubscription());

        Test.stopTest();
    }

    @IsTest
    static void testInitWithTwoZuoraSubscription() {
        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(1, opportunities.size());

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());
        MockApi.setup()
                .mockStrict(MockApi.zuoraRestQueryService().findAllSubscriptionsByZuoraAccountId(zuoraAccount.id),
                new List<ZuoraObject.ZuoraSubscriptionWithRatePlans> {
                        new ZuoraObject.ZuoraSubscriptionWithRatePlans(),
                        new ZuoraObject.ZuoraSubscriptionWithRatePlans()
                        })
                .build();

        Test.startTest();

        ApexPages.StandardController standardController = new ApexPages.StandardController(opportunities.get(0));
        OpportunityZuoraValidationController opportunityValidationController = new OpportunityZuoraValidationController(standardController);

        System.assertNotEquals(null, opportunityValidationController.getErrorMessage());
        System.assertNotEquals(null, opportunityValidationController.getZuoraAccount());
        System.assertEquals(null, opportunityValidationController.getSubscription());

        Test.stopTest();
    }
}
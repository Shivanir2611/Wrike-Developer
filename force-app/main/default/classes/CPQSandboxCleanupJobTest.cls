@IsTest
public class CPQSandboxCleanupJobTest {

    private static final String testEmail = 'cpqcleanupjob@test.com';

    @TestSetup
    static void setup() {
        final User cpqUser = TestDataFactory.createUser(testEmail, 'CPQ', 'Test', 'System Administrator', false);
        TestUtils.insertAndAssert(cpqUser);
        TestUtils.insertAndAssert(new CPQSettings__c(ECommerceAPIUserId__c = cpqUser.Id, StorageAlertsEmails__c = 'email1@test.com, email2@test.com,'));
    }

    @IsTest
    static void testCleanupEcommerce() {
        System.runAs(getTestUser()) {
            createTestData(Datetime.now().addHours(-3));
        }

        Test.startTest();
        final CPQSandboxCleanupJob cleanupJob = new CPQSandboxCleanupJob(1);
        final Database.QueryLocatorIterator it = cleanupJob.start(null).iterator();
        System.assert(it.hasNext());
        cleanupJob.execute(null, new List<Account> { (Account)it.next()});
        Test.stopTest();

        System.assert(getAccounts().isEmpty());
        System.assert(getOpportunities().isEmpty());
        System.assert(getBillToShipTos().isEmpty());
        System.assert(getOfacChecks().isEmpty());
        System.assert(getQuotes().isEmpty());
        System.assert(getQuoteLines().isEmpty());
        System.assert(getQuoteLineGroups().isEmpty());
        System.assert(getOrders().isEmpty());
        System.assert(getContracts().isEmpty());
        System.assert(getSubscriptions().isEmpty());
        System.assert(getWrikeSubscriptions().isEmpty());
        System.assert(getOppData().isEmpty());
        System.assert(getLineItemBillingSchedules().isEmpty());
        System.assert(getBillingSchedules().isEmpty());
        System.assert(getWrikeDeployments().isEmpty());
    }

    @IsTest
    static void testNoCleanupEcommerce_recentData() {
        System.runAs(getTestUser()) {
            createTestData(null);
        }

        Test.startTest();
        final CPQSandboxCleanupJob cleanupJob = new CPQSandboxCleanupJob(1);
        System.assert(!cleanupJob.start(null).iterator().hasNext());
        Test.stopTest();
    }

    @IsTest
    static void testCleanupAllUsers() {
        createTestData(Datetime.now().addDays(-15));

        Test.startTest();
        final CPQSandboxCleanupJob cleanupJob = new CPQSandboxCleanupJob(1);
        final Database.QueryLocatorIterator it = cleanupJob.start(null).iterator();
        System.assert(it.hasNext());
        cleanupJob.execute(null, new List<Account> { (Account)it.next()});
        Test.stopTest();

        System.assert(getAccounts().isEmpty());
        System.assert(getOpportunities().isEmpty());
        System.assert(getBillToShipTos().isEmpty());
        System.assert(getOfacChecks().isEmpty());
        System.assert(getQuotes().isEmpty());
        System.assert(getQuoteLines().isEmpty());
        System.assert(getQuoteLineGroups().isEmpty());
        System.assert(getOrders().isEmpty());
        System.assert(getContracts().isEmpty());
        System.assert(getSubscriptions().isEmpty());
        System.assert(getWrikeSubscriptions().isEmpty());
        System.assert(getOppData().isEmpty());
        System.assert(getLineItemBillingSchedules().isEmpty());
        System.assert(getBillingSchedules().isEmpty());
        System.assert(getWrikeDeployments().isEmpty());
    }

    @IsTest
    static void testNoCleanupAllUsers_recentData() {
        createTestData(Datetime.now().addDays(-7));

        Test.startTest();
        final CPQSandboxCleanupJob cleanupJob = new CPQSandboxCleanupJob(1);
        System.assert(!cleanupJob.start(null).iterator().hasNext());
        Test.stopTest();
    }

    @IsTest
    static void testNoCleanupAllUsers_MarkedAccount() {
        createTestData(Datetime.now().addDays(-15));
        final Account acc = getAccounts().get(0);
        update new Account(
                Id = acc.Id,
                TestAccount__c = true
        );

        Test.startTest();
        final CPQSandboxCleanupJob cleanupJob = new CPQSandboxCleanupJob(1);
        System.assert(!cleanupJob.start(null).iterator().hasNext());
        Test.stopTest();
    }

    @IsTest
    static void testStorageAlert() {
        final CPQSandboxCleanupJob cleanupJob = new CPQSandboxCleanupJob(1);
        final String message = cleanupJob.getLimitAlertMessage('testString', 70, 100);
        System.assert(String.isNotBlank(message));
        System.assert(message.contains('testString'));
        System.assert(message.contains('70'));
        System.assert(message.contains('100'));
        final Messaging.SingleEmailMessage alertEmail = cleanupJob.getAlertEmail(message);
        System.assertNotEquals(null, alertEmail);
        System.assert(alertEmail.getToAddresses().contains('email1@test.com'));
        System.assert(alertEmail.getToAddresses().contains('email2@test.com'));
        System.assert(alertEmail.getSubject().contains(URL.getSalesforceBaseUrl().getHost().substringBeforeLast('.my.salesforce.com') + ' is close to limits'));
        System.assert(alertEmail.getPlainTextBody().contains(message));
        Test.startTest();
        cleanupJob.sendAlert(alertEmail);
        Test.stopTest();
    }

    @IsTest
    static void testNoStorageAlert() {
        final CPQSandboxCleanupJob cleanupJob = new CPQSandboxCleanupJob(1, 90);
        final String message = cleanupJob.getLimitAlertMessage('testString', 91, 100);
        System.assert(String.isNotBlank(message));
        final String message2 = cleanupJob.getLimitAlertMessage('testString', 89, 100);
        System.assertEquals(null, message2);
    }

    private static void createTestData(final Datetime createdDate) {
        final Integer wrikeAccountId = 12345;
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);

        final Opportunity opp = TestDataFactory.createOpportunity(account.Id, wrikeAccountId);
        TestUtils.insertAndAssert(opp);

        final Deployment__c deployment = TestDataFactory.createDeployment(opp.Id, account.Id, 'New', Datetime.now(), Datetime.now().addDays(1));
        TestUtils.insertAndAssert(deployment);

        final WrikeData__c wrikeData = TestDataFactory.createWrikeData(wrikeAccountId, false);
        TestUtils.insertAndAssert(wrikeData);

        final QS_Bill_To_Ship_To__c btst = TestDataFactory.createBillToShipTo(account.Id, wrikeAccountId, true);
        TestUtils.insertAndAssert(btst);

        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = account.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft',
                QS_Bill_To__c = btst.Id
        );
        TestUtils.insertAndAssert(quote);

        final Product2 product = new Product2(
                Name = 'Test Product'
        );
        insert product;
        TestUtils.insertAndAssert(new SBQQ__QuoteLineGroup__c(
                Name = 'Group 1',
                SBQQ__Number__c = 1,
                SBQQ__Quote__c = quote.Id,
                SBQQ__StartDate__c = Date.today(),
                SBQQ__EndDate__c = Date.today().addYears(1)
        ));

        TestUtils.insertAndAssert(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__RegularPrice__c = 100,
                SBQQ__CustomerPrice__c = 100,
                SBQQ__Product__c = product.Id,
                SBQQ__Quantity__c = 5
        ));

        TestUtils.updateAndAssert(new SBQQ__Quote__c(
                Id = quote.Id,
                SBQQ__Status__c = 'Approved'
        ));

        final Billing_Schedule__c billingSchedule = new Billing_Schedule__c(
                Name = 'Name',
                Invoice_Number__c = 1234567,
                Service_Start_Date__c = Date.today().addDays(1),
                Service_End_Date__c = Date.today().addDays(1).addMonths(12),
                Invoice_Date__c = Date.today(),
                Subscription_Amount__c = 10,
                One_Time_Fee_Amount__c = 1,
                Service_Term_In_Months__c = 12,
                Quote__c = quote.Id
        );
        TestUtils.insertAndAssert(billingSchedule);

        final Order order = new Order(
                AccountId = account.Id,
                OpportunityId = opp.Id,
                SBQQ__Quote__c = quote.Id,
                EffectiveDate = Date.today().addDays(1),
                Status = 'Draft',
                Pricebook2Id = Test.getStandardPricebookId()
        );
        TestUtils.insertAndAssert(order);


        PriceBookEntry pbEntry = new PriceBookEntry(
                Product2Id = product.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                UnitPrice = 2000,
                IsActive = true
        );
        insert pbEntry;

        final OrderItem orderItem = new OrderItem(
                OrderId = order.Id,
                SBQQ__Status__c = 'Activated',
                SBQQ__Activated__c = true,
                SBQQ__Contracted__c = true,
                PricebookEntryId = pbEntry.Id,
                UnitPrice = 2000,
                Quantity = 1
        );
        TestUtils.insertAndAssert(orderItem);

        order.Status = 'Activated';
        order.SBQQ__Contracted__c = true;
        TestUtils.updateAndAssert(order);

        final Line_Item_Billing_Schedule__c lineItemBillingSchedule = new Line_Item_Billing_Schedule__c(
                Name = 'Name',
                Internal_Invoice_Number__c = 1234567,
                Service_Start_Date__c = Date.today().addDays(1),
                Service_End_Date__c = Date.today().addDays(1).addMonths(12),
                Invoice_Date__c = Date.today(),
                Invoice_Allocated_Amount__c = 10,
                Order_Effective_Price__c = 2000,
                Quantity__c = 12,
                Charge_Type__c = 'charge type',
                Product_NetSuite_Internal_ID__c = '1',
                Product__c = product.Id,
                Order__c = order.Id,
                Order_Line_Id__c = orderItem.Id
        );
        TestUtils.insertAndAssert(lineItemBillingSchedule);

        final Contract contract = new Contract(
                AccountId = account.Id,
                SBQQ__Quote__c = quote.Id,
                SBQQ__Order__c = order.Id
        );
        TestUtils.insertAndAssert(contract);
        contract.Status = 'Activated';
        TestUtils.updateAndAssert(contract);

        final SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
                SBQQ__Account__c = account.Id,
                SBQQ__Contract__c = contract.Id,
                SBQQ__Quantity__c = 1
        );
        TestUtils.insertAndAssert(subscription);

        final Subscription__c wrikeSubscription = new Subscription__c (
                Account__c = account.Id,
                Status__c = 'Active'
        );
        insert wrikeSubscription;

        if(createdDate != null) {
            Test.setCreatedDate(account.Id, createdDate);
            final List<OpportunityData__c> oppData = getOppData();
            System.assert(!oppData.isEmpty());
            Test.setCreatedDate(oppData.get(0).Id, createdDate);
        }
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Email = :testEmail LIMIT 1];
    }

    private static List<Account> getAccounts() {
        return [SELECT Id FROM Account];
    }

    private static List<Opportunity> getOpportunities() {
        return [SELECT Id FROM Opportunity];
    }

    private static List<QS_Bill_To_Ship_To__c> getBillToShipTos() {
        return [SELECT Id FROM QS_Bill_To_Ship_To__c];
    }

    private static List<SBQQ__Quote__c> getQuotes() {
        return [SELECT Id FROM SBQQ__Quote__c];
    }

    private static List<SBQQ__QuoteLine__c> getQuoteLines() {
        return [SELECT Id FROM SBQQ__QuoteLine__c];
    }

    private static List<SBQQ__QuoteLineGroup__c> getQuoteLineGroups() {
        return [SELECT Id FROM SBQQ__QuoteLineGroup__c];
    }

    private static List<Order> getOrders() {
        return [SELECT Id FROM Order];
    }

    private static List<Contract> getContracts() {
        return [SELECT Id FROM Contract];
    }

    private static List<SBQQ__Subscription__c> getSubscriptions() {
        return [SELECT Id FROM SBQQ__Subscription__c];
    }

    private static List<Subscription__c> getWrikeSubscriptions() {
        return [SELECT Id FROM Subscription__c];
    }

    private static List<OpportunityData__c> getOppData() {
        return [SELECT Id FROM OpportunityData__c];
    }

    private static List<Line_Item_Billing_Schedule__c> getLineItemBillingSchedules() {
        return [SELECT Id FROM Line_Item_Billing_Schedule__c];
    }

    private static List<Billing_Schedule__c> getBillingSchedules() {
        return [SELECT Id FROM Billing_Schedule__c];
    }

    private static List<OfacCheck__c> getOfacChecks() {
        return [SELECT Id FROM OfacCheck__c];
    }

    private static List<Deployment__c> getWrikeDeployments() {
        return [SELECT Id FROM Deployment__c];
    }
}
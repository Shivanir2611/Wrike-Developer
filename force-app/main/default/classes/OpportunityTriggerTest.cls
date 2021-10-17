@IsTest
private class OpportunityTriggerTest {

    private static final String TestUserEmail = 'test.cpq.renewal@team.wrike.com';

    @TestSetup
    static void setup() {
        TestUtils.createUser('cpq.renewal', TestUserEmail, 'System Administrator');
    }

    @IsTest
    static void testCPQRenewalOpportunityCreation() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = TestDataFactory.createCPQContract(account.Id, 123);
        insert contract;
        Test.startTest();
        System.runAs(TestUtils.getUserByEmail(TestUserEmail)[0]) {
            final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
            insert opportunity;
            final Order order = createOrder(contract, opportunity.Id);
            contract.SBQQ__Quote__c = order.SBQQ__Quote__c;
            contract.SBQQ__Order__c = order.Id;
            update contract;
        }
        final Opportunity renewalOpportunity = [
            SELECT Id, SBQQ__RenewalOpportunity__r.OwnerId
            FROM Contract
            WHERE Id = :contract.Id
        ]?.SBQQ__RenewalOpportunity__r;
        System.assertNotEquals(null, renewalOpportunity);
        System.assertEquals(WrikeConstants.SF_ADMIN_ID, renewalOpportunity.OwnerId);
        Test.stopTest();
    }

    @IsTest
    static void testCPQRenewalOpportunityRelatedPartnerCreation() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contract contract = TestDataFactory.createCPQContract(account.Id, 123);
        insert contract;
        Test.startTest();
        System.runAs(TestUtils.getUserByEmail(TestUserEmail)[0]) {
            final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
            insert opportunity;
            final Order order = createOrder(contract, opportunity.Id);
            contract.SBQQ__Quote__c = order.SBQQ__Quote__c;
            contract.SBQQ__Order__c = order.Id;
            update contract;
        }
        final Opportunity renewalOpportunity = [
                SELECT Id, SBQQ__RenewalOpportunity__r.OwnerId
                FROM Contract
                WHERE Id = :contract.Id
        ]?.SBQQ__RenewalOpportunity__r;
        System.assertNotEquals(null, renewalOpportunity);
        System.assertEquals(WrikeConstants.SF_ADMIN_ID, renewalOpportunity.OwnerId);
        Test.stopTest();
    }

    @IsTest
    static void testCPQRenewalMigratedOpportunity() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Account partnerAccount = TestDataFactory.createAccount();
        partnerAccount.AgreementType__c = 'Reseller';
        insert partnerAccount;
        final Contract contract = TestDataFactory.createCPQContract(account.Id, 123);
//        insert contract;
//        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
//        insert opportunity;
//        final Order order = createOrder(contract, opportunity.Id);
        contract.ResellerAccount__c = partnerAccount.Id;
        contract.SBQQ__RenewalForecast__c = true;
        insert contract;
        final Id renewalOpportunityId = [
                SELECT Id, SBQQ__RenewalOpportunity__c
                FROM Contract
                WHERE Id = :contract.Id
        ]?.SBQQ__RenewalOpportunity__c;
        final List<Partner__c> relatedPartners = [
                SELECT Id, Partner__c
                FROM Partner__c
                WHERE Opportunity__c = :renewalOpportunityId
        ];
        System.assertEquals(1, relatedPartners.size());
        System.assertEquals(partnerAccount.Id, relatedPartners.get(0).Partner__c);
    }

    private static Order createOrder(final Contract contract, final Id opportunityId) {
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = contract.AccountId,
                SBQQ__Opportunity2__c = opportunityId,
                SBQQ__Primary__c = true,
                SBQQ__Status__c = 'Draft'
        );
        insert quote;
        final Order order = new Order(
                AccountId = contract.AccountId,
                SBQQ__Quote__c = quote.Id,
                QS_Bill_To__c = contract.QS_Bill_To__c,
                QS_Ship_To__c = contract.QS_Ship_To__c,
                WrikeAccountId__c = contract.Wrike_Account_ID__c,
                Status = 'Draft',
                EffectiveDate = Date.today()
        );
        insert order;
        return order;
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
        final Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Discovery',
                CloseDate = Date.today(),
                Department__c = 'IT',
                Billing__c = 'Credit Card',
                Billing_Terms__c = 'Monthly',
                Marketing_using_Wrike__c = 'No',
                Deployment__c = 'No',
                Employee_Size__c = 1000,
                Wrike_Account_Id__c = 1,
                Wrike_Data__c = wrikeData1.Id
        );
        insert opp;

        Test.startTest();
        opp.Wrike_Account_Id__c = 2;
        update opp;
        Test.stopTest();

        final Opportunity updatedOpp = [
                SELECT Wrike_Data__c
                FROM Opportunity
                WHERE Id = :opp.Id
        ];
        System.assertEquals(wrikeData2.Id, updatedOpp.Wrike_Data__c,
                'WrikeData was not updated for new wrike account id');
    }

    @IsTest
    static void testCreatedWithExistingWrikeData() {
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = 1
        );
        insert wrikeData;
        final Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Discovery',
                CloseDate = Date.today(),
                Department__c = 'IT',
                Billing__c = 'Credit Card',
                Billing_Terms__c = 'Monthly',
                Marketing_using_Wrike__c = 'No',
                Deployment__c = 'No',
                Employee_Size__c = 1000,
                Wrike_Account_Id__c = 1
        );
        insert opp;

        final Opportunity savedOpp = [
                SELECT Wrike_Data__c
                FROM Opportunity
                WHERE Id = :opp.Id
        ];
        System.assertEquals(wrikeData.Id, savedOpp.Wrike_Data__c, 'Wrike Data is not valid.');
    }

    @IsTest
    static void testUpdatedWithExistingWrikeData() {
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = 1
        );
        insert wrikeData;
        final Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Discovery',
                CloseDate = Date.today(),
                Department__c = 'IT',
                Billing__c = 'Credit Card',
                Billing_Terms__c = 'Monthly',
                Marketing_using_Wrike__c = 'No',
                Deployment__c = 'No',
                Employee_Size__c = 1000
        );
        insert opp;

        Test.startTest();
        opp.Wrike_Account_Id__c = 1;
        update opp;
        Test.stopTest();

        final Opportunity updatedOpp = [
                SELECT Wrike_Data__c
                FROM Opportunity
                WHERE Id = :opp.Id
        ];
        System.assertEquals(wrikeData.Id, updatedOpp.Wrike_Data__c, 'WrikeData should be set');
    }

    @IsTest
    static void testWrikeDataCreated() {
        final Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Discovery',
                CloseDate = Date.today(),
                Department__c = 'IT',
                Billing__c = 'Credit Card',
                Billing_Terms__c = 'Monthly',
                Marketing_using_Wrike__c = 'No',
                Deployment__c = 'No',
                Employee_Size__c = 1000
        );
        insert opp;

        Test.startTest();
        opp.Wrike_Account_Id__c = 1;
        update opp;
        Test.stopTest();

        final Opportunity updatedOpp = [
                SELECT Wrike_Data__r.Wrike_Account_Id__c
                FROM Opportunity
                WHERE Id = :opp.Id
        ];
        System.assert(updatedOpp.Wrike_Data__r != null, 'WrikeData should be created.');
        System.assertEquals(1, updatedOpp.Wrike_Data__r.Wrike_Account_Id__c,
                'Wrike Account Id of Wrike Data is not valid.');
    }

    @IsTest
    static void testWrikeDataRemoved() {
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = 1
        );
        insert wrikeData;
        final Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Discovery',
                CloseDate = Date.today(),
                Department__c = 'IT',
                Billing__c = 'Credit Card',
                Billing_Terms__c = 'Monthly',
                Marketing_using_Wrike__c = 'No',
                Deployment__c = 'No',
                Employee_Size__c = 1000,
                Wrike_Account_Id__c = 1,
                Wrike_Data__c = wrikeData.Id
        );
        insert opp;

        Test.startTest();
        opp.Wrike_Account_Id__c = null;
        update opp;
        Test.stopTest();

        final Opportunity updatedOpp = [
                SELECT Wrike_Data__c
                FROM Opportunity
                WHERE Id = :opp.Id
        ];
        System.assertEquals(null, updatedOpp.Wrike_Data__c, 'WrikeData should be updated to null');
    }

    @IsTest
    static void testDeploymentCreated() {
        System.runAs(TestUtils.getWrikeIntegrationUser()) {
            final Account account = TestDataFactory.createAccount();
            insert account;

            final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
            insert pricebook;

            final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
            opportunity.Pricebook2Id = pricebook.Id;
            opportunity.Deployment__c = 'Yes';
            opportunity.Wrike_Account_Id__c = 123;
            insert opportunity;

            final Product2 product = new Product2(
                    Name = 'Test Product',
                    ZuoraProductId__c = '1',
                    ZuoraServiceType__c = 'Implementation',
                    PG1__c = 'Services',
                    PG2__c = 'Deployment',
                    PG3__c = 'Integrate',
                    Deployment_Package2__c = 'Medium',
                    Deployment_Method__c = 'Onsite',
                    Budgeted_Hours__c = 5,
                    Delivery_Timeframe__c = 60
            );
            insert product;
            final PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(pricebook.Id, product.Id, 11.11);
            insert pricebookEntry;
            final OpportunityLineItem deploymentItem = new OpportunityLineItem(
                    OpportunityId = opportunity.Id,
                    Product2Id = product.Id,
                    PricebookEntryId = pricebookEntry.Id,
                    Quantity = 1,
                    UnitPrice = 12.12,
                    PG1__c = 'Services',
                    PG2__c = 'Deployment',
                    PG3__c = 'Integrate'
            );
            insert deploymentItem;

            Test.startTest();

            opportunity.StageName = 'Closed Won';
            opportunity.eCommerce__c = false;
            opportunity.Number_of_Users_in_Opportunity__c = 15;
            opportunity.Potential_License_Type__c = 'Enterprise';
            opportunity.Competitor_Lost_To__c = 'Asana';
            update opportunity;

            Test.stopTest();

            final List<Deployment__c> deployments = [
                    SELECT Name, Account__c, Opportunity__c, Status__c, Subscription__c, DeploymentEffectivePrice2__c,
                           DeploymentListPrice2__c, Deployment_Type2__c, Budgeted_Hours__c, Deployment_Method__c,
                           Original_Delivery_Deadline__c
                    FROM Deployment__c
            ];

            final String createdDate = DateUtils.format(DateUtils.getPacificLocalDate(), 'yyyyMMdd');

            System.assert(deployments.size() == 1, 'One deployment should be created.');
            System.assertEquals(account.Id, deployments[0].Account__c, 'Account is not valid.');
            System.assertEquals(null, deployments[0].Subscription__c, 'Subscription should be null.');
            System.assertEquals(opportunity.Id, deployments[0].Opportunity__c, 'Opportunity is not valid.');
            System.assertEquals('New', deployments[0].Status__c, 'Status is not valid.');
            System.assertEquals(TestDataFactory.TEST_NAME + ' Integrate Medium Onsite ' + createdDate, deployments[0].Name);
            System.assertEquals(12.12, deployments[0].DeploymentEffectivePrice2__c);
            System.assertEquals(11.11, deployments[0].DeploymentListPrice2__c);
            System.assertEquals('Integrate', deployments[0].Deployment_Type2__c);
            System.assertEquals('Onsite', deployments[0].Deployment_Method__c);
            System.assertEquals(opportunity.Id, deployments[0].Opportunity__c);
            System.assertEquals(5, deployments[0].Budgeted_Hours__c);
            System.assertEquals(DateUtils.getPacificLocalDate().addDays(60),
                    deployments[0].Original_Delivery_Deadline__c);
        }
    }

    @IsTest
    static void testAggregatedDeploymentCreated() {
        System.runAs(TestUtils.getWrikeIntegrationUser()) {
            final Account account = TestDataFactory.createAccount();
            insert account;

            final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
            insert pricebook;

            final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
            opportunity.Pricebook2Id = pricebook.Id;
            opportunity.Deployment__c = 'Yes';
            opportunity.Wrike_Account_Id__c = 123;
            insert opportunity;

            final Product2 product1 = new Product2(
                    Name = 'Test Product 1',
                    ZuoraProductId__c = '1',
                    ZuoraServiceType__c = 'Implementation',
                    PG1__c = 'Services',
                    PG2__c = 'Add On',
                    PG3__c = 'Standard',
                    Deployment_Package2__c = 'Add On',
                    Budgeted_Hours__c = 5,
                    Delivery_Timeframe__c = 20
            );
            insert product1;
            final PricebookEntry pricebookEntry1 = TestDataFactory.createPricebookEntry(pricebook.Id, product1.Id, 10);
            insert pricebookEntry1;
            final OpportunityLineItem deploymentItem1 = new OpportunityLineItem(
                    OpportunityId = opportunity.Id,
                    Product2Id = product1.Id,
                    PricebookEntryId = pricebookEntry1.Id,
                    Quantity = 1,
                    UnitPrice = 20,
                    PG1__c = 'Services',
                    PG2__c = 'Add On',
                    PG3__c = 'Standard'
            );
            insert deploymentItem1;

            final Product2 product2 = new Product2(
                    Name = 'Test Product 2',
                    ZuoraProductId__c = '2',
                    ZuoraServiceType__c = 'Implementation',
                    PG1__c = 'Services',
                    PG2__c = 'Add On',
                    PG3__c = 'Standard',
                    Deployment_Package2__c = 'Add On',
                    Budgeted_Hours__c = 10,
                    Delivery_Timeframe__c = 10
            );
            insert product2;
            final PricebookEntry pricebookEntry2 = TestDataFactory.createPricebookEntry(pricebook.Id, product2.Id, 30);
            insert pricebookEntry2;
            final OpportunityLineItem deploymentItem2 = new OpportunityLineItem(
                    OpportunityId = opportunity.Id,
                    Product2Id = product2.Id,
                    PricebookEntryId = pricebookEntry2.Id,
                    Quantity = 1,
                    UnitPrice = 40,
                    PG1__c = 'Services',
                    PG2__c = 'Add On',
                    PG3__c = 'Standard'
            );
            insert deploymentItem2;

            Test.startTest();

            opportunity.StageName = 'Closed Won';
            opportunity.eCommerce__c = false;
            opportunity.Number_of_Users_in_Opportunity__c = 15;
            opportunity.Potential_License_Type__c = 'Enterprise';
            opportunity.Competitor_Lost_To__c = 'Asana';
            update opportunity;

            Test.stopTest();

            final List<Deployment__c> deployments = [
                    SELECT Name, Account__c, Opportunity__c, Status__c, Subscription__c, DeploymentEffectivePrice2__c,
                            DeploymentListPrice2__c, Deployment_Type2__c, Budgeted_Hours__c, Deployment_Method__c,
                            Original_Delivery_Deadline__c
                    FROM Deployment__c
            ];

            final String createdDate = DateUtils.format(DateUtils.getPacificLocalDate(), 'yyyyMMdd');

            System.assert(deployments.size() == 1, 'One deployment should be created.');
            System.assertEquals(account.Id, deployments[0].Account__c, 'Account is not valid.');
            System.assertEquals(null, deployments[0].Subscription__c, 'Subscription should be null.');
            System.assertEquals(opportunity.Id, deployments[0].Opportunity__c, 'Opportunity is not valid.');
            System.assertEquals('New', deployments[0].Status__c, 'Status is not valid.');
            System.assertEquals(TestDataFactory.TEST_NAME + ' Add On Add On Remote ' + createdDate, deployments[0].Name);
            System.assertEquals(60, deployments[0].DeploymentEffectivePrice2__c);
            System.assertEquals(40, deployments[0].DeploymentListPrice2__c);
            System.assertEquals('Add On', deployments[0].Deployment_Type2__c);
            System.assertEquals('Remote', deployments[0].Deployment_Method__c);
            System.assertEquals(opportunity.Id, deployments[0].Opportunity__c);
            System.assertEquals(15, deployments[0].Budgeted_Hours__c);
            System.assertEquals(DateUtils.getPacificLocalDate().addDays(20),
                    deployments[0].Original_Delivery_Deadline__c);
        }
    }

    @IsTest
    static void testPinnacleDeploymentsCreated() {
            insert new Settings__c(
                    AnalyzeBasePrice__c = 5,
                    AnalyzeBaseBudgetedHours__c = 3,
                    ReportsMasterySilverPrice__c = 2
            );
            final Account account = TestDataFactory.createAccount();
            insert account;

            final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
            insert pricebook;

            final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
            opportunity.Pricebook2Id = pricebook.Id;
            opportunity.Deployment__c = 'Yes';
            opportunity.Wrike_Account_Id__c = 123;
            insert opportunity;

            final Product2 product = new Product2(
                    Name = 'Pinnacle A',
                    ZuoraProductId__c = '1',
                    ZuoraServiceType__c = 'Implementation',
                    PG1__c = 'Services',
                    PG2__c = 'Deployment',
                    PG3__c = 'Consulting Services',
                    Deployment_Package2__c = 'Pinnacle - A Base',
                    Deployment_Method__c = 'Remote',
                    Budgeted_Hours__c = 10,
                    Delivery_Timeframe__c = 60
            );
            insert product;
            final PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(pricebook.Id, product.Id, 20);
            insert pricebookEntry;
            final OpportunityLineItem deploymentItem = new OpportunityLineItem(
                    OpportunityId = opportunity.Id,
                    Product2Id = product.Id,
                    PricebookEntryId = pricebookEntry.Id,
                    Quantity = 1,
                    UnitPrice = 15,
                    PG1__c = 'Services',
                    PG2__c = 'Deployment',
                    PG3__c = 'Consulting Services'
            );
            insert deploymentItem;

            Test.startTest();

            opportunity.StageName = 'Closed Won';
            opportunity.eCommerce__c = false;
            opportunity.Number_of_Users_in_Opportunity__c = 15;
            opportunity.Potential_License_Type__c = 'Enterprise';
            opportunity.Competitor_Lost_To__c = 'Asana';
            update opportunity;

            Test.stopTest();

            final List<Deployment__c> deployments = [
                    SELECT Name, Account__c, Opportunity__c, Status__c, Subscription__c, DeploymentEffectivePrice2__c,
                            DeploymentListPrice2__c, Deployment_Type2__c, Budgeted_Hours__c, Deployment_Method__c,
                            Original_Delivery_Deadline__c, Deployment_Package2__c
                    FROM Deployment__c
                    ORDER BY Deployment_Type2__c
            ];

            final String createdDate = DateUtils.format(DateUtils.getPacificLocalDate(), 'yyyyMMdd');

            System.assert(deployments.size() == 2);
            System.assertEquals(account.Id, deployments[0].Account__c, 'Account is not valid.');
            System.assertEquals(null, deployments[0].Subscription__c, 'Subscription should be null.');
            System.assertEquals(opportunity.Id, deployments[0].Opportunity__c, 'Opportunity is not valid.');
            System.assertEquals('New', deployments[0].Status__c, 'Status is not valid.');
            System.assertEquals(TestDataFactory.TEST_NAME + ' - Pinnacle - A Base - Remote - ' + createdDate, deployments[0].Name);
            System.assertEquals(9.75, deployments[0].DeploymentEffectivePrice2__c);
            System.assertEquals(13, deployments[0].DeploymentListPrice2__c);
            System.assertEquals('Pinnacle - A Base', deployments[0].Deployment_Package2__c);
            System.assertEquals('Consulting Services', deployments[0].Deployment_Type2__c);
            System.assertEquals('Remote', deployments[0].Deployment_Method__c);
            System.assertEquals(opportunity.Id, deployments[0].Opportunity__c);
            System.assertEquals(7, deployments[0].Budgeted_Hours__c);
            System.assertEquals(DateUtils.getPacificLocalDate().addDays(60),
                    deployments[0].Original_Delivery_Deadline__c);

            System.assertEquals(TestDataFactory.TEST_NAME + ' - Pinnacle - Analyze Standard - Remote - ' + createdDate, deployments[1].Name);
            System.assertEquals(3.75, deployments[1].DeploymentEffectivePrice2__c);
            System.assertEquals(5, deployments[1].DeploymentListPrice2__c);
            System.assertEquals('Pinnacle - Analyze Standard', deployments[1].Deployment_Package2__c);
            System.assertEquals('SA Services', deployments[1].Deployment_Type2__c);
            System.assertEquals('Remote', deployments[1].Deployment_Method__c);
            System.assertEquals(opportunity.Id, deployments[1].Opportunity__c);
            System.assertEquals(3, deployments[1].Budgeted_Hours__c);
            System.assertEquals(DateUtils.getPacificLocalDate().addDays(60),
                    deployments[1].Original_Delivery_Deadline__c);

    }

    @IsTest
    static void testDeploymentCreatedWithSubscription() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
        insert pricebook;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        opportunity.Pricebook2Id = pricebook.Id;
        opportunity.Deployment__c = 'Yes';
        opportunity.Wrike_Account_Id__c = 123;
        insert opportunity;

        final Product2 product = new Product2(
                Name = 'Test Product',
                ZuoraProductId__c = '1',
                ZuoraServiceType__c = 'Implementation'
        );
        insert product;
        final PricebookEntry pricebookEntry = TestDataFactory.createPricebookEntry(pricebook.Id, product.Id, 11.11);
        insert pricebookEntry;
        final OpportunityLineItem deploymentItem = new OpportunityLineItem(
                OpportunityId = opportunity.Id,
                Product2Id = product.Id,
                PricebookEntryId = pricebookEntry.Id,
                Quantity = 1,
                UnitPrice = 12.12,
                PG1__c = 'Services',
                PG2__c = 'Deployment',
                PG3__c = 'Integrate'
        );
        insert deploymentItem;

        final Subscription__c subscription = new Subscription__c (
                Account__c = account.Id,
                Wrike_Account_Id__c = 123,
                MRR__c = 50,
                Status__c = 'Active'
        );
        insert subscription;

        Test.startTest();

        opportunity.StageName = 'Closed Won';
        opportunity.eCommerce__c = false;
        opportunity.Number_of_Users_in_Opportunity__c = 15;
        opportunity.Potential_License_Type__c = 'Enterprise';
        opportunity.Competitor_Lost_To__c = 'Asana';
        update opportunity;

        Test.stopTest();

        final List<Deployment__c> deployments = [
                SELECT Name, Account__c, Opportunity__c, Status__c, Subscription__c
                FROM Deployment__c
        ];
        System.assert(deployments.size() == 1, 'One deployment should be created.');
        System.assert(deployments[0].Account__c == account.Id, 'Account is not valid.');
        System.assertEquals(subscription.Id, deployments[0].Subscription__c);
        System.assert(deployments[0].Opportunity__c == opportunity.Id, 'Opportunity is not valid.');
        System.assert(deployments[0].Status__c == 'New', 'Status is not valid.');
    }

    @IsTest
    static void testInsertOpportunity() {
        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 123);

        Test.startTest();
        TestUtils.insertAndAssert(testOpportunity);
        Test.stopTest();

        Opportunity foundOpportunity = TestUtils.findOpportunityById(testOpportunity.Id);
        System.assert(foundOpportunity.OpportunityData__c != null);
    }

    @IsTest
    static void testInsertMultipleOpportunities() {
        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity1 = TestDataFactory.createOpportunity(testAccount.Id, 123);
        Opportunity testOpportunity2 = TestDataFactory.createOpportunity(testAccount.Id, 123);

        Test.startTest();
        TestUtils.insertAndAssert(new List<Opportunity>{testOpportunity1, testOpportunity2});
        Test.stopTest();

        List<Opportunity> opportunities = TestUtils.getOpportunities();
        System.assertEquals(2, opportunities.size());
        System.assert(opportunities.get(0).OpportunityData__c != null);
        System.assert(opportunities.get(1).OpportunityData__c != null);
    }

    @IsTest
    static void testDeleteOpportunity() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 123);
        TestUtils.insertAndAssert(testOpportunity);

        Quote__c quote1 = TestDataFactory.insertDraftSubscriptionQuote(testOpportunity.Id);
        quote1.Status__c = WrikeQuote.Status.TRIAL.name();
        TestUtils.updateAndAssert(quote1);
        Quote__c quote2 = TestDataFactory.insertDraftSubscriptionQuote(testOpportunity.Id);
        quote2.Status__c = WrikeQuote.Status.TRIAL.name();
        TestUtils.updateAndAssert(quote2);

        List<Quote__c> quotesWithItems = TestUtils.findQuotes();

        WrikeHttpMock wrikeMock = new WrikeHttpMock();
        Test.setMock(HttpCalloutMock.class, wrikeMock);

        Test.startTest();

        TestUtils.deleteAndAssert(testOpportunity);

        Test.stopTest();

        List<Quote__c> quotesAfterDeleteOpportunity = TestUtils.findQuotes();
        System.assertEquals(0, quotesAfterDeleteOpportunity.size());

        List<String> quoteProductIds =
                SobjectUtils.extractNotNullByFieldName(quotesWithItems.get(0).Quote_Items__r, 'Product__c');
        quoteProductIds.addAll(
                SobjectUtils.extractNotNullByFieldName(quotesWithItems.get(1).Quote_Items__r, 'Product__c'));
        List<Quote_Product__c> quoteProducts = TestUtils.findQuoteProductsByIds(quoteProductIds);
        System.assertEquals(0, quoteProducts.size());

        WrikeHttpMock.assertNumberOfActionInvocation('delete_quotes', 1);
    }

    @IsTest
    static void testLastDateUpdate() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        opportunity.StageName = '1-Connect';
        insert opportunity;

        Test.startTest();
        opportunity.StageName = '2-Create';
        update opportunity;
        Test.stopTest();

        final Opportunity updatedOpportunity = findUpdatedOpportunity(opportunity.Id);

        System.assertEquals(Date.today(), updatedOpportunity.Trial_Stage_Last_Date__c);
    }

    @IsTest
    static void testLastDateUpdateConnectAndDemoPursue() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        opportunity.StageName = '0-MQL';
        opportunity.Meeting_Accepted__c = true;
        insert opportunity;

        Test.startTest();
        opportunity.StageName = '1-Connect';
        opportunity.Demo_Pursue__c = true;
        update opportunity;
        Test.stopTest();

        final Opportunity updatedOpportunity = findUpdatedOpportunity(opportunity.Id);

        System.assertEquals(Date.today(), updatedOpportunity.Trial_Stage_Last_Date__c);
    }

    @IsTest
    static void testLastDateUpdateNonBlank() {
        final Account account = TestDataFactory.createAccount();
        insert account;

        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        opportunity.StageName = '1-Connect';
        opportunity.Trial_Stage_Last_Date__c = Date.parse('10/10/2019');
        insert opportunity;

        Test.startTest();
        opportunity.StageName = '2-Create';
        update opportunity;
        Test.stopTest();

        final Opportunity updatedOpportunity = findUpdatedOpportunity(opportunity.Id);

        System.assertEquals(Date.parse('10/10/2019'), updatedOpportunity.Trial_Stage_Last_Date__c);
    }

    @IsTest
    static void testTaskReassignment() {
        final Id newOwnerId = TestUtils.findNonAdminAssigneeId();
        final Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                StageName = 'Discovery',
                CloseDate = Date.today(),
                Department__c = 'IT',
                Billing__c = 'Credit Card',
                Billing_Terms__c = 'Monthly',
                Marketing_using_Wrike__c = 'No',
                Employee_Size__c = 1000,
                Wrike_Account_Id__c = 123
        );
        insert opp;
        final Task task = new Task(
                WhatId = opp.Id,
                Status = 'Open',
                Subject = 'Test Task',
                ActivityDate = Date.today()
        );
        insert task;

        Test.startTest();
        opp.OwnerId = newOwnerId;
        update opp;
        Test.stopTest();

        System.assertEquals(newOwnerId, findTaskOwnerId(task.Id), 'Task was not reassigned');
    }

    private static Id findTaskOwnerId(final Id taskId) {
        return [
                SELECT OwnerId
                FROM Task
                WHERE Id = :taskId
        ].OwnerId;
    }

    private static Opportunity findUpdatedOpportunity(final Id opportunityId) {
        return [
                SELECT Id, Trial_Stage_Last_Date__c
                FROM Opportunity
                WHERE Id = :opportunityId
        ];
    }
}
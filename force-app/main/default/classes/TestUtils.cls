@IsTest
public class TestUtils {

    public static final String WRIKE_INTEGRATION_USER_EMAIL = 'salesforce.integration@team.wrike.com';

    public static void insertAndAssert(sObject sObj) {
        Database.SaveResult saveResult = Database.insert(sObj);
        System.assert(saveResult.isSuccess(), saveResult.getErrors());
    }

    public static void insertAndAssert(List<sObject> sObjs) {
        List<Database.SaveResult> saveResults = Database.insert(sObjs);
        for (Database.SaveResult saveResult : saveResults) {
            System.assert(saveResult.isSuccess(), saveResult.getErrors());
        }
    }

    public static void updateAndAssert(sObject sObj) {
        Database.SaveResult saveResult = Database.update(sObj);
        System.assert(saveResult.isSuccess(), saveResult.getErrors());
    }

    public static void deleteAndAssert(sObject sObj) {
        Database.DeleteResult saveResult = Database.delete(sObj);
        System.assert(saveResult.isSuccess(), saveResult.getErrors());
    }

    public static void deleteAndAssert(sObject[] sObjList) {
        Database.DeleteResult[] saveResults = Database.delete(sObjList);
        for (Database.DeleteResult deleteResult : saveResults) {
            System.assert(deleteResult.isSuccess(), deleteResult.getErrors());
        }
    }

    public static List<Contact> getContacts() {
        return [
            SELECT Id, MailingCountry, MailingCountryCode, AccountId, OwnerId, Account.OwnerId
            FROM Contact
        ];
    }

    public static Opportunity findOpportunityById(final Id opportunityId) {
        return [
            SELECT Id, OpportunityData__c
            FROM Opportunity
            WHERE Id = :opportunityId
        ];
    }

    public static List<Opportunity> getOpportunities() {
        return [
            SELECT Id, Billing_Contact__c, VAT__c, BillingCountryCode__c, OpportunityData__c
            FROM Opportunity
        ];
    }

    public static Opportunity findOpportunity() {
        List<Opportunity> opportunities = getOpportunities();
        System.assertEquals(1, opportunities.size());
        return opportunities.get(0);
    }

    public static List<OpportunityContactRole> getOpportunityContactRoles() {
        return [
            SELECT Id, OpportunityId, ContactId
            FROM OpportunityContactRole
        ];
    }

    public static User getActiveUser() {
        final User activeUser = new User(
                Alias = 'standt',
                Email='standarduser@test.com',
                EmailEncodingKey='UTF-8',
                LastName='Testing',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
                TimeZoneSidKey='America/Los_Angeles',
                UserName='testuserwrke@test.com');
        insert activeUser;
        return activeUser;
    }

    public static List<User> getUsersByApproverLevelAndType(String approverLevel, String opportunityApproverType) {
        return [
            SELECT Id, OpportunityApproverType__c
            FROM User
            WHERE ApproverLevel__c >= :approverLevel
                AND OpportunityApproverType__c INCLUDES (:opportunityApproverType)
                AND IsActive = true
        ];
    }

    public static List<User> getUserById(String userId) {
        return [
            SELECT Id, ApproverLevel__c, OpportunityApproverType__c
            FROM User
            WHERE Id = :userId
        ];
    }

    public static List<User> getUserByEmail(String email) {
        return [
            SELECT Id, Email
            FROM User
            WHERE Email = :email
                AND IsActive = true
        ];
    }

    public static User getWrikeIntegrationUser() {
        List<User> wrikeIntegrationUsers = getUserByEmail(WRIKE_INTEGRATION_USER_EMAIL);
        System.assert(wrikeIntegrationUsers.size() > 0, 'Wrike Integration User do not exist.');
        return wrikeIntegrationUsers[0];
    }

    public static User findOtherSystemAdminUser() {
        return [
            SELECT Id, Email
            FROM User
            WHERE Profile.Name = 'System Administrator'
              AND Email != :UserInfo.getUserEmail()
              AND IsActive = true
            LIMIT 1
        ];
    }

    public static Id findNonAdminAssigneeId() {
        final List<PermissionSetAssignment> assignments =  [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetId IN (
                SELECT ParentId
                FROM ObjectPermissions
                WHERE SObjectType = 'Account'
                AND PermissionsEdit = true)
                AND Assignee.IsActive = true
                AND (NOT Assignee.Name LIKE '%Marketo%')
                AND (NOT Assignee.Profile.Name LIKE '%Marketo%'
            )
            AND Assignee.Profile.Name != 'System Administrator'
            AND PermissionSet.IsOwnedByProfile = true
            LIMIT 1
        ];
        return assignments.isEmpty() ? null : assignments[0].AssigneeId;
    }

    public static User createUser(final String alias, final String email, final String profile) {
        final User user = new User(
            Alias = alias.left(8),
            Email = email,
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = email,
            ProfileId = [SELECT Id FROM Profile WHERE Name = :profile].Id
        );
        insert user;
        return user;
    }

    public static List<Log__c> getLogs() {
        return [
            SELECT Id, Message__c, Details__c, Type__c
            FROM Log__c
        ];
    }

    public static List<CronTrigger> findCronTriggersLikeJobName(final String jobNamePrefix) {
        final String jobName = jobNamePrefix + '%';
        return [
            SELECT Id, CronJobDetailId, NextFireTime, PreviousFireTime, State, StartTime, EndTime, CronExpression,
                TimeZoneSidKey, OwnerId, LastModifiedById, CreatedById, CreatedDate, TimesTriggered,
                CronJobDetail.JobType, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :jobName
        ];
    }

    public static List<Quote__c> findQuotes() {
        return [
            SELECT Id, Name, Status__c, PurchaseOrderAttachmentId__c, Pdf_Id__c,
                (
                    SELECT Id, Key__c
                    FROM Quote_Operations__r
                ),
                (
                    SELECT Id, Product__c
                    FROM Quote_Items__r
                )
            FROM Quote__c
        ];
    }

    public static List<Quote__c> findQuoteById(final String quoteId) {
        return [
            SELECT Id, Name, Status__c, Primary__c,
                (
                    SELECT Id, Product__c
                    FROM Quote_Items__r
                )
            FROM Quote__c
            WHERE Id = :quoteId
        ];
    }

    public static List<Quote_Product__c> findQuoteProductsByIds(final List<String> quoteProductIds) {
        return [
            SELECT Id, Name
            FROM Quote_Product__c
            WHERE Id IN :quoteProductIds
        ];
    }

    public static List<Attachment> getAttachment(String attachmentId) {
        return [
            SELECT Id
            FROM Attachment
            WHERE Id = :attachmentId
        ];
    }

    public static List<Group> findGroupByTypeAndDevName(final String groupType, final String groupDevName) {
        return [
            SELECT Id
            FROM Group
            WHERE Type = :groupType
                AND DeveloperName = :groupDevName
        ];
    }

    public static List<Lead> findLeadByEmail(final String email) {
        return [
            SELECT Id, OwnerId, LeadSource, Firstname, Lastname, Email, Phone, Company, Website, Industry, NumberOfEmployees,
                   Self_Selected_Employee_Size__c, Title, CountryCode, Country, StateCode, State, City, Street, PostalCode,
                   Lead_Sub_Source__c, EmailData__c, Scoring_Data__c, Status, Contact__c,
                   (
                       SELECT Id, ParentId, Title, Body
                       FROM Notes
                   )
            FROM Lead
            WHERE Email = :email
        ];
    }

    public static List<Lead> findLeads() {
        return [
            SELECT Id, OwnerId, LeadSource, Firstname, Lastname, Email, Phone, Company, Industry, NumberOfEmployees,
                Title, CountryCode, StateCode, City, Street, PostalCode, CountryData__c
            FROM Lead
        ];
    }

    public static Lead findLead() {
        List<Lead> leads = findLeads();
        System.assertEquals(1, leads.size());
        return leads.get(0);
    }

    public static Lead findLeadById(String leadId) {
        return [
            SELECT Id, LastModifiedDate, OwnerId, LeadSource, Firstname, Lastname, Email, Phone, Company, Industry, NumberOfEmployees,
                   Title, CountryCode, StateCode, City, Street, PostalCode, HasOptedOutOfEmail, Referral_Code__c, EmailData__c, Scoring_Data__c
            FROM Lead
            WHERE Id = :leadId
        ];
    }

    public static Account findAccountByName(final String name) {
        final List<Account> accounts = [
            SELECT Id, Name, Email_Domain__c
            FROM Account
        ];
        System.assert(!accounts.isEmpty(), 'Account not found.');
        return accounts.get(0);
    }

    public static Contact findContact() {
        final List<Contact> contacts = [
                SELECT Id, Wrike_User_Status__c, Wrike_User_Type__c, Subscription_NPS_Score__c, Subscription_License_Seats__c,
                       Subscriptions_Users_Sum__c, Subscriptions_Collaborators_Sum__c, Subscription_Health_Score__c,
                       Subscription_Last_Activity_Date__c, Subscription_Paid_Date__c, AccountId, RecordTypeId
                FROM Contact
        ];
        System.assert(!contacts.isEmpty(), 'Contact not found.');
        return contacts.get(0);
    }

    public static Contact findContactById(final Id contactId) {
        return [
            SELECT Id, Email, HasOptedOutOfEmail, EmailData__c
            FROM Contact
            WHERE Id = :contactId
        ];
    }


    public static Account findAccountById(final String accountId) {
        final List<Account> accounts = [
            SELECT Type, Primary_CSM__c, Wrike_Subscription_Terms__c, BillingCountryCode, BillingStateCode, BillingCity, BillingStreet,
                BillingPostalCode, Subscription_MRR_Sum__c, Subscription_Users_Sum__c, Subscription_Collaborators_Sum__c,
                Subscription_License_Users_Sum__c, Subscription_Upgrade_Score__c, Email_Domain__c, Last_Evaluated_Date__c, Customer_MRR_Sum__c
            FROM Account
            WHERE Id = :accountId
        ];
        System.assert(!accounts.isEmpty(), 'Account not found.');
        return accounts.get(0);
    }

    public static List<Account> findAccounts() {
        return [
            SELECT Id
            FROM Account
        ];
    }

    public static Account findAccount() {
        List<Account> accounts = findAccounts();
        System.assertEquals(1, accounts.size());
        return accounts.get(0);
    }

    public static List<Activity__c> findActivityForLead(final String leadId) {
        return [
            SELECT Id, Task_Id__c, Type__c, Sub_Type__c, Subject__c, Duration__c
            FROM Activity__c
            WHERE Activity_Data__c IN (
                SELECT Activity_Data__c
                FROM Lead
                WHERE Id = :leadId
            )
        ];
    }

    public static List<Activity__c> findActivityForContact(final String contactId) {
        return [
            SELECT Id, Task_Id__c, Type__c, Sub_Type__c, Subject__c, Duration__c
            FROM Activity__c
            WHERE Activity_Data__c IN (
                SELECT Activity_Data__c
                FROM Contact
                WHERE Id = :contactId
            )
        ];
    }

    public static Subscription__c findSubscriptionById(final Id subscriptionId) {
        return [
            SELECT Id, Name, Wrike_Account_Id__c, Last_Evaluated_Date__c
            FROM Subscription__c
            WHERE Id = :subscriptionId
        ];
    }

    public static List<Subscription__c> findSubscriptions() {
        return [
            SELECT Id, LastDeployment__c, DeploymentStatus__c, DeploymentStartDateTime__c, DeploymentEndDateTime__c, DeploymentPackage__c
            FROM Subscription__c
        ];
    }

    public static List<Deployment__c> findDeployments() {
        return [
            SELECT Id, Subscription__c, Status__c, Start_Date__c, End_Date__c, Deployment_Package__c
            FROM Deployment__c
            ORDER BY CreatedDate ASC
        ];
    }

    public static Deployment__c findDeploymentById(final Id deploymentId) {
        final List<Deployment__c> deployments = [
                SELECT Id, Subscription__c, Status__c, Start_Date__c, End_Date__c, Deployment_Package__c
                FROM Deployment__c
                WHERE Id = :deploymentId
        ];
        System.assertEquals(1, deployments.size(), 'Deployment not found.');
        return deployments.get(0);
    }

    public class ZuoraRestMock implements HttpCalloutMock {

        private final String accessToken = 'abcd1234';

        private HttpResponse queryRes;

        public ZuoraRestMock(HttpResponse queryRes) {
            this.queryRes = queryRes;
        }

        public HttpResponse respond(HttpRequest req) {
            if (req.getEndpoint().endsWith('/oauth/token')) {

                System.assertEquals('application/x-www-form-urlencoded', req.getHeader('Content-Type'));
                System.assert(req.getBody().contains('client_id'));
                System.assert(req.getBody().contains('client_secret'));

                HttpResponse tokenRes = new HttpResponse();
                tokenRes.setHeader('Content-Type', 'application/json');
                tokenRes.setBody('{"access_token":"' + accessToken + '"}');
                tokenRes.setStatusCode(200);
                return tokenRes;
            }

            System.assertEquals(accessToken, CacheService.getInstance().getZuoraToken());
            System.assertEquals('application/json', req.getHeader('Content-Type'));
            System.assertEquals('Bearer ' + accessToken, req.getHeader('Authorization'));

            return queryRes;
        }
    }

    public static void createAndInsertWrikeProducts() {
        final Product2 professionalLicensesProduct = new Product2();
        professionalLicensesProduct.Name = 'Professional Licenses';
        professionalLicensesProduct.ZuoraName__c = 'Professional Licenses';
        professionalLicensesProduct.IsActive = true;
        professionalLicensesProduct.ZuoraServiceType__c = 'Premium2016Seats';
        professionalLicensesProduct.ZuoraProductId__c = '2c92c0f85313118601531cccab441750';
        insert professionalLicensesProduct;

        final Product2 businessSubscriptionLicensesProduct = new Product2();
        businessSubscriptionLicensesProduct.Name = 'Business Subscription Licenses';
        businessSubscriptionLicensesProduct.ZuoraName__c = 'Business Subscription Licenses';
        businessSubscriptionLicensesProduct.IsActive = true;
        businessSubscriptionLicensesProduct.ZuoraServiceType__c = 'BusinessSeats';
        businessSubscriptionLicensesProduct.ZuoraProductId__c = '2c92c0f853cf91bb0153ebb4609c7dab';
        insert businessSubscriptionLicensesProduct;

        final Product2 enterpriseSubscriptionLicensesProduct = new Product2();
        enterpriseSubscriptionLicensesProduct.Name = 'Enterprise Subscription Licenses';
        enterpriseSubscriptionLicensesProduct.ZuoraName__c = 'Enterprise Subscription Licenses';
        enterpriseSubscriptionLicensesProduct.IsActive = true;
        enterpriseSubscriptionLicensesProduct.ZuoraServiceType__c = 'EnterpriseSeats';
        enterpriseSubscriptionLicensesProduct.ZuoraProductId__c = '2c92c0f94b4e2e1b014b56830eb27ea9';
        insert enterpriseSubscriptionLicensesProduct;

        final Product2 proofingAddonProduct = new Product2();
        proofingAddonProduct.Name = 'Wrike Proof';
        proofingAddonProduct.ZuoraName__c = 'Wrike Proof';
        proofingAddonProduct.EnabledLicenses__c = 'Professional; Business; Enterprise';
        proofingAddonProduct.IsActive = true;
        proofingAddonProduct.ZuoraServiceType__c = 'ProofingAddon';
        proofingAddonProduct.ZuoraProductId__c = '2c92c0f9555cf10501555f48eee836c0';
        insert proofingAddonProduct;

        final Product2 publishAddonProduct = new Product2();
        publishAddonProduct.Name = 'Wrike Publish';
        publishAddonProduct.ZuoraName__c = 'Wrike Publish';
        publishAddonProduct.EnabledLicenses__c = 'Business; Enterprise';
        publishAddonProduct.IsActive = true;
        publishAddonProduct.ZuoraServiceType__c = 'DamAddon';
        publishAddonProduct.ZuoraProductId__c = '2c92c0f966a9b7430166ab03d14470fd';
        insert publishAddonProduct;

        final Product2 integrateAddonProduct = new Product2();
        integrateAddonProduct.Name = 'Wrike Integrate';
        integrateAddonProduct.ZuoraName__c = 'Wrike Integrate';
        integrateAddonProduct.EnabledLicenses__c = 'Business; Enterprise';
        integrateAddonProduct.IsActive = true;
        integrateAddonProduct.ZuoraServiceType__c = 'IntegrateAddon';
        integrateAddonProduct.ZuoraProductId__c = '2c92c0f8661febcb016634ff5bf809b0';
        insert integrateAddonProduct;

        final Product2 resourceAddonProduct = new Product2();
        resourceAddonProduct.Name = 'Wrike Resource';
        resourceAddonProduct.ZuoraName__c = 'Wrike Resource';
        resourceAddonProduct.EnabledLicenses__c = 'Business; Enterprise';
        resourceAddonProduct.IsActive = true;
        resourceAddonProduct.ZuoraServiceType__c = 'ResourceAddon';
        resourceAddonProduct.ZuoraProductId__c = '2c92c0f964cff4f30164daf550f260e3';
        insert resourceAddonProduct;

        final Product2 analyzeAddonProduct = new Product2();
        analyzeAddonProduct.Name = 'Wrike Analyze';
        analyzeAddonProduct.ZuoraName__c = 'Wrike Analyze';
        analyzeAddonProduct.EnabledLicenses__c = 'Business; Enterprise';
        analyzeAddonProduct.IsActive = true;
        analyzeAddonProduct.ZuoraServiceType__c = 'AnalyzeAddon';
        analyzeAddonProduct.ZuoraProductId__c = '2c92c0f96ce30c37016cf303e0e47245';
        insert analyzeAddonProduct;

        final Product2 lockAddonProduct = new Product2();
        lockAddonProduct.Name = 'Wrike Lock';
        lockAddonProduct.ZuoraName__c = 'Wrike Lock';
        lockAddonProduct.EnabledLicenses__c = 'Enterprise';
        lockAddonProduct.IsActive = true;
        lockAddonProduct.ZuoraServiceType__c = 'WrikeLockAddon';
        lockAddonProduct.ZuoraProductId__c = '2c92c0f965ad723b0165af33cb547f2d';
        insert lockAddonProduct;

        final WrikePackage__c wrikePerformancePackage = new WrikePackage__c();
        wrikePerformancePackage.Name = 'Wrike Performance Package';
        insert wrikePerformancePackage;

        final Product2 wrikePerformancePackageProduct = new Product2();
        wrikePerformancePackageProduct.WrikePackage__c = wrikePerformancePackage.Id;
        wrikePerformancePackageProduct.Name = 'Wrike Performance Package';
        wrikePerformancePackageProduct.ZuoraName__c = 'Wrike Performance Package';
        wrikePerformancePackageProduct.EnabledLicenses__c = 'Business; Enterprise';
        wrikePerformancePackageProduct.IsActive = true;
        wrikePerformancePackageProduct.ZuoraServiceType__c = 'WrikePerformancePackage';
        wrikePerformancePackageProduct.ZuoraProductId__c = '2c92c0f86d2a27de016d2bfd85254b44';
        insert wrikePerformancePackageProduct;

        final WrikePackage__c wrikeForMarketersPackage = new WrikePackage__c();
        wrikeForMarketersPackage.Name = 'Wrike for Marketers Package';
        insert wrikeForMarketersPackage;

        final Product2 wrikeForMarketersPackageProduct = new Product2();
        wrikeForMarketersPackageProduct.WrikePackage__c = wrikeForMarketersPackage.Id;
        wrikeForMarketersPackageProduct.Name = 'Wrike for Marketers Package';
        wrikeForMarketersPackageProduct.ZuoraName__c = 'Wrike for Marketers Package';
        wrikeForMarketersPackageProduct.EnabledLicenses__c = 'Business; Enterprise';
        wrikeForMarketersPackageProduct.IsActive = true;
        wrikeForMarketersPackageProduct.ZuoraServiceType__c = 'WrikeForMarketersPackage';
        wrikeForMarketersPackageProduct.ZuoraProductId__c = '2c92c0f86905128201690b5d9efe224c';
        insert wrikeForMarketersPackageProduct;

        final WrikePackage__c wrikeForProfessionalServicesPackage = new WrikePackage__c();
        wrikeForProfessionalServicesPackage.Name = 'Wrike for Professional Services Package';
        insert wrikeForProfessionalServicesPackage;

        final Product2 wrikeForProfessionalServicesPackageProduct = new Product2();
        wrikeForProfessionalServicesPackageProduct.WrikePackage__c = wrikeForProfessionalServicesPackage.Id;
        wrikeForProfessionalServicesPackageProduct.Name = 'Wrike for Professional Services Package';
        wrikeForProfessionalServicesPackageProduct.ZuoraName__c = 'Wrike for Professional Services Package';
        wrikeForProfessionalServicesPackageProduct.EnabledLicenses__c = 'Business; Enterprise';
        wrikeForProfessionalServicesPackageProduct.IsActive = true;
        wrikeForProfessionalServicesPackageProduct.ZuoraServiceType__c = 'WrikeForProfessionalServicesPackage';
        wrikeForProfessionalServicesPackageProduct.ZuoraProductId__c = '2c92c0f86d2a27e6016d2a4baa4d6cd1';
        insert wrikeForProfessionalServicesPackageProduct;

        final WrikePackageItem__c integrateAddonWP = new WrikePackageItem__c();
        integrateAddonWP.WrikePackage__c = wrikePerformancePackage.Id;
        integrateAddonWP.Product__c = integrateAddonProduct.Id;
        insert integrateAddonWP;

        final WrikePackageItem__c analyzeAddonWP = new WrikePackageItem__c();
        analyzeAddonWP.WrikePackage__c = wrikePerformancePackage.Id;
        analyzeAddonWP.Product__c = analyzeAddonProduct.Id;
        insert analyzeAddonWP;

        final WrikePackageItem__c proofingAddonWFM = new WrikePackageItem__c();
        proofingAddonWFM.WrikePackage__c = wrikeForMarketersPackage.Id;
        proofingAddonWFM.Product__c = proofingAddonProduct.Id;
        insert proofingAddonWFM;

        final WrikePackageItem__c publishAddonWFM = new WrikePackageItem__c();
        publishAddonWFM.WrikePackage__c = wrikeForMarketersPackage.Id;
        publishAddonWFM.Product__c = publishAddonProduct.Id;
        insert publishAddonWFM;

        final WrikePackageItem__c resourceAddonWFPS = new WrikePackageItem__c();
        resourceAddonWFPS.WrikePackage__c = wrikeForProfessionalServicesPackage.Id;
        resourceAddonWFPS.Product__c = resourceAddonProduct.Id;
        insert resourceAddonWFPS;
    }

    public static Id createPricebookEntry(final Id productId, final Id priceBookId, final Decimal unitPrice) {
        final PricebookEntry standardPricebookEntry = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = productId,
                UnitPrice = unitPrice,
                CurrencyIsoCode = 'USD'
        );
        insert standardPricebookEntry;
        final PricebookEntry pricebookEntry = new PricebookEntry(
                Pricebook2Id = priceBookId,
                Product2Id = productId,
                UnitPrice = unitPrice,
                IsActive = true,
                CurrencyIsoCode = 'USD'
        );
        insert pricebookEntry;
        return pricebookEntry.Id;
    }

    public static Id createContentDocument() {
        final ContentVersion contentVersion = new ContentVersion(
                Title = 'Test Document',
                ContentUrl = 'http://www.google.com/'
        );
        insert contentVersion;
        return [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :contentVersion.Id
        ]?.ContentDocumentId;
    }

    public static CPQRestService.CPQRestBillToShipTo defaultBillToShipTo() {
        final CPQRestService.CPQRestBillToShipTo billToShipTo = new CPQRestService.CPQRestBillToShipTo();
        billToShipTo.userName = 'Test User';
        billToShipTo.email = 'test.user@address.com';
        billToShipTo.countryCode = 'US';
        billToShipTo.stateCode = 'CA';
        billToShipTo.city = 'San Jose';
        billToShipTo.address1 = 'N 2nd Street';
        billToShipTo.address2 = '70';
        billToShipTo.postalCode = '95113';
        billToShipTo.stateName = 'California';
        return billToShipTo;
    }
}
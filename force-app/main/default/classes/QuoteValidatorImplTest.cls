@IsTest
public class QuoteValidatorImplTest {

    static {
        TestUtils.createAndInsertWrikeProducts();
        TestDataFactory.insertSettings();
        TestDataFactory.insertSalesSettings();
    }

    @IsTest
    static void testValidateSuccess() {
        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Business Subscription Licenses',
                                                                                   'Wrike Analyze',
                                                                                   'Wrike for Marketers Package' });
        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assert(messages.isEmpty(), messages);
    }

    @IsTest
    static void testValidateDifferentLicenses() {
        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Professional Licenses',
                                                                                   'Business Subscription Licenses' });
        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('You can\'t have different license products per Zuora subscription.',
                messages.get(0), messages);
    }

    @IsTest
    static void testValidateNoLicenses() {
        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Wrike Performance Package',
                                                                                   'Wrike for Marketers Package' });
        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('You should have at least one licence product in the quote.',
                messages.get(0), messages);
    }

    @IsTest
    static void testValidateMinimalPlan() {
        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Wrike Lock',
                                                                                   'Business Subscription Licenses' });
        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('Wrike Lock is only available for Enterprise licenses.', messages.get(0), messages);
    }

    @IsTest
    static void testValidateAddonAlreadyInPackage() {
        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Enterprise Subscription Licenses',
                                                                                   'Wrike for Marketers Package',
                                                                                   'Wrike Proof' });
        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('Wrike Proof is already included in Wrike for Marketers Package.', messages.get(0), messages);
    }

    @IsTest
    static void testValidateWrikeLock() {
        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Enterprise Subscription Licenses',
                                                                                   'Wrike Analyze',
                                                                                   'Wrike Lock' });
        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('Wrike Analyze can not be combined with Wrike Lock.', messages.get(0), messages);
    }

    @IsTest
    static void testWrikePerformancePackageWithoutWfPSOrWfMPackages() {
        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Enterprise Subscription Licenses',
                                                                                   'Wrike Performance Package' });
        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('Wrike Performance Package can only be included if WfPS or WfM is included ' +
                'or has already been purchased.', messages.get(0), messages);
    }

    @IsTest
    static void testInvalidLicenseQuantity() {
        final WrikeQuote quote = new WrikeQuote();
        quote.quoteType = WrikeQuote.QuoteType.SUBSCRIPTION;
        quote.addItem(WrikeQuoteItem.State.ADDED,
                createWrikeQuoteProduct('Business Subscription Licenses', 6, 'Annual'));

        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('Please enter a valid quantity for the license product. ' +
                'Possible options are increments of 5 (5, 10, 15, 20, 25 etc.).', messages.get(0), messages);
    }

    @IsTest
    static void testProfessionalUsersLimitExceeded() {
        final WrikeQuote quote = new WrikeQuote();
        quote.quoteType = WrikeQuote.QuoteType.SUBSCRIPTION;
        quote.addItem(WrikeQuoteItem.State.ADDED, createWrikeQuoteProduct('Professional Licenses', 20, 'Annual'));

        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('We do not sell professional in tiers higher than 15 users. ' +
                'Please upgrade to enterprise if you would like to send a quote for more than 15 users.',
                messages.get(0), messages);
    }

    @IsTest
    static void testDifferentBillingPeriods() {
        final WrikeQuote quote = new WrikeQuote();
        quote.addItem(WrikeQuoteItem.State.ADDED,
                createWrikeQuoteProduct('Business Subscription Licenses', 10, 'Annual'));
        quote.addItem(WrikeQuoteItem.State.ADDED, createWrikeQuoteProduct('Wrike Resource', 10, 'Month'));

        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('Billing frequency (selected in Rate Plan) should be the same ' +
                'for all recurring product in the quote.', messages.get(0), messages);
    }

    @IsTest
    static void testNotMatchLicenseQuantity() {
        final WrikeQuote quote = new WrikeQuote();
        quote.newQuantity = 10;
        quote.addItem(WrikeQuoteItem.State.ADDED,
                createWrikeQuoteProduct('Business Subscription Licenses', 10, 'Annual'));
        quote.addItem(WrikeQuoteItem.State.ADDED, createWrikeQuoteProduct('Wrike Resource', 5, 'Annual'));

        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('Quantity mismatch for add-on seats.', messages.get(0), messages);
    }

    @IsTest
    static void testNotCorrespondQuoteBillingPeriod() {
        final WrikeQuote quote = new WrikeQuote();
        quote.newTerm = 12;
        quote.addItem(WrikeQuoteItem.State.ADDED,
                createWrikeQuoteProduct('Business Subscription Licenses', 10, 'Two Years'));

        final List<String> messages = new QuoteValidatorImpl(quote).getErrorMessages();
        System.assertEquals('Billing frequency of Business Subscription Licenses (selected in Rate Plan) ' +
                'doesn\'t correspond to initial or renewal contract term.', messages.get(0), messages);
    }

    @IsTest
    static void testGetMissingDeploymentNames() {
        final Product2 deployment = new Product2();
        deployment.Name = 'Professional Services - Remote – Package One';
        deployment.ZuoraServiceType__c = 'Implementation';
        deployment.ZuoraProductId__c = '2c92c0f9709a26d801709bc6b45f39ac';
        deployment.ZuoraRateplanId__c = '2c92c0f9709a26dd01709bca57dc50fb';
        deployment.ZuoraProductName__c = 'Professional Services - Remote';
        deployment.ZuoraRatePlanName__c = 'Package One';
        deployment.MaxNumberOfTeams__c = 2;
        deployment.MinSeats__c = 1;
        deployment.MaxSeats__c = 30;
        insert deployment;

        final Product2 wrongDeployment = new Product2();
        wrongDeployment.Name = 'Some Deployment';
        wrongDeployment.ZuoraServiceType__c = 'Implementation';
        wrongDeployment.ZuoraProductId__c = 'ZuoraProductId';
        wrongDeployment.ZuoraRateplanId__c = 'ZuoraRatePlanId';
        wrongDeployment.ZuoraProductName__c = 'Some';
        wrongDeployment.ZuoraRatePlanName__c = 'Deployment';
        wrongDeployment.MaxNumberOfTeams__c = 1;
        wrongDeployment.MinSeats__c = 1;
        wrongDeployment.MaxSeats__c = 30;
        insert wrongDeployment;

        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Business Subscription Licenses', 'Some Deployment' });
        quote.numberOfTeams = 2;

        final String missingDeploymentName = new QuoteValidatorImpl(quote).getMissingDeploymentNames().get(0);
        System.assertEquals('Professional Services - Remote – Package One', missingDeploymentName);
    }

    @IsTest
    static void testAdditionalCollaboratorDiscount() {
        final Product2 additionalCollaborators = new Product2();
        additionalCollaborators.Name = 'Additional Collaborator Licenses';
        additionalCollaborators.ZuoraServiceType__c = 'CollaboratorSeats';
        additionalCollaborators.ZuoraProductId__c = '2c92c0f9697a317901697bde3d82031a';
        insert additionalCollaborators;

        final WrikeQuote quote = createDefaultQuoteWithProducts(new List<String> { 'Business Subscription Licenses' });
        final WrikeQuoteProduct product = createWrikeQuoteProduct('Additional Collaborator Licenses', 10, 'Annual');
        product.discount = 10;
        quote.addItem(WrikeQuoteItem.State.ADDED, product);

        System.assertEquals(10, new QuoteValidatorImpl(quote).getAdditionalCollaboratorDiscount());
    }

    private static List<Product2> findProductsByNames(final List<String> productNames) {
        final List<Product2> products = [
                SELECT Id, Name, ZuoraServiceType__c, ZuoraProductId__c
                FROM Product2
                WHERE Name IN :productNames
        ];
        return products;
    }

    private static WrikeQuote createDefaultQuoteWithProducts(final List<String> productNames) {
        final List<Product2> products = findProductsByNames(productNames);
        final WrikeQuote quote = new WrikeQuote();
        for (Product2 product2 : products) {
            final WrikeQuoteProduct product = new WrikeQuoteProduct();
            product.product2Id = product2.Id;
            product.name = product2.Name;
            product.serviceType = product2.ZuoraServiceType__c;
            product.quantity = 10;
            product.zuoraProductId = product2.ZuoraProductId__c;
            quote.addItem(WrikeQuoteItem.State.ADDED, product);
        }
        return quote;
    }

    private static WrikeQuoteProduct createWrikeQuoteProduct(final String name,
                                                             final Integer quantity,
                                                             final String billingPeriodName) {
        final WrikeQuoteProduct product = new WrikeQuoteProduct();
        product.quantity = quantity;
        product.billingPeriodName = billingPeriodName;
        product.chargeType = ZuoraRestQueryService.RECURRING;
        product.name = name;
        final Product2 product2 = findProductsByNames(new List<String> { name }).get(0);
        product.product2Id = product2.Id;
        product.serviceType = product2.ZuoraServiceType__c;
        product.zuoraProductId = product2.ZuoraProductId__c;
        return product;
    }
}
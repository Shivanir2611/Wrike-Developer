@IsTest
public class CPQAddDeploymentsControllerTest {

    @TestSetup
    static void setup() {
        final Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
        insert pricebook;
        insert new Settings__c(
                StandardPriceBookId__c = pricebook.Id
        );
    }

    @IsTest
    static void testCalculateAndAddDeployments() {
        final Id priceBookId = Settings__c.getOrgDefaults().StandardPriceBookId__c;
        final Product2 professionalServicesPackage = new Product2(
                Name = 'Professional Services Package',
                ProductCode = 'o-serv-bndl-ProfServices'
        );
        insert professionalServicesPackage;
        TestUtils.createPricebookEntry(professionalServicesPackage.Id, priceBookId, 0);
        final Product2 licenseProduct = new Product2(
                Name = 'Test License Product',
                PG1__c = 'License',
                PG2__c = 'Base Plans',
                PG3__c = 'Base',
                SBQQ__SubscriptionType__c = 'Renewable'
        );
        insert licenseProduct;
        final Product2 addonProduct = new Product2(
                Name = 'Test Addon Product',
                PG1__c = 'License',
                PG2__c = 'Add On',
                PG3__c = 'Standard',
                SBQQ__SubscriptionType__c = 'Renewable'
        );
        insert addonProduct;
        final Product2 existingAddonDeploymentProduct = new Product2(
                Name = 'Test Existing Addon Deployment',
                SBQQ__ChargeType__c = 'One-Time',
                SBQQ__BillingFrequency__c = null,
                ParentProduct__c = addonProduct.Id,
                MaxSeats__c = 30,
                MinSeats__c = 10,
                SBQQ__SubscriptionType__c = 'One-time'
        );
        insert existingAddonDeploymentProduct;
        final Product2 licenseDeploymentProduct = new Product2(
                Name = 'Test License Deployment Remote',
                SBQQ__ChargeType__c = 'One-Time',
                SBQQ__BillingFrequency__c = null,
                MaxSeats__c = 9,
                MaxNumberOfTeams__c = 5
        );
        insert licenseDeploymentProduct;
        TestUtils.createPricebookEntry(licenseDeploymentProduct.Id, priceBookId, 11.11);
        final Product2 addonDeploymentProduct = new Product2(
                Name = 'Test Addon Deployment',
                SBQQ__BillingFrequency__c = null,
                SBQQ__ChargeType__c = 'One-Time',
                ParentProduct__c = addonProduct.Id,
                MaxSeats__c = 9,
                MinSeats__c = 1
        );
        insert addonDeploymentProduct;
        TestUtils.createPricebookEntry(addonDeploymentProduct.Id, priceBookId, 12.12);
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                NumberOfTeams__c = '1',
                CurrencyIsoCode = 'USD',
                AllowLegacyBasePlans__c = true
        );
        insert quote;

        insert new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = licenseProduct.Id,
                SBQQ__Quantity__c = 5
        );
        insert new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = addonProduct.Id,
                SBQQ__Quantity__c = 5
        );
        insert new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = existingAddonDeploymentProduct.Id,
                SBQQ__Quantity__c = 1
        );

        PageReference newQuotePage = Page.addDeployments;
        newQuotePage.getParameters().put(RequestParam.QUOTE_ID, quote.Id);
        Test.setCurrentPage(newQuotePage);

        new CPQAddDeploymentsController().calculateAndAddDeployments();

        final List<SBQQ__QuoteLine__c> items = findQuoteItems(quote.Id);
        System.assertEquals(5, items.size());
        Boolean hasLicenseDeployment = false;
        Boolean hasAddonDeployment = false;
        for (SBQQ__QuoteLine__c item : items) {
            if (item.SBQQ__Product__c == licenseDeploymentProduct.Id) {
                hasLicenseDeployment = true;
            }
            if (item.SBQQ__Product__c == addonDeploymentProduct.Id) {
                hasAddonDeployment = true;
            }
        }
        System.assertEquals(true, hasLicenseDeployment);
        System.assertEquals(true, hasAddonDeployment);
    }

    private static List<SBQQ__QuoteLine__c> findQuoteItems(final Id quoteId) {
        return [
                SELECT Id, Name, SBQQ__Product__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
        ];
    }
}
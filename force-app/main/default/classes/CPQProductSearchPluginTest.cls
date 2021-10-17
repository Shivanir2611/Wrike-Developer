@IsTest
public class CPQProductSearchPluginTest {

    @IsTest
    static void testGetAdditionalSearchFiltersStandAlone() {
        final Product2 packageProduct = new Product2(
                Name = 'Test Package Product',
                ProductCode = CPQProductService.WrikeSolution
        );
        insert packageProduct;
        final Product2 optionProduct = new Product2(
                Name = 'Test Option Product',
                ProductCode = 'test-Option-Product-Code'
        );
        insert optionProduct;
        insert new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = packageProduct.Id,
                SBQQ__OptionalSKU__c = optionProduct.Id,
                SBQQ__Number__c = 1
        );
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                AllowLegacyBasePlans__c = false,
                AllowStandAloneProducts__c = true,
                AllowLegacyFTE__c = false,
                AllowLegacyWrikeIntegrate__c = false
        );
        insert quote;
        final String additionalFilters = new CPQProductSearchPlugin().getAdditionalSearchFilters(
                quote,
                new Map<String, Object>{'SBQQ__ChargeType__c' => 'Recurring'}
        );
        System.assertEquals('Product2.Id IN (\'' + optionProduct.Id + '\')', additionalFilters);
    }
}
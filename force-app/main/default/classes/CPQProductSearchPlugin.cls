global class CPQProductSearchPlugin implements SBQQ.ProductSearchPlugin {

    private final CPQProductService productSrv = CPQProductService.getInstance();

    global CPQProductSearchPlugin() {
    }

    public String getAdditionalSearchFilters(SObject defaultQuote, Map<String, Object> fieldValuesMap) {
        final Id quoteId = (Id)defaultQuote.get('Id');
        final SBQQ__Quote__c quote = [
                SELECT Id, AllowLegacyBasePlans__c, AllowStandAloneProducts__c,
                       AllowLegacyFTE__c, AllowLegacyWrikeIntegrate__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
        final Boolean recurring = fieldValuesMap.get('SBQQ__ChargeType__c') == 'Recurring';
        final String packageProductCode =
                getPackageProductCode(quote.AllowLegacyBasePlans__c, recurring);
        if (quote.AllowStandAloneProducts__c) {
            final List<Id> productIds = getStandAloneProductIds(
                    packageProductCode,
                    quote.AllowLegacyFTE__c,
                    quote.AllowLegacyWrikeIntegrate__c
            );
            return productIds.isEmpty()
                   ? null
                   : 'Product2.Id IN (\'' + String.join(productIds, '\', \'') + '\')';
        } else {
            return packageProductCode != null
                   ? 'Product2.ProductCode = \'' + packageProductCode + '\''
                   : null;
        }
    }

    private String getPackageProductCode(final Boolean allowLegacyBasePlans, final Boolean recurring) {
        if (allowLegacyBasePlans && recurring) {
            return CPQProductService.WrikeSolutionLegacy;
        }
        if (allowLegacyBasePlans && !recurring) {
            return CPQProductService.ProfessionalServicesPackageLegacy;
        }
        if (!allowLegacyBasePlans && recurring) {
            return CPQProductService.WrikeSolution;
        }
        if (!allowLegacyBasePlans && !recurring) {
            return CPQProductService.ProfessionalServicesPackage;
        }
        return null;
    }

    private List<Id> getStandAloneProductIds(final String packageProductCode,
                                             final Boolean allowLegacyFTE,
                                             final Boolean allowLegacyWrikeIntegrate) {
        final List<Id> productIds = new List<Id>();
        final List<SBQQ__ProductOption__c> options = [
                SELECT Id, SBQQ__OptionalSKU__r.Id, SBQQ__OptionalSKU__r.ProductCode
                FROM SBQQ__ProductOption__c
                WHERE SBQQ__ConfiguredSKU__r.ProductCode = :packageProductCode
        ];
        for (SBQQ__ProductOption__c option : options) {
            final String optionProductCode = option.SBQQ__OptionalSKU__r.ProductCode;
            if ((!productSrv.isLegacyFTE(optionProductCode) || allowLegacyFTE)
                    && (!productSrv.isLegacyIntegrate(optionProductCode) || allowLegacyWrikeIntegrate)) {
                productIds.add(option.SBQQ__OptionalSKU__r.Id);
            }
        }
        if (productSrv.isProfessionalServicesPackage(packageProductCode)) {
            productIds.add(CPQProductService.getInstance().findProductByProductCode(
                    CPQProductService.WrikeIntegrateStandard).Id);
        }
        return productIds;
    }

    public String getAdditionalSuggestFilters(SObject param0,
                                              Map<String, Object> param1) {
        return null;
    }

    public Object getFilterDefaultValue(SObject quote,
                                        String fieldName) {
        return null;
    }

    public Object getInputDefaultValue(SObject param0,
                                       String param1) {
        return null;
    }

    public Boolean isFilterHidden(SObject quote,
                                  String filter) {
        return filter == 'SBQQ__ChargeType__c';
    }

    public Boolean isInputHidden(SObject quote,
                                 String input) {
        return false;
    }

    public Boolean isSearchCustom(SObject param0,
                                  Map<String, Object> param1) {
        return false;
    }

    public Boolean isSuggestCustom(SObject param0,
                                   Map<String, Object> param1) {
        return false;
    }

    public List<PricebookEntry> search(SObject param0,
                                       Map<String, Object> param1) {
        return null;
    }

    public List<PricebookEntry> suggest(SObject param0, Map<String, Object> param1) {
        return null;
    }
}
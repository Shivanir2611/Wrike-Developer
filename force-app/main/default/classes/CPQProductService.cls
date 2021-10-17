public class CPQProductService {

    public static final String ProfessionalServicesPackage = 'o-serv-bndl-ProfServices2021';
    public static final String ProfessionalServicesPackageLegacy = 'o-serv-bndl-ProfServices';
    public static final String WrikeSolution = 'r-lic-bndl-WrkSolution2021';
    public static final String WrikeSolutionLegacy = 'r-lic-bndl-WrkSolition';
    public static final String WrikeIntegrateStandard = 'o-serv-dep-IntStandard';
    public static final String ProfessionalLicenses = 'r-lic-base-Pro';
    public static final String SmartStart = 'o-serv-dep-SmartStartOnboarding';
    public static final String CustomDeployment = 'o-serv-dep-CustomDepl';
    public static final String WrikeAnalyze = 'r-lic-adn-Analyze';
    public static final String WrikeAnalyzeStandard = 'o-serv-adn-AnalyzeStandard';
    public static final String Jumpstart = 'o-serv-dep-Jumpstart';

    private static final Set<String> legacyIntegrate = new Set<String> {
            'r-lic-adn-Integrate',
            'r-lic-pckg-Performance'
    };

    private static final Set<String> legacyFTE = new Set<String> {
            'r-othr-ps-0125FTE',
            'r-othr-ps-025FTE',
            'r-othr-ps-05FTE',
            'r-othr-ps-1FTE'
    };

    public static final Set<String> legacyBasePlans = new Set<String>{
            'r-lic-base-Biz',
            'r-lic-base-Ent'
    };

    public static final Set<String> basePlans = new Set<String>{
            'r-lic-base-BizPlus',
            'r-lic-base-EntStandard',
            'r-lic-base-EntPinnacle'
    };

    public static CPQProductService getInstance() {
        return (CPQProductService)ServiceLocator.getInstance(CPQProductService.class);
    }

    public List<Product2> findDeploymentBySeatsAndParentProductId(final Integer seats, final Id parentProductId) {
        return [
                SELECT Id, ProductCode
                FROM Product2
                WHERE MinSeats__c <= :seats
                AND MaxSeats__c >= :seats
                AND ParentProduct__c = :parentProductId
        ];
    }

    public Product2 findDeploymentBySeatsAndNumberOfTeams(final Integer seats, final Integer numberOfTeams) {
        final List<Product2> deployments = [
                SELECT Id, ProductCode
                FROM Product2
                WHERE MaxSeats__c >= :seats
                AND MaxNumberOfTeams__c >= :numberOfTeams
                AND Name LIKE '%Remote%'
                ORDER BY MaxSeats__c
                LIMIT 1
        ];
        return deployments.isEmpty() ? null : deployments.get(0);
    }

    public Product2 findDeploymentForProfessionalLicense(final Integer seats, final Boolean legacyBasePlans) {
        String productCode = null;
        if (!legacyBasePlans) {
            if (seats > 0 && seats <= 25) {
                productCode = 'o-serv-dep-QuickStartOnboarding';
            }
            if (seats >= 26 && seats <= 50) {
                productCode = 'o-serv-dep-SmartStartOnboarding';
            }
            if (seats >= 51 && seats <= 200) {
                productCode = 'o-serv-dep-ProA';
            }
        } else {
            if (seats > 0 && seats < 10) {
                productCode = 'o-serv-dep-QuickStartOnboarding';
            }
            if (seats >= 10 && seats <= 39) {
                productCode = 'o-serv-dep-SmartStartOnboarding';
            }
            if (seats >= 40 && seats <= 49) {
                productCode = 'o-serv-dep-RemoteOne';
            }
            if (seats >= 50 && seats <= 124) {
                productCode = 'o-serv-dep-RemoteTwo';
            }
            if (seats >= 125 && seats <= 200) {
                productCode = 'o-serv-dep-RemoteThree';
            }
        }
        return productCode != null ? findProductByProductCode(productCode) : null;
    }

    public List<Product2> findProductsByIds(final Set<Id> productIds) {
        return [
                SELECT Id, Name, PG1__c, PG2__c, PG3__c, SBQQ__SubscriptionType__c, MaxSeats__c, ProductCode,
                       ParentProduct__c
                FROM Product2
                WHERE Id IN :productIds
        ];
    }

    public Product2 findProductById(final Id productId) {
        final List<Product2> products = findProductsByIds(new Set<Id>{productId});
        return products.isEmpty() ? null : products.get(0);
    }

    public Product2 findProductByProductCode(final String productCode) {
        final List<Product2> products = [
                SELECT Id, ProductCode
                FROM Product2
                WHERE ProductCode = :productCode
        ];
        if (products.isEmpty()) {
            throw new ProductServiceException('WrikeProduct with Product Code ' + productCode + ' does not exist.');
        }
        return products.get(0);
    }

    public Boolean isSeat(final Product2 product) {
        return product.PG1__c == 'License' && product.PG2__c == 'Base Plans' && product.PG3__c == 'Base';
    }

    public Boolean isRenewable(final String subscriptionType) {
        return 'Renewable'.equalsIgnoreCase(subscriptionType);
    }

    public Boolean isUncountable(final String productCode) {
        return isPremiumSupportOrSuccess(productCode)
                || 'r-othr-xtr-UnlimCollab'.equals(productCode)
                || 'r-othr-xtr-LegUptime'.equals(productCode);
    }

    public Boolean isPremiumSupportOrSuccess(final String productCode) {
        return 'r-othr-sprt-PremSupport'.equals(productCode)
                || 'r-othr-sprt-PremPlusSuccess'.equals(productCode);
    }

    public Boolean isBusinessA(final String productCode) {
        return 'o-serv-dep-BizA'.equals(productCode);
    }

    public Boolean isBusinessB(final String productCode) {
        return 'o-serv-dep-BizB'.equals(productCode);
    }

    public Boolean isPinnacleB(final String productCode) {
        return 'o-serv-dep-PinB'.equals(productCode);
    }

    public Boolean isPinnacleACore(final String productCode) {
        return 'o-serv-dep-PinAcore'.equals(productCode);
    }

    public Boolean isPinnacleBCore(final String productCode) {
        return 'o-serv-dep-PinBcore'.equals(productCode);
    }

    public Boolean isProfessionalServicesPackage(final String productCode) {
        return ProfessionalServicesPackage.contains(productCode);
    }

    public Boolean isLegacyFTE(final String productCode) {
        return legacyFTE.contains(productCode);
    }

    public Boolean isLegacyIntegrate(final String productCode) {
        return legacyIntegrate.contains(productCode);
    }

    public Boolean isEnterprisePinnacle(final String productCode) {
        return 'r-lic-base-EntPinnacle'.equals(productCode);
    }

    public Boolean isWrikeAnalyzeStandard(final String productCode) {
        return WrikeAnalyzeStandard.equals(productCode);
    }

    public Boolean isProfessionalLicenses(final String productCode) {
        return ProfessionalLicenses.equals(productCode);
    }

    public Boolean isBasePlan(final String productCode) {
        return basePlans.contains(productCode);
    }

    public Boolean isSmartStart(final String productCode) {
        return SmartStart.equals(productCode);
    }

    public Boolean isLegacyBasePlane(final String productCode) {
        return legacyBasePlans.contains(productCode);
    }

    public Boolean isCustomDeployment(final String productCode) {
        return CustomDeployment.equals(productCode);
    }

    public Boolean isWrikeSolutionLegacy(final String productCode) {
        return WrikeSolutionLegacy.equals(productCode);
    }

    public Boolean isJumpstart(final String productCode) {
        return Jumpstart.equals(productCode);
    }

    public Set<String> getProductOptionCodesByPackageProductCode(final String productCode) {
        final List<SBQQ__ProductOption__c> productOptions = [
                SELECT Id, SBQQ__ProductCode__c
                FROM SBQQ__ProductOption__c
                WHERE SBQQ__ConfiguredSKU__r.ProductCode = :productCode
        ];
        final Set<String> productOptionCodes = new Set<String>();
        for (SBQQ__ProductOption__c productOption : productOptions) {
            productOptionCodes.add(productOption.SBQQ__ProductCode__c);
        }
        return productOptionCodes;
    }

    public class ProductServiceException extends Exception {
    }
}
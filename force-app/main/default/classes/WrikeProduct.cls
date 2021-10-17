public class WrikeProduct {

    public static Set<String> seatsServiceTypes = new Set<String> {
            'PremiumSeats',
            'Premium2016Seats',
            'BusinessSeats',
            'BizCreative',
            'EnterpriseSeats',
            'EntCreative'
            };

    public static Set<String> addonServiceTypes = new Set<String> {
            'ProofingAddon',
            'DamAddon',
            'IntegrateAddon',
            'IntegrateLimitedAddon',
            'ResourceAddon',
            'AnalyzeAddon',
            'WrikeLockAddon'
            };

    public static Set<String> packageServiceTypes = new Set<String> {
            'WrikePerformancePackage',
            'WrikeForMarketersPackage',
            'WrikeForProfessionalServicesPackage'
            };

    private static final String ADDITIONAL_COLLABORATORS = 'CollaboratorSeats';
    private static final String UNLIMITED_COLLABORATORS = 'UnlimitedCollaboratorSeats';
    private static final String PREMIUM_SUPPORT = 'PremiumSupport';
    private static final String QUICK_START = 'Quick Start';
    private static final String SELF_START = 'Self Start';
    private static final String SMART_START = 'Smart Start';
    private static final String PS_REMOTE = 'Professional Services - Remote';
    private static final String PS_ONSITE = 'Professional Services - Onsite';

    private static final String WFPS_PACKAGE = 'WrikeForProfessionalServicesPackage';
    private static final String WRIKE_PERFORMANCE_PACKAGE = 'WrikePerformancePackage';
    private static final String WFM_PACKAGE = 'WrikeForMarketersPackage';

    private static final String WRIKE_INTEGRATE = 'IntegrateAddon';
    private static final String WRIKE_OLD_INTEGRATE = 'Wrike Integrate';
    private static final String WRIKE_INTEGRATE_STANDARD = 'IntegrateLimitedAddon';
    private static final String WRIKE_INTEGRATE_ENHANCED = 'AdditionalIntegrateTasks1k';
    private static final String WRIKE_LOCK = 'WrikeLockAddon';
    private static final String WRIKE_ANALYZE = 'AnalyzeAddon';

    private static final String PREMIUM = 'Premium';
    private static final String IMPLEMENTATION = 'Implementation';
    private static final String JUMPSTART = 'Jumpstart';
    private static final String FTE = 'FTE';
    private static final String CUSTOM = 'Custom';

    public Id id {get; set;}
    public String name {get; set;}
    public String zuoraName {get; set;}
    public String zuoraServiceType {get; set;}
    public String zuoraProductId {get; set;}
    public String zuoraRatePlanId {get; set;}
    public String zuoraCategory {get; set;}
    public String enabledLicenses {get; set;}
    public String sku {get; set;}
    public WrikePackage wrikePackage {get; set;}
    public Decimal maxSeats {get; set;}
    public Decimal minSeats {get; set;}
    public Decimal maxNumberOfTeams {get; set;}
    public Id parentProductId {get; set;}
    public String pg1 {get; set;}
    public String pg2 {get; set;}
    public String pg3 {get; set;}
    public String deploymentExhibit {get; set;}
    public String zuoraProductName {get; set;}
    public String zuoraRatePlanName {get; set;}
    public String requiredProductServiceType {get; set;}

    public Boolean isSeat() {
        return zuoraServiceType != null && seatsServiceTypes.contains(zuoraServiceType);
    }

    public Boolean isPremium() {
        return isSeat() && zuoraServiceType.startsWith(PREMIUM);
    }

    public Boolean isPremiumSupport() {
        return PREMIUM_SUPPORT.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isPackage() {
        return wrikePackage != null;
    }

    public Boolean isDeployment() {
        return IMPLEMENTATION.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isCustomDeployment() {
        return isDeployment() && zuoraRatePlanName.contains(CUSTOM);
    }

    public Boolean isJumpstart() {
        return isDeployment() && name.contains(JUMPSTART);
    }

    public Boolean isFTE() {
        return isDeployment() && name.contains(FTE);
    }

    public Boolean isQuickStart() {
        return isDeployment() && zuoraProductName.equalsIgnoreCase(QUICK_START);
    }

    public Boolean isSelfStart() {
        return isDeployment() && zuoraProductName.equalsIgnoreCase(SELF_START);
    }

    public Boolean isSmartStart() {
        return isDeployment() && zuoraProductName.equalsIgnoreCase(SMART_START);
    }

    /* returns:
     *      0  if this deployment fits a given number of seats
     *      1  if this deployment is larger than required
     *     -1  if this deployment is smaller or is not applicable
     */
    public Integer matchProfessionalLicenseDeployment(final Integer seats,
                                                      final Boolean includeOnsite) {
        if(zuoraProductName != null) {
            final Boolean psPackage = zuoraProductName.equalsIgnoreCase(PS_REMOTE)
                    || (includeOnsite && zuoraProductName.equalsIgnoreCase(PS_ONSITE));
            if(isQuickStart() || isSelfStart()) {
                return matchRangeToValue(seats, 1, 9);
            }
            if(isSmartStart()) {
                return matchRangeToValue(seats, 10, 39);
            }
            if(psPackage && 'Package One'.equals(zuoraRatePlanName)) {
                return matchRangeToValue(seats, 40, 49);
            }
            if(psPackage && 'Package Two'.equals(zuoraRatePlanName)) {
                return matchRangeToValue(seats, 50, 124);
            }
            if(psPackage && 'Package Three'.equals(zuoraRatePlanName)) {
                return seats > 124 ? 0 : 1;
            }
            if(psPackage && ('Package Four'.equals(zuoraRatePlanName) || 'Package Five'.equals(zuoraRatePlanName))) {
                return 1;
            }
        }
        return -1;
    }

    private Integer matchRangeToValue(final Integer value,
                                      final Integer min,
                                      final Integer max) {
        return value > max
               ? -1
               : (value < min ? 1 : 0);
    }

    public Boolean isAdditionalCollaboratorLicenses() {
        return ADDITIONAL_COLLABORATORS.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isUnlimitedCollaborators() {
        return UNLIMITED_COLLABORATORS.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isAvailablePlan(final String licenseServiceType) {
        if (enabledLicenses == null) {
            return true;
        }
        final String plan = getLicenseType(licenseServiceType);
        return plan != null && enabledLicenses.contains(plan);
    }

    public String getEnabledLicensesAsString() {
        return String.join(enabledLicenses.split(';'), ' or ');
    }

    public Boolean isProfessional(final String serviceType) {
        return serviceType == 'PremiumSeats' || serviceType == 'Premium2016Seats';
    }

    public Boolean isBusiness(final String serviceType) {
        return serviceType == 'BusinessSeats' || serviceType == 'BizCreative';
    }

    public Boolean isEnterprise(final String serviceType) {
        return serviceType == 'EnterpriseSeats' || serviceType == 'EntCreative';
    }

    public String getLicenseType(final String serviceType) {
        if (isProfessional(serviceType)) {
            return 'Professional';
        } else if (isBusiness(serviceType)) {
            return 'Business';
        } else if (isEnterprise(serviceType)) {
            return 'Enterprise';
        }
        return null;
    }

    public Boolean isWfPSPackage() {
        return WFPS_PACKAGE.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isWrikePerformancePackage() {
        return WRIKE_PERFORMANCE_PACKAGE.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isWrikeIntegrate() {
        return WRIKE_INTEGRATE.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isWrikeIntegrateStandard() {
        return WRIKE_INTEGRATE_STANDARD.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isWrikeIntegrateEnhanced() {
        return WRIKE_INTEGRATE_ENHANCED.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isOldWrikeIntegrate() {
        return WRIKE_OLD_INTEGRATE.equalsIgnoreCase(zuoraProductName);
    }

    public Boolean isWfMPackage() {
        return WFM_PACKAGE.equalsIgnoreCase(zuoraServiceType);
    }

    public Boolean isStandardDeployment() {
        return isDeployment() && pg1 == 'Services' && pg2 == 'Deployment' && pg3 == 'Standard';
    }

    public Boolean includes(final WrikeProduct product) {
        return this.isPackage() && this.wrikePackage.items.contains(product);
    }

    public Boolean isCompatible(final WrikeProduct product) {
        if (this.zuoraServiceType == WRIKE_LOCK
                && (product.zuoraServiceType == WRIKE_ANALYZE
                        || product.zuoraServiceType == WRIKE_PERFORMANCE_PACKAGE)) {
            return false;
        }
        if ((this.isSelfStart() || this.isQuickStart()) && product.isDeployment()) {
            return false;
        }
        if (this.isSmartStart() && product.isDeployment()) {
            return false;
        }
        if (this.isPackage() && product.isPackage()) {
            for (WrikeProduct thisPackageItem : this.wrikePackage.items) {
                if (product.wrikePackage.items.contains(thisPackageItem)) {
                    return false;
                }
            }
        }
        return true;
    }

    public class WrikePackage {
        public List<WrikeProduct> items {get; set;}

        public WrikePackage(List<WrikeProduct> items) {
            this.items = items;
        }
    }
}
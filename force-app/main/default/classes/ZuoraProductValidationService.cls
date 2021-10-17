public virtual class ZuoraProductValidationService {

    public static ZuoraProductValidationService getInstance() {
        return (ZuoraProductValidationService)ServiceLocator.getInstance(ZuoraProductValidationService.class);
    }

    private static Map<String, Integer> recurringPeriodNameToNumber = new Map<String, Integer> {
        'Month' => 1,
        'Quarter' => 3,
        'Semi-Annual' => 6,
        'Annual' => 12,
        'Eighteen Months' => 18,
        'Two Years' => 24,
        'Three Years' => 36,
        'Five Years' => 60
    };

    private static Set<String> seatsServiceTypes = new Set<String> {
        'PremiumSeats',
        'Premium2016Seats',
        'BusinessSeats',
        'BizCreative',
        'EnterpriseSeats',
        'EntCreative'
    };

    private static Set<String> creativeServiceTypes = new Set<String> {
        'BizCreative',
        'EntCreative'
    };

    private static final String PREMIUM = 'Premium';
    private static final String PREMIUM_SUPPORT = 'PremiumSupport';
    private static final String PROOFING_ADDON = 'ProofingAddon';
    private static final String ADVANCED_FEATURE_ADDON = 'AdvancedFeatureAddon';
    private static final String RESOURCE_MANAGEMENT_ADDON = 'ResourceAddon';
    private static final String INTEGRATE_ADDON = 'IntegrateAddon';
    private static final String WRIKE_INTEGRATE = 'Wrike Integrate';
    private static final String WRIKE_INTEGRATE_STANDARD = 'Wrike Integrate Standard';
    private static final String WRIKE_INTEGRATE_ENHANCED_OLD = 'IntegrateExtraOperations';
    private static final String WRIKE_INTEGRATE_ENHANCED_NEW = 'AdditionalIntegrateTasks1k';
    private static final String MARKETING_INSIGHTS_STANDARD = 'MarketingInsightsAddon';
    private static final String MARKETING_INSIGHTS_ENHANCED = 'MarketingInsightsExtendedLimits';
    private static final String DAM_ADDON = 'DamAddon';
    private static final String BRONZE_CERTIFICATION = 'Bronze Certification';
    private static final String SILVER_CERTIFICATION = 'Silver Certification';
    private static final String LOCK_ADDON = 'WrikeLockAddon';
    private static final String PROJECT_SYNCS_ADDON = 'ProjectSyncsAddon';
    private static final String ANALYZE_ADDON = 'AnalyzeAddon';
    private static final String WFM_PACKAGE = 'WrikeForMarketersPackage';
    private static final String WFPS_PACKAGE = 'WrikeForProfessionalServicesPackage';
    private static final String PERFORMANCE_PACKAGE = 'WrikePerformancePackage';
    private static final String PARTNER_COMMISSION = 'PartnerCommission';
    public static final String IMPLEMENTATION = 'Implementation';
    public static final String COLLABORATORS = 'CollaboratorSeats';
    public static final String ADDITIONAL_STORAGE = 'StorageTB';
    public static final String ADDITIONAL_VIDEO_UPLOAD = 'AdditionalVideoTranscoding100GB';
    public static final String UNLIMITED_COLLABORATORS = 'UnlimitedCollaboratorSeats';
    private static final String QUICK_START = 'Quick Start';
    private static final String SELF_START = 'Self Start';
    private static final String SMART_START = 'Smart Start';

    public Integer getRecurringPeriodInMonth(final String recurringPeriodName) {
        return recurringPeriodNameToNumber.get(recurringPeriodName);
    }

    public Boolean isSeat(final String serviceType) {
        return serviceType != null && seatsServiceTypes.contains(serviceType);
    }

    public Boolean isPremium(final String serviceType) {
        return isSeat(serviceType) && serviceType.startsWith(PREMIUM);
    }

    public Boolean isPremiumSupport(final String serviceType) {
        return PREMIUM_SUPPORT.equalsIgnoreCase(serviceType);
    }

    public Boolean isQuickStart(final String name) {
        return QUICK_START.equalsIgnoreCase(name);
    }

    public Boolean isSelfStart(final String name) {
        return SELF_START.equalsIgnoreCase(name);
    }

    public Boolean isSmartStart(final String name) {
        return SMART_START.equalsIgnoreCase(name);
    }

    public Boolean isBronzeCertification(final String name) {
        return BRONZE_CERTIFICATION.equalsIgnoreCase(name);
    }

    public Boolean isSilverCertification(final String name) {
        return SILVER_CERTIFICATION.equalsIgnoreCase(name);
    }

    public Boolean isEnterprise(final String serviceType) {
        return serviceType == 'EnterpriseSeats' || serviceType == 'EntCreative';
    }

    public Boolean isProofingAddon(final String serviceType) {
        return PROOFING_ADDON.equalsIgnoreCase(serviceType);
    }

    public Boolean isProjectSyncsAddon(final String serviceType) {
        return PROJECT_SYNCS_ADDON.equalsIgnoreCase(serviceType);
    }

    public Boolean isAdvancedFeatureAddon(final String serviceType) {
        return ADVANCED_FEATURE_ADDON.equalsIgnoreCase(serviceType);
    }

    public Boolean isIntegrateAddon(final String serviceType) {
        return INTEGRATE_ADDON.equalsIgnoreCase(serviceType);
    }

    public Boolean isWrikeIntegrate(final String name) {
        return WRIKE_INTEGRATE.equalsIgnoreCase(name);
    }

    public Boolean isWrikeIntegrateStandard(final String name) {
        return WRIKE_INTEGRATE_STANDARD.equalsIgnoreCase(name);
    }

    public Boolean isMarketingInsightsStandard(final String serviceType) {
        return MARKETING_INSIGHTS_STANDARD.equalsIgnoreCase(serviceType);
    }

    public Boolean isMarketingInsightsEnhanced(final String serviceType) {
        return MARKETING_INSIGHTS_ENHANCED.equalsIgnoreCase(serviceType);
    }

    public Boolean isWrikeIntegrateEnhanced(final String serviceType) {
        return WRIKE_INTEGRATE_ENHANCED_OLD.equalsIgnoreCase(serviceType) || WRIKE_INTEGRATE_ENHANCED_NEW.equalsIgnoreCase(serviceType);
    }

    public Boolean isResourceManagementAddon(final String serviceType) {
        return RESOURCE_MANAGEMENT_ADDON.equalsIgnoreCase(serviceType);
    }

    public Boolean isDAMAddon(final String serviceType) {
        return DAM_ADDON.equalsIgnoreCase(serviceType);
    }

    public Boolean isWrikeLockAddon(final String serviceType) {
        return LOCK_ADDON.equalsIgnoreCase(serviceType);
    }

    public Boolean isWrikeAnalyzeAddon(final String serviceType) {
        return ANALYZE_ADDON.equalsIgnoreCase(serviceType);
    }

    public Boolean isPerformancePackage(final String serviceType) {
        return PERFORMANCE_PACKAGE.equalsIgnoreCase(serviceType);
    }

    public Boolean isWfmPackage(final String serviceType) {
        return WFM_PACKAGE.equalsIgnoreCase(serviceType);
    }

    public Boolean isWfpsPackage(final String serviceType) {
        return WFPS_PACKAGE.equalsIgnoreCase(serviceType);
    }

    public Boolean isCreative(final String serviceType) {
        return serviceType != null && creativeServiceTypes.contains(serviceType);
    }

    public Boolean isImplementation(final String serviceType) {
        return IMPLEMENTATION.equalsIgnoreCase(serviceType);
    }

    public Boolean isCollaboratorsAddon(final String serviceType) {
        return COLLABORATORS.equalsIgnoreCase(serviceType);
    }

    public Boolean isUnlimitedCollaborators(final String serviceType) {
        return UNLIMITED_COLLABORATORS.equalsIgnoreCase(serviceType);
    }

    public Boolean isPartnerCommission(final String serviceType) {
        return PARTNER_COMMISSION.equals(serviceType);
    }

    public Boolean isAdditionalStorage(final String serviceType) {
        return ADDITIONAL_STORAGE.equalsIgnoreCase(serviceType);
    }

    public Boolean isAdditionalVideoUpload(final String serviceType) {
        return ADDITIONAL_VIDEO_UPLOAD.equalsIgnoreCase(serviceType);
    }
}
public with sharing class SettingsProvider {

    public static final String COMMA = ',';

    private static List<Quote_Item_Type__mdt> quoteItemActions = [
        SELECT DeveloperName, Label, New_Product__c, Renewal__c, Type__c, Update_On_Renewal__c, Description__c, index__c
        FROM Quote_Item_Type__mdt
        WHERE IsActive__c = true
        ORDER BY Index__c
    ];
    private static List<Profile> currentUserProfiles = ProfileQueryService.getInstance().getById(UserInfo.getProfileId());
    private static Set<String> adminProfilesName = new Set<String> {
        'System Administrator', 'Salesforce Admin', 'Salesforce Integration'
    };

    private static Set<String> customPriceRatePlans;
    private static Set<String> licenseSeatsMatchingProducts;
    private static Set<String> wrikeIntegratePSPackages;
    private static Map<String, ProductQuantityOptions> predefinedQuantityOptions;
    private static Map<String, Decimal> maxDiscountMap;

    public static Map<String, String> getAmendmentTypeToDescription() {
        Map<String, String> amendmentTypeToDescription = new Map<String, String>();
        for (Quote_Item_Type__mdt quoteItemAction :  quoteItemActions) {
            if (quoteItemAction.Type__c == 'Amendment') {
                amendmentTypeToDescription.put(quoteItemAction.DeveloperName, quoteItemAction.Description__c);
            }
        }
        return amendmentTypeToDescription;
    }

    public static String getWrikeUrl() {
        return Settings__c.getOrgDefaults().Wrike_URL__c;
    }

    public static String getWrikeSupportappURL() {
        return Settings__c.getOrgDefaults().Wrike_Support_App_URL__c;
    }

    public static String getSlackApiToken() {
        return Settings__c.getOrgDefaults().SlackApiToken__c;
    }

    public static String getJumpStartProductRatePlanZuoraId() {
        return Settings__c.getOrgDefaults().JumpStartProductRatePlanZuoraId__c;
    }

    public static Boolean isAdmin() {
        if (currentUserProfiles.isEmpty()) {
            return false;
        }
        return adminProfilesName.contains(currentUserProfiles[0].Name);
    }
    
    public static Boolean isUnlimitedProfessionalLicense() {
        return SalesSettings__c.getInstance().Unlimited_Professional_License__c == true;
    }
    
    public static Boolean isCustomUserLicenseTiers() {
        return SalesSettings__c.getInstance().Custom_User_License_Tiers__c == true;
    }
    
    public static Boolean isDocusignOptional() {
        return isAdmin() || SalesSettings__c.getInstance().Docusign_Optional__c == true;
    }
    
    public static Boolean isVatOptional() {
        return isAdmin() || SalesSettings__c.getInstance().VAT_Optional__c == true;
    }

    public static String getDocusignSubject() {
        return Settings__c.getInstance().Docusign_Subject__c;
    }

    public static String getDocusignMessage() {
        return Settings__c.getInstance().Docusign_Message__c;
    }

    public static List<String> getPartnerLeadsNotificationEmails() {
        List<String> validEmails = new List<String>();
        String commaSeparatedEmails = Settings__c.getInstance().PartnerLeadsNotificationEmails__c;
        if (String.isBlank(commaSeparatedEmails)) {
            return validEmails;
        }
        List<String> emails = commaSeparatedEmails.split(COMMA);
        for (String currentEmail : emails) {
            if (EmailUtil.isValidEmail(currentEmail)) {
                validEmails.add(currentEmail);
            }
        }
        return validEmails;
    }

    public static List<String> getCPQRenewalNotificationEmails() {
        final String emails = CPQSettings__c.getOrgDefaults().RenewalNotificationEmails__c;
        return String.isBlank(emails) ? new List<String>() : emails.split(',');
    }

    public static List<String> getNetSuiteSyncOrdersNotificationEmails() {
        final String emails = CPQSettings__c.getOrgDefaults().NetSuiteSyncOrdersNotificationEmails__c;
        return String.isBlank(emails) ? new List<String>() : emails.split(',');
    }

    public static String getUrl() {
        final Boolean isSandboox = Settings__c.getOrgDefaults().Sandbox__c;
        if (isSandboox) {
            return 'https://test.salesforce.com/';
        }
        return 'https://login.salesforce.com/';
    }

    public static Boolean isSubscriptionStartDateInThePastAllowed() {
        return SalesSettings__c.getInstance().SubscriptionStartDateInThePast__c == true;
    }

    public static Map<String, Set<String>> getZuoraEnabledRatePlanMap() {
        final String enabledRatePlans = Settings__c.getOrgDefaults().ZuoraEnabledProductRatePlans__c;
        if (String.isBlank(enabledRatePlans)) {
            return new Map<String, Set<String>>();
        }
        return (Map<String, Set<String>>) JSON.deserialize(enabledRatePlans.trim().toLowerCase(), Map<String, Set<String>>.class);
    }

    public static Set<String> getZuoraEnabledDeploymentRatePlans() {
        final String enabledDeploymentRatePlans = Settings__c.getOrgDefaults().ZuoraEnabledDeploymentRatePlans__c;
        if(String.isBlank(enabledDeploymentRatePlans)) {
            return new Set<String>();
        }
        return new Set<String>(enabledDeploymentRatePlans.split(','));
    }

    public static Set<String> getCustomRatePlans() {
        if(customPriceRatePlans == null) {
            final String value = Settings__c.getOrgDefaults().ZuoraCustomPriceRatePlans__c;
            if (String.isBlank(value)) {
                customPriceRatePlans = new Set<String>();
            } else {
                customPriceRatePlans = new Set<String>(value.trim().toUpperCase().split(','));
            }
        }
        return customPriceRatePlans;
    }

    public static Boolean isCustomRatePlan(final String ratePlanName) {
        if(String.isBlank(ratePlanName)) {
            return false;
        }
        return getCustomRatePlans().contains(ratePlanName.toUpperCase());
    }

    public static Boolean isLicenseSeatsMatchingProduct(final String productName) {
        if(licenseSeatsMatchingProducts == null) {
            final String value = Settings__c.getOrgDefaults().LicenseSeatsMatchingProducts__c;
            if(String.isNotBlank(value)) {
                licenseSeatsMatchingProducts = new Set<String>(value.split(','));
            } else {
                licenseSeatsMatchingProducts = new Set<String>();
            }

        }
        return licenseSeatsMatchingProducts.contains(productName);
    }

    public static Boolean isWrikeIntegratePS(final String productName, final String ratePlanName) {
        if(String.isBlank(ratePlanName)
                || !'Professional Services - Integrations'.equalsIgnoreCase(productName)
                && !'Professional Services - Add-ons'.equalsIgnoreCase(productName)) {
            return false;
        }

        System.debug(productName + ' ' + ratePlanName);
        if(wrikeIntegratePSPackages == null) {
            final String value = Settings__c.getOrgDefaults().ProfessionalServicesIntegratePackages__c;
            if(String.isNotBlank(value)) {
                wrikeIntegratePSPackages = new Set<String>(value.split(','));
            } else {
                wrikeIntegratePSPackages = new Set<String>();
            }

        }
        for(String value : wrikeIntegratePSPackages) {
            if(ratePlanName.startsWithIgnoreCase(value)) {
                return true;
            }
        }
        return false;
    }

    public static List<SelectOption> getPredefinedQuantityOptions(final String productName) {
        if(predefinedQuantityOptions == null) {
            final String value = Settings__c.getOrgDefaults().PredefinedQuantityProducts__c;
            if(String.isNotBlank(value)) {
                predefinedQuantityOptions = (Map<String, ProductQuantityOptions>)
                        JSON.deserialize(value, Map<String, ProductQuantityOptions>.class);
            } else {
                predefinedQuantityOptions = new Map<String, ProductQuantityOptions>();
            }
        }
        final List<SelectOption> optionList = new List<SelectOption>();
        final ProductQuantityOptions productQuantityOptions = predefinedQuantityOptions.get(productName);
        if(productQuantityOptions != null) {
            for(Integer quantity : productQuantityOptions.options) {
                optionList.add(new SelectOption(String.valueOf(quantity), quantity + ' ' + productQuantityOptions.unit));
            }
        }
        return optionList;
    }

    public static Decimal findMaxDiscountByProductName(final String productName) {
        if(maxDiscountMap == null) {
            final String value = Settings__c.getOrgDefaults().MaxProductDiscount__c;
            if(String.isNotBlank(value)) {
                maxDiscountMap = (Map<String, Decimal>)JSON.deserialize(value, Map<String, Decimal>.class);
            } else {
                maxDiscountMap = new Map<String, Decimal>();
            }
        }
        return maxDiscountMap.get(productName);
    }

    public static String getTechnologyAdviceEbookLeadOwnerId() {
        return Settings__c.getOrgDefaults().TechnologyAdviceEbookLeadOwnerId__c;
    }

    public static String getWrikeIntegrationUserId() {
        return Settings__c.getOrgDefaults().Wrike_Integration_User_Id__c;
    }

    public static Boolean isRenewalQuotesAvailable() {
        return SalesSettings__c.getInstance().IsRenewalQuotesAvailable__c;
    }

    public static Boolean isBillingProfile() {
        return !currentUserProfiles.isEmpty()
                && currentUserProfiles[0].Name.startsWithIgnoreCase('billing');
    }

    public class ProductQuantityOptions {
        public List<Integer> options {get; set;}
        public String unit {get; set;}
    }
}
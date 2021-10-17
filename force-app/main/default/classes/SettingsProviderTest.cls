@IsTest
public class SettingsProviderTest {
    
    @IsTest
    public static void testIsUnlimitedProfessionalLicense() {
        System.assertEquals(false, SettingsProvider.isUnlimitedProfessionalLicense());
        insert new SalesSettings__c(
            SetupOwnerId = UserInfo.getUserId(), 
            Unlimited_Professional_License__c = true
        );
        System.assertEquals(true, SettingsProvider.isUnlimitedProfessionalLicense());
    }
    
    @IsTest
    public static void testIsCustomUserLicenseTiers() {
        System.assertEquals(false, SettingsProvider.isCustomUserLicenseTiers());
        insert new SalesSettings__c(
            SetupOwnerId = UserInfo.getUserId(), 
            Custom_User_License_Tiers__c = true
        );
        System.assertEquals(true, SettingsProvider.isCustomUserLicenseTiers());
    }
    
    @IsTest
    public static void testDocusignRequired() {
        final User user = TestUtils.createUser('testds1', 'test.docusign@team.wrike.com', 'Standard User');
        System.runAs(user) {
            System.assertEquals(false, SettingsProvider.isDocusignOptional());
        }
    }
    
    @IsTest
    public static void testDocusignOptional() {
        final User user = TestUtils.createUser('testds1', 'test.docusign@team.wrike.com', 'Standard User');
        insert new SalesSettings__c(
            SetupOwnerId = user.Id, 
            Docusign_Optional__c = true
        );
        System.runAs(user) {
            System.assertEquals(true, SettingsProvider.isDocusignOptional());
        }
    }

    @IsTest
    public static void testDocusignSubject() {
        insert new Settings__c(
            Docusign_Subject__c = 'Default subject'
        );
        System.assertEquals('Default subject', SettingsProvider.getDocusignSubject());
        insert new Settings__c(
            SetupOwnerId = UserInfo.getUserId(),
            Docusign_Subject__c = 'Custom subject'
        );
        System.assertEquals('Custom subject', SettingsProvider.getDocusignSubject());
    }

    @IsTest
    public static void testDocusignMessage() {
        insert new Settings__c(
            Docusign_Message__c = 'Default message.'
        );
        System.assertEquals('Default message.', SettingsProvider.getDocusignMessage());
        insert new Settings__c(
            SetupOwnerId = UserInfo.getUserId(),
            Docusign_Message__c = 'Custom message.'
        );
        System.assertEquals('Custom message.', SettingsProvider.getDocusignMessage());
    }
    
    @IsTest
    public static void testVatRequired() {
        final User user = TestUtils.createUser('testvat1', 'test.vat@team.wrike.com', 'Standard User');
        System.runAs(user) {
            System.assertEquals(false, SettingsProvider.isVatOptional());
        }
    }
    
    @IsTest
    public static void testVatOptional() {
        final User user = TestUtils.createUser('testvat1', 'test.vat@team.wrike.com', 'Standard User');
        insert new SalesSettings__c(
            SetupOwnerId = user.Id, 
            VAT_Optional__c = true
        );
        System.runAs(user) {
            System.assertEquals(true, SettingsProvider.isVatOptional());
        }
    }
}
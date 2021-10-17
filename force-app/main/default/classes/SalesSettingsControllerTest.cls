@IsTest
public class SalesSettingsControllerTest {

    @IsTest
    public static void testGetUserCodeMapEmpty() {
        Test.startTest();
        final SalesSettingsController controller = new SalesSettingsController();
        Test.stopTest();
        System.assert(controller.getUserCodeMap().isEmpty(), 'Code map should be empty');
    }
    
    @IsTest
    public static void testGetUserCodeMapSingleEntry() {
        final User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        insert new SalesSettings__c(SetupOwnerId = user.Id, Referral_Code__c = 'QA');
        Test.startTest();
        final SalesSettingsController controller = new SalesSettingsController();
        Test.stopTest();
        final Map<Id, SalesSettings__c> userCodeMap = controller.getUserCodeMap();
        System.assert(userCodeMap.size() == 1, 'Code map should have one entry.');
        System.assert(userCodeMap.get(user.Id).Referral_Code__c == 'QA', 'Code map values are not correct.');
    }
    
    @IsTest
    public static void testGetUserCodeMapEntries() {
        final List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        insert new SalesSettings__c(SetupOwnerId = users[0].Id, Referral_Code__c = 'QA1');
        insert new SalesSettings__c(SetupOwnerId = users[1].Id, Referral_Code__c = 'QA2');
        Test.startTest();
        final SalesSettingsController controller = new SalesSettingsController();
        Test.stopTest();
        final Map<Id, SalesSettings__c> userCodeMap = controller.getUserCodeMap();
        System.assert(userCodeMap.size() == 2, 'Code map should have two entries.');
        System.assert(userCodeMap.get(users[0].Id).Referral_Code__c == 'QA1', 'Code map value is not correct.');
        System.assert(userCodeMap.get(users[1].Id).Referral_Code__c == 'QA2', 'Code map value is not correct.');
    }
    
    @IsTest
    public static void testSave() {
        final List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 3];
        insert new SalesSettings__c(SetupOwnerId = users[0].Id, Referral_Code__c = 'QA1');
        insert new SalesSettings__c(SetupOwnerId = users[1].Id, Referral_Code__c = 'QA2');
        Test.startTest();
        final SalesSettingsController controller = new SalesSettingsController();
        SalesSettingsController.UserBean userBean1 = null;
        SalesSettingsController.UserBean userBean2 = null;
        SalesSettingsController.UserBean userBean3 = null;
        for(SalesSettingsController.UserBean userBean : controller.users) {
            if(userBean.userId == users[0].Id) {
                userBean1 = userBean;
            }
            if(userBean.userId == users[1].Id) {
                userBean2 = userBean;
            }
            if(userBean.userId == users[2].Id) {
                userBean3 = userBean;
            }    
        }
        System.assert(userBean1.settings.Referral_Code__c == 'QA1', 'Referral code is not valid.');
        System.assert(userBean2.settings.Referral_Code__c == 'QA2', 'Referral code is not valid.');
        System.assert(userBean3.settings.Referral_Code__c == null, 'Referral code should be empty.');
        userBean3.settings.Referral_Code__c = 'QA3';
        Test.setCurrentPage(Page.referralSettings);
        controller.save();
        Test.stopTest();
        final Map<Id, SalesSettings__c> userCodeMap = controller.getUserCodeMap();
        System.assert(userCodeMap.size() == 3, 'Code map should have 3 entries.');
        System.assert(userCodeMap.get(users[0].Id).Referral_Code__c == 'QA1', 'Code map value is not correct.');
        System.assert(userCodeMap.get(users[1].Id).Referral_Code__c == 'QA2', 'Code map value is not correct.');
        System.assert(userCodeMap.get(users[2].Id).Referral_Code__c == 'QA3', 'Code map value is not correct.');
    }
    
    @IsTest
    public static void testDeclineDuplicateValue() {
        final List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 3];
        insert new SalesSettings__c(SetupOwnerId = users[0].Id, Referral_Code__c = 'QA1');
        insert new SalesSettings__c(SetupOwnerId = users[1].Id, Referral_Code__c = 'QA2');
        Test.startTest();
        final SalesSettingsController controller = new SalesSettingsController();
        SalesSettingsController.UserBean userBean1 = null;
        SalesSettingsController.UserBean userBean2 = null;
        SalesSettingsController.UserBean userBean3 = null;
        for(SalesSettingsController.UserBean userBean : controller.users) {
            if(userBean.userId == users[0].Id) {
                userBean1 = userBean;
            }
            if(userBean.userId == users[1].Id) {
                userBean2 = userBean;
            }
            if(userBean.userId == users[2].Id) {
                userBean3 = userBean;
            }    
        }
        System.assert(userBean1.settings.Referral_Code__c == 'QA1', 'Referral code is not valid.');
        System.assert(userBean2.settings.Referral_Code__c == 'QA2', 'Referral code is not valid.');
        System.assert(userBean3.settings.Referral_Code__c == null, 'Referral code should be empty.');
        userBean2.settings.Referral_Code__c = 'QA1';
        userBean3.settings.Referral_Code__c = 'QA3';
        Test.setCurrentPage(Page.referralSettings);
        controller.save();
        Test.stopTest();
        final Map<Id, SalesSettings__c> userCodeMap = controller.getUserCodeMap();
        System.assert(userCodeMap.size() == 2, 'Code map should have 2 entries.');
        System.assert(userCodeMap.get(users[0].Id).Referral_Code__c == 'QA1', 'Code map value is not correct.');
        System.assert(userCodeMap.get(users[1].Id).Referral_Code__c == 'QA2', 'Code map value is not correct.');
    }
}
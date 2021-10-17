@IsTest
public class WrikeDataTriggerTest {
    
    @IsTest
    static void testWrikeDataInsert() {
        DateTime contractEndDate = DateTime.newInstance(2020, 4, 15, 12, 30, 0);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            Contract_End_Date__c = contractEndDate
        );
        insert wrikeData;
        
        Test.startTest();
        wrikeData.Contract_End_Date__c = System.now();
        update wrikeData; 
        Test.stopTest();
        
        final WrikeData__c updatedWrikeData = findWrikeData(wrikeData.Id);
        
        System.assertEquals(updatedWrikeData.Last_Contract_End_Date__c,contractEndDate);
    }
    
    @IsTest
    static void testWrikeDataUpdate() {
        DateTime contractEndDate = DateTime.newInstance(2020, 4, 15, 12, 30, 0);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1
        );
        insert wrikeData;
        
        Test.startTest();
        wrikeData.Contract_End_Date__c = contractEndDate;
        update wrikeData; 
        Test.stopTest();
        
        final WrikeData__c updatedWrikeData = findWrikeData(wrikeData.Id);
        
        System.assertEquals(updatedWrikeData.Last_Contract_End_Date__c,null);
    }

    @IsTest
    static void testPremiumSupportDateUpdate() {
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = 1
        );
        insert wrikeData;

        wrikeData.PremiumSupportAddonMrr__c = 100;
        update wrikeData;
        final WrikeData__c updatedWrikeData = findWrikeData(wrikeData.Id);

        System.assertNotEquals(null, updatedWrikeData.PremiumSupportStartDate__c);
        System.assert(updatedWrikeData.PremiumSupportStartDate__c.isSameDay(Date.today()));
    }

    @IsTest
    static void testPremiumSupportDateAlreadySet() {
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = 1,
                PremiumSupportStartDate__c = Date.today().addDays(-7)
        );
        insert wrikeData;

        wrikeData.PremiumSupportAddonMrr__c = 100;
        update wrikeData;
        final WrikeData__c updatedWrikeData = findWrikeData(wrikeData.Id);

        System.assertEquals(Date.today().addDays(-7), updatedWrikeData.PremiumSupportStartDate__c);
    }

    @IsTest
    static void testLastOwnerUpdateDateChange() {
        final WrikeData__c wrikeData = new WrikeData__c(
                Wrike_Account_Id__c = 1,
                CompanyName__c = 'Test Inc.'
        );
        insert wrikeData;
        final WrikeData__c initialWrikeData = findWrikeData(wrikeData.Id);

        wrikeData.CompanyName__c = 'Test Ltd.';
        update wrikeData;
        final WrikeData__c updatedWrikeData = findWrikeData(wrikeData.Id);

        System.assertEquals(null, initialWrikeData.LastOwnerUpdateDate__c);
        System.assertNotEquals(null, updatedWrikeData.LastOwnerUpdateDate__c);
        System.assert(updatedWrikeData.LastOwnerUpdateDate__c.isSameDay(Datetime.now()));
    }

    @IsTest
    static void testLastOwnerUpdateDateSet() {
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1
        );
        insert wrikeData;

        wrikeData.CompanyName__c = 'Test Inc.';
        update wrikeData;
        final WrikeData__c updatedWrikeData = findWrikeData(wrikeData.Id);

        System.assertNotEquals(null, updatedWrikeData.LastOwnerUpdateDate__c);
        System.assert(updatedWrikeData.LastOwnerUpdateDate__c.isSameDay(Datetime.now()));
    }

    private static WrikeData__c findWrikeData(final Id wrikeDataId) {
        return [
                SELECT Id, Last_Contract_End_Date__c, PremiumSupportStartDate__c, LastOwnerUpdateDate__c
                FROM WrikeData__c
                WHERE Id = :wrikeDataId
        ];
    }
}
/*
    @author Andrey Kuleshov
*/
@isTest
private class WrikeUtilTest {

    @TestSetup
    static void setup() {
        TestDataFactory.insertSettings();

        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Opportunity testOpportunity = TestDataFactory.createOpportunity(testAccount.Id, 100);
        TestUtils.insertAndAssert(testOpportunity);
    }

    @IsTest
    static void executeMethods() {
        TestDataFactory.insertSettings();

        Test.setMock(HttpCalloutMock.class, new WrikeHttpMock());

        Test.startTest();

        final String fakeSfId = '001000000000001';

        WrikeUtil.acceptQuote(100, fakeSfId);
        WrikeUtil.deleteQuotes(new List<String>{'100'});
        WrikeUtil.sendQuoteToWrike(null);
        WrikeUtil.getQuoteStatuses(new Set<String>{'100'});
        WrikeUtil.findAccountInfo(100);
        WrikeUtil.checkDemoAccount();
        WrikeUtil.resetDemoAccount();

        String encryptedId = WrikeUtil.encrypt(fakeSfId);
        Id decryptedId = WrikeUtil.getDecryptedId(encryptedId);
        System.assertEquals(fakeSfId, decryptedId);

        Test.stopTest();
    }
}
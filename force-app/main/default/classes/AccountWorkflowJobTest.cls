@IsTest
private class AccountWorkflowJobTest {

    @IsTest
    static void testAccountUpdated() {
        Account testAccount = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(testAccount);

        Test.startTest();

        AccountWorkflowJob job = new AccountWorkflowJob();
        job.execute(null);

        Test.stopTest();

        Account updatedAccount = TestUtils.findAccountById(testAccount.Id);
        System.assert(updatedAccount.Last_Evaluated_Date__c != null, 'Last Evaluated_Date was not set.');
    }
}
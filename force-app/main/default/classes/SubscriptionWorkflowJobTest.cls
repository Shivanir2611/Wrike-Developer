/**
 *  @author Andrey.Kuleshov
 */
@IsTest
public class SubscriptionWorkflowJobTest {

    @IsTest
    static void testSubscriptionUpdated() {
        final Account account = TestDataFactory.createAccount();
        TestUtils.insertAndAssert(account);
        final WrikeData__c wrikeData = new WrikeData__c(
            Wrike_Account_Id__c = 1,
            MRR__c = 150
        );
        TestUtils.insertAndAssert(wrikeData);
        final Subscription__c subscription = TestDataFactory.createWrikeSubscription(
            account.Id,
            wrikeData.Id,
            'Active',
            1,
            99.0
        );
        TestUtils.insertAndAssert(subscription);

        Test.startTest();
        Database.executeBatch(new SubscriptionWorkflowJob());
        Test.stopTest();

        final Subscription__c updatedSubscription = TestUtils.findSubscriptionById(subscription.Id);
        System.assert(updatedSubscription.Last_Evaluated_Date__c != null, 'Last Evaluated Date was not set.');
    }
}
@IsTest
public class UserTriggerTest {

    @IsTest
    static void testPopulateDelegatedUsers() {
        final User user = TestUtils.createUser('a', 'username@test.email.com', 'Standard User');
        final User delegatedUser = TestUtils.createUser('b', 'delegated_username@test.email.com', 'Standard User');

        user.DelegatedApproverId = delegatedUser.Id;
        update user;

        final List<sbaa__Approver__c> approvers = [
                SELECT Id, Name, sbaa__DelegatedApprover__c, sbaa__DelegationStart__c, sbaa__DelegationEnd__c
                FROM sbaa__Approver__c
                WHERE sbaa__User__c = :user.Id
        ];
        System.assert(!approvers.isEmpty());
        final sbaa__Approver__c approver = approvers.get(0);
        final Id delegatedApproverId = [
                SELECT Id
                FROM sbaa__Approver__c
                WHERE sbaa__User__c = :delegatedUser.Id
        ]?.Id;
        System.assertEquals('Test User', approver.Name);
        System.assertEquals(delegatedApproverId, approver.sbaa__DelegatedApprover__c);
        System.assertEquals(DateUtils.getPacificLocalDate(), approver.sbaa__DelegationStart__c);
        System.assertEquals(Date.newInstance(3000, 1, 1), approver.sbaa__DelegationEnd__c);

        user.DelegatedApproverId = null;
        update user;

        final sbaa__Approver__c cleanedApprover = [
                SELECT Id, Name, sbaa__DelegatedApprover__c, sbaa__DelegationStart__c, sbaa__DelegationEnd__c
                FROM sbaa__Approver__c
                WHERE sbaa__User__c = :user.Id
        ].get(0);

        System.assertEquals('Test User', cleanedApprover.Name);
        System.assertEquals(null, cleanedApprover.sbaa__DelegatedApprover__c);
        System.assertEquals(null, cleanedApprover.sbaa__DelegationStart__c);
        System.assertEquals(null, cleanedApprover.sbaa__DelegationEnd__c);
        update user;
    }
}
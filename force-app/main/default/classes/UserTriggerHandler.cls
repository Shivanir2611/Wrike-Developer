public class UserTriggerHandler {

    public static UserTriggerHandler getInstance() {
        return (UserTriggerHandler)ServiceLocator.getInstance(UserTriggerHandler.class);
    }

    public void afterUpdate(final Map<Id, User> oldMap, final Map<Id, User> newMap) {
        final Map<Id, Id> userWithDelegationMap = new Map<Id, Id>();
        for (User user : newMap.values()) {
            if (user.DelegatedApproverId != oldMap.get(user.Id).DelegatedApproverId) {
                userWithDelegationMap.put(user.Id, user.DelegatedApproverId);
            }
        }
        final Map<Id, Id> approverMap = getApproverMap(userWithDelegationMap);

        final List<sbaa__Approver__c> approversToUpsert = new List<sbaa__Approver__c>();
        for (Id userId : userWithDelegationMap.keySet()) {
            final Id sourceApproverId = approverMap.get(userId);
            final Id delegatedUserId = userWithDelegationMap.get(userId);
            final Id delegatedApproverId = delegatedUserId == null
                                           ? null
                                           : approverMap.get(userWithDelegationMap.get(userId));
            approversToUpsert.add(new sbaa__Approver__c(
                    Id = sourceApproverId,
                    Name = newMap.get(userId).FirstName + ' ' + newMap.get(userId).LastName,
                    sbaa__User__c = userId,
                    sbaa__DelegatedApprover__c = delegatedApproverId,
                    sbaa__DelegationStart__c = delegatedApproverId == null ? null : DateUtils.getPacificLocalDate(),
                    sbaa__DelegationEnd__c = delegatedApproverId == null ? null : Date.newInstance(3000, 1, 1)
            ));
        }
        upsert approversToUpsert;
    }

    private Map<Id, Id> getApproverMap(final Map<Id, Id> userWithDelegationMap) {
        final List<sbaa__Approver__c> approvers = [
                SELECT Id, sbaa__User__c
                FROM sbaa__Approver__c
                WHERE sbaa__User__c IN :userWithDelegationMap.keySet()
                OR sbaa__User__c IN :userWithDelegationMap.values()
        ];
        final Map<Id, Id> approverMap = new Map<Id, Id>();
        for (sbaa__Approver__c approver : approvers) {
            approverMap.put(approver.sbaa__User__c, approver.Id);
        }

        final Map<Id, sbaa__Approver__c> delegatedApproversToCreateMap = new Map<Id, sbaa__Approver__c>();
        for (Id userId : userWithDelegationMap.keySet()) {
            final Id delegatedUserId = userWithDelegationMap.get(userId);
            if (delegatedUserId != null && approverMap.get(delegatedUserId) == null) {
                delegatedApproversToCreateMap.put(delegatedUserId, new sbaa__Approver__c(sbaa__User__c = delegatedUserId));
            }
        }
        final List<User> delegatedUsersWithName = [
                SELECT Id, Name
                FROM User
                WHERE Id IN :delegatedApproversToCreateMap.keySet()
        ];
        for (User user : delegatedUsersWithName) {
            delegatedApproversToCreateMap.get(user.Id).Name = user.Name;
        }
        insert delegatedApproversToCreateMap.values();

        for (sbaa__Approver__c approver : delegatedApproversToCreateMap.values()) {
            approverMap.put(approver.sbaa__User__c, approver.Id);
        }
        return approverMap;
    }
}
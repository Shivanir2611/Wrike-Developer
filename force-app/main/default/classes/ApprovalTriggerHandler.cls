public class ApprovalTriggerHandler {

    public static ApprovalTriggerHandler getInstance() {
        return (ApprovalTriggerHandler)ServiceLocator.getInstance(ApprovalTriggerHandler.class);
    }

    public void afterInsert(final List<sbaa__Approval__c> approvals) {
        final Set<Id> requestedApprovalIds = new Set<Id>();
        for (sbaa__Approval__c approval : approvals) {
            if(approval.sbaa__Status__c == 'Requested') {
                requestedApprovalIds.add(approval.Id);
            }
        }
        sendApprovalNotifications(requestedApprovalIds);
    }

    public void afterUpdate(final Map<Id, sbaa__Approval__c> oldMap, final Map<Id, sbaa__Approval__c> newMap) {
        final Set<Id> requestedApprovalIds = new Set<Id>();
        for (sbaa__Approval__c approval : newMap.values()) {
            final sbaa__Approval__c oldApproval = oldMap.get(approval.Id);
            if (approval.sbaa__Status__c == 'Requested'
                    && approval.sbaa__Status__c != oldApproval.sbaa__Status__c) {
                requestedApprovalIds.add(approval.Id);
            }
        }
        sendApprovalNotifications(requestedApprovalIds);
    }

    private void sendApprovalNotifications(final Set<Id> requestedApprovalIds) {
        if(!requestedApprovalIds.isEmpty()) {
            final Id notificationTypeId = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = 'Notify_Quote_Approver'
            ]?.Id;
            if(notificationTypeId != null) {
                final List<sbaa__Approval__c> requestedApprovals = [
                        SELECT Id,
                               Quote__r.Id,
                               Quote__r.Name,
                               Quote__r.SBQQ__Opportunity2__r.Name,
                               sbaa__AssignedTo__c,
                               sbaa__Approver__r.sbaa__User__c,
                               sbaa__Approver__r.sbaa__GroupId__c
                        FROM sbaa__Approval__c
                        WHERE Id IN :requestedApprovalIds
                          AND Quote__c != null
                ];
                final Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();
                final Map<Id, Set<String>> quoteRecipientMap = new Map<Id, Set<String>>();
                for(sbaa__Approval__c approval : requestedApprovals) {
                    final SBQQ__Quote__c quote = approval.Quote__r;
                    quoteMap.put(quote.Id, quote);
                    final Id recipientId = findRecipientId(approval);
                    if(recipientId != null) {
                        if(quoteRecipientMap.containsKey(quote.Id)) {
                            quoteRecipientMap.get(quote.Id).add(recipientId);
                        } else {
                            quoteRecipientMap.put(quote.Id, new Set<String> { recipientId });
                        }
                    }
                }

                for(Id quoteId : quoteRecipientMap.keySet()) {
                    final Set<String> recipientIds = quoteRecipientMap.get(quoteId);
                    if(!recipientIds.isEmpty()) {
                        final SBQQ__Quote__c quote = quoteMap.get(quoteId);
                        final Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle('Approval is Requested for Quote ' + quote.Name);
                        notification.setBody('Opportunity: ' + quote.SBQQ__Opportunity2__r.Name);
                        notification.setNotificationTypeId(notificationTypeId);
                        notification.setTargetId(quoteId);
                        notification.send(recipientIds);
                    }
                }
            }
        }
    }

    private Id findRecipientId(sbaa__Approval__c approval) {
        if(approval.sbaa__AssignedTo__c != null) {
            return approval.sbaa__AssignedTo__c;
        }
        final sbaa__Approver__c approver = approval.sbaa__Approver__r;
        if(approver != null) {
            return approver.sbaa__User__c != null
                   ? approver.sbaa__User__c
                   : approver.sbaa__GroupId__c;
        }
        return null;
    }
}
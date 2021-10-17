public class RequestService {

    public static RequestService getInstance() {
        return (RequestService)ServiceLocator.getInstance(RequestService.class);
    }

    public void createRequests(final List<Lead> leads, final Map<Id, Lead> oldMap) {
        final List<Request__c> requests = new List<Request__c>();
        final String marketoUserId = Settings__c.getOrgDefaults().MarketoUserId__c;
        final Boolean trialProcessingEnabled = Settings__c.getOrgDefaults().TrialProcessingEnabled__c;
        final Boolean paidProcessingEnabled = Settings__c.getOrgDefaults().PaidProcessingEnabled__c;
        for (Lead lead : leads) {
            if (lead.OwnerId != marketoUserId) {
                final Lead oldLead = oldMap == null ? null : oldMap.get(lead.Id);
                if (lead.Last_request_date__c != null
                        && (oldMap == null
                                || lead.Last_request_date__c != oldLead.Last_request_date__c)) {
                    requests.add(new Request__c(
                            Name = getName(lead.Last_request_type__c,
                                    lead.Last_request_subtype__c,
                                            lead.FirstName + ' ' + lead.LastName),
                            Type__c = lead.Last_request_type__c,
                            Subtype__c = lead.Last_request_subtype__c,
                            WrikeAccountId__c = lead.Last_request_wrike_account_ID__c,
                            Comment__c = lead.Last_request_comment__c,
                            Status__c = 'Completed',
                            Lead__c = lead.Id,
                            EventQueueId__c = lead.LastRequestId__c
                    ));
                }
                if (trialProcessingEnabled
                        && !isSelfManagedTrial(lead.Last_Trial_Action_Source__c)
                        && lead.Last_Trial_Start_Date__c != null
                        && (oldMap == null
                                || lead.Last_Trial_Start_Date__c != oldLead.Last_Trial_Start_Date__c)) {
                    final String subtype = oldMap == null || oldLead.Last_Trial_Start_Date__c == null
                                           ? 'New'
                                           : 'Restart';
                    requests.add(new Request__c(
                            Name = getName('Trial', subtype,
                                            lead.FirstName + ' ' + lead.LastName),
                            Type__c = 'Trial',
                            Subtype__c = subtype,
                            WrikeAccountId__c = lead.Last_Trial_Account_Id__c,
                            Status__c = oldMap != null
                                                && isLessThan7DaysAgo(oldLead.Last_Trial_Start_Date__c, lead.Last_Trial_Start_Date__c)
                                                || isOlderThan2Weeks(lead.Last_Trial_Start_Date__c)
                                        ? 'Completed'
                                        : 'Pending',
                            Lead__c = lead.Id,
                            EventQueueId__c = lead.LastRequestId__c
                    ));
                }
                if (isSelfManagedTrial(lead.Last_Trial_Action_Source__c)
                        && String.isNotBlank(lead.Last_Trial_Product__c)
                        && (oldMap == null
                                || lead.Last_Trial_Product__c != oldLead.Last_Trial_Product__c)) {
                    requests.add(new Request__c(
                            Name = getName('SelfManagedTrial', null,
                                            lead.FirstName + ' ' + lead.LastName),
                            Type__c = 'SelfManagedTrial',
                            Comment__c = lead.Last_Trial_Product__c,
                            WrikeAccountId__c = lead.Wrike_Account_Id__c,
                            Status__c = 'Pending',
                            Lead__c = lead.Id
                    ));
                }
                if (lead.MarketingAssignmentId__c != null
                        && (oldMap == null
                                || lead.MarketingAssignmentId__c != oldLead.MarketingAssignmentId__c)) {
                    requests.add(new Request__c(
                            Name = getName('MarketingAssignment', null,
                                            lead.FirstName + ' ' + lead.LastName),
                            Type__c = 'MarketingAssignment',
                            Status__c = 'Pending',
                            Lead__c = lead.Id
                    ));
                }
                if (paidProcessingEnabled
                        && lead.Wrike_Account_Status__c == 'Paid'
                        && (oldMap == null || oldLead.Wrike_Account_Status__c != 'Paid')) {
                    requests.add(new Request__c(
                            Name = getName('Paid', null,
                                            lead.FirstName + ' ' + lead.LastName),
                            Type__c = 'Paid',
                            WrikeAccountId__c = lead.Wrike_Account_Id__c,
                            Status__c = 'Pending',
                            Lead__c = lead.Id
                    ));
                }
                if (lead.Assign_Code__c != null
                        && (oldMap == null
                                || lead.Assign_Code__c != oldLead.Assign_Code__c)) {
                    requests.add(new Request__c(
                            Name = getName('AssignCodeUpdate', null,
                                            lead.FirstName + ' ' + lead.LastName),
                            Type__c = 'AssignCodeUpdate',
                            WrikeAccountId__c = lead.Wrike_Account_Id__c,
                            Status__c = 'Pending',
                            Lead__c = lead.Id
                    ));
                }
                if (lead.mkto71_Lead_Score__c > 99
                        && lead.OwnerId == WrikeConstants.RLQ_ID
                        && lead.TechMotion__c == 'Outbound'
                        && lead.Region__c == 'North America'
                        && (oldLead != null
                                && (oldLead.mkto71_Lead_Score__c == null || oldLead.mkto71_Lead_Score__c < 100 || oldLead.TechMotion__c != 'Outbound'))
                ) {
                    requests.add(new Request__c(
                            Name = getName('HighMarketoScore', null,
                                            lead.FirstName + ' ' + lead.LastName),
                            Type__c = 'HighMarketoScore',
                            WrikeAccountId__c = lead.Wrike_Account_Id__c,
                            Status__c = 'Pending',
                            Lead__c = lead.Id
                    ));
                }
            }
        }
        insert requests;
    }

    public void createRequests(final List<Contact> contacts, final Map<Id, Contact> oldMap) {
        final List<Request__c> requests = new List<Request__c>();
        final Boolean trialProcessingEnabled = Settings__c.getOrgDefaults().TrialProcessingEnabled__c;
        for (Contact contact : contacts) {
            final Contact oldContact = oldMap.get(contact.Id);
            if (contact.Last_request_date__c != null
                    && contact.Last_request_date__c != oldContact.Last_request_date__c) {
                requests.add(new Request__c(
                        Name = getName(contact.Last_request_type__c,
                                contact.Last_request_subtype__c,
                                contact.FirstName + ' ' + contact.LastName),
                        Type__c = contact.Last_request_type__c,
                        Subtype__c = contact.Last_request_subtype__c,
                        WrikeAccountId__c = contact.Last_request_wrike_account_ID__c,
                        Comment__c = contact.Last_request_comment__c,
                        Status__c = 'Completed',
                        Contact__c = contact.Id,
                        EventQueueId__c = contact.LastRequestId__c
                ));
            }
            if (trialProcessingEnabled
                    && !isSelfManagedTrial(contact.Last_Trial_Action_Source__c)
                    && contact.Last_Trial_Start_Date__c != null
                    && contact.Last_Trial_Start_Date__c != oldContact.Last_Trial_Start_Date__c) {
                final String subtype = oldMap == null || oldContact.Last_Trial_Start_Date__c == null
                                       ? 'New'
                                       : 'Restart';
                requests.add(new Request__c(
                        Name = getName('Trial', subtype,
                                        contact.FirstName + ' ' + contact.LastName),
                        Type__c = 'Trial',
                        Subtype__c = subtype,
                        WrikeAccountId__c = contact.Last_Trial_Account_Id__c,
                        Status__c = oldContact.Last_Trial_Start_Date__c != null
                                            && isLessThan7DaysAgo(oldContact.Last_Trial_Start_Date__c, contact.Last_Trial_Start_Date__c)
                                            || isOlderThan2Weeks(contact.Last_Trial_Start_Date__c)
                            ? 'Completed'
                            : 'Pending',
                        Contact__c = contact.Id
                ));
            }
            if (isSelfManagedTrial(contact.Last_Trial_Action_Source__c)
                    && String.isNotBlank(contact.Last_Trial_Product__c)
                    && (oldMap == null
                            || contact.Last_Trial_Product__c != oldContact.Last_Trial_Product__c)) {
                requests.add(new Request__c(
                        Name = getName('SelfManagedTrial', null,
                                        contact.FirstName + ' ' + contact.LastName),
                        Type__c = 'SelfManagedTrial',
                        Comment__c = contact.Last_Trial_Product__c,
                        Status__c = 'Pending',
                        Contact__c = contact.Id
                ));
            }
            if (contact.MarketingAssignmentId__c != null
                    && contact.MarketingAssignmentId__c != oldContact.MarketingAssignmentId__c) {
                requests.add(new Request__c(
                        Name = getName('MarketingAssignment', null,
                                        contact.FirstName + ' ' + contact.LastName),
                        Type__c = 'MarketingAssignment',
                        Status__c = 'Pending',
                        Contact__c = contact.Id
                ));
            }
        }
        insert requests;
    }

    private String getName(final String requestType,
                           final String requestSubtype,
                           final String name) {
        final String requestInfo = requestType
                + ' - '
                + (String.isBlank(requestSubtype)
                   ? ''
                   : requestSubtype + ' - ');
        return requestInfo + name.abbreviate(80 - requestInfo.length());
    }

    private Boolean isLessThan7DaysAgo(final Datetime oldDate, final Datetime requestDate) {
        return requestDate.addDays(-7) < oldDate;
    }

    private Boolean isOlderThan2Weeks(final Datetime requestDate) {
        return DateUtils.getPacificLocalDate().addDays(-14) > requestDate;
    }

     private Boolean isSelfManagedTrial(final String trialSource) {
         return trialSource == 'AccountManagement' || trialSource == 'ChangeExistingTrialAccountManagement';
     }
}
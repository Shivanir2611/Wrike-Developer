public class RenewalOpportunityUpdateJob implements Database.Batchable<SObject>, Schedulable {

    public void execute(final SchedulableContext context) {
        Database.executeBatch(this, 1);
    }

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
                SELECT Id,
                       IsClosed,
                       StageName,
                       Wrike_Account_Id__c,
                       AE_Sourced__c,
                       Manager_Notes__c,
                       NextStep,
                       Next_Step__c,
                       Forecast__c,
                       Wrike_Task_URL__c,
                       Owner.Id,
                       Owner.ProfileId,
                       Owner.Profile.Name,
                       (SELECT Id, ContactId FROM OpportunityContactRoles)
                FROM Opportunity
                WHERE SBQQ__RenewedContract__c != null
                  AND CloseDate >= TODAY
                  AND ZuoraRenewalOpportunity__c = NULL
                  AND Wrike_Account_Id__c > 0
                  AND (NOT Account.Name LIKE 'wpt %')
                ORDER BY SBQQ__RenewedContract__r.StartDate DESC, CreatedDate DESC
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Opportunity> opportunities) {
        System.assertEquals(1, opportunities.size(), 'Please run the job with batch size = 1');
        final Opportunity cpqOpportunity = opportunities[0];
        final Decimal wrikeAccountId = opportunities[0].Wrike_Account_Id__c;
        final Map<Decimal, Opportunity> oldOpportunityMap = mapByWrikeAccountId([
                SELECT Id,
                       IsClosed,
                       StageName,
                       Wrike_Account_Id__c,
                       AE_Sourced__c,
                       Manager_Notes__c,
                       NextStep,
                       Next_Step__c,
                       Forecast__c,
                       Wrike_Task_URL__c,
                       OwnerId,
                       Owner.IsActive,
                       (
                           SELECT Id
                           FROM Related_Partners__r
                       ),
                       (
                           SELECT Id, Title, Body
                           FROM Notes
                           ORDER BY CreatedDate DESC
                           LIMIT 200
                       ),
                       (
                           SELECT Id, ContactId, Role, IsPrimary
                           FROM OpportunityContactRoles
                           ORDER BY CreatedDate DESC
                           LIMIT 200
                       ),
                       (
                           SELECT Id, WhatId, ActivitySubtype
                           FROM OpenActivities
                           ORDER BY CreatedDate DESC
                           LIMIT 200
                       ),
                       (
                           SELECT Id, WhatId, ActivitySubtype
                           FROM ActivityHistories
                           ORDER BY CreatedDate DESC
                           LIMIT 200
                       )
                FROM Opportunity
                WHERE SBQQ__RenewedContract__c = null
                  AND Type = 'Renewal'
                  AND Contract_Start_Date__c > TODAY
                  AND Wrike_Account_Id__c = :wrikeAccountId
                ORDER BY Contract_Start_Date__c DESC, CreatedDate DESC
        ]);
        final Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
        final List<Event> eventsToUpdate = new List<Event>();
        final List<Task> tasksToUpdate = new List<Task>();
        final List<Partner__c> partnersToUpdate = new List<Partner__c>();
        final List<OpportunityContactRole> newContactRoles = new List<OpportunityContactRole>();
        final List<Note> newNotes = new List<Note>();
        final Set<Id> existingContactIds = new Set<Id>();
        for(OpportunityContactRole contactRole : cpqOpportunity.OpportunityContactRoles) {
            existingContactIds.add(contactRole.ContactId);
        }
        final Opportunity oldOpportunity = oldOpportunityMap.get(wrikeAccountId);
        if(oldOpportunity != null) {
            final Opportunity updatedOpportunity = new Opportunity(
                Id = cpqOpportunity.Id,
                ZuoraRenewalOpportunity__c = oldOpportunity.Id
            );
            oppsToUpdate.put(cpqOpportunity.Id, updatedOpportunity);
            if(!oldOpportunity.IsClosed && !cpqOpportunity.IsClosed) {
                copyPopulatedSalesData(oldOpportunity, cpqOpportunity, updatedOpportunity);
                oppsToUpdate.put(oldOpportunity.Id, new Opportunity(
                    Id = oldOpportunity.Id,
                    StageName = 'Reject',
                    Rejected_pass_reason__c = 'Duplicate'
                ));
                for(OpportunityContactRole contactRole : oldOpportunity.OpportunityContactRoles) {
                    if (!existingContactIds.contains(contactRole.ContactId)) {
                        newContactRoles.add(new OpportunityContactRole(
                            ContactId = contactRole.ContactId,
                            OpportunityId = cpqOpportunity.Id,
                            Role = contactRole.Role
                        ));
                    }
                }
                for(Note note : oldOpportunity.Notes) {
                    newNotes.add(new Note(
                        Title = note.Title,
                        Body = note.Body,
                        ParentId = cpqOpportunity.Id
                    ));
                }
                for(OpenActivity activity : oldOpportunity.OpenActivities) {
                    if(activity.WhatId == oldOpportunity.Id) {
                        addUpdatedActivity(activity.id, tasksToUpdate, eventsToUpdate, cpqOpportunity.Id);
                    }
                }
                for(ActivityHistory activity : oldOpportunity.ActivityHistories) {
                    if(activity.WhatId == oldOpportunity.Id) {
                        addUpdatedActivity(activity.id, tasksToUpdate, eventsToUpdate, cpqOpportunity.Id);
                    }
                }
                for(Partner__c partner : oldOpportunity.Related_Partners__r) {
                    partnersToUpdate.add(new Partner__c(
                        Id = partner.Id,
                        Opportunity__c = cpqOpportunity.Id
                    ));
                }
            }
        } else if(ProfileQueryService.getInstance().isAdminOrBillingProfile(cpqOpportunity.Owner.ProfileId)
                  && cpqOpportunity.Owner.Id != WrikeConstants.SF_ADMIN_ID) {
            oppsToUpdate.put(cpqOpportunity.Id, new Opportunity(
                    Id = cpqOpportunity.Id,
                    OwnerId = WrikeConstants.SF_ADMIN_ID
            ));
        }
        update oppsToUpdate.values();
        update tasksToUpdate;
        update eventsToUpdate;
        update partnersToUpdate;
        insert newContactRoles;
        insert newNotes;
    }

    private void addUpdatedActivity(final Id activityId,
                                    final List<Task> tasksToUpdate,
                                    final List<Event> eventsToUpdate,
                                    final Id opportunityId) {
        if(activityId.getSobjectType() == Event.SObjectType) {
            eventsToUpdate.add(new Event(
                Id = activityId,
                WhatId = opportunityId
            ));
        } else {
            tasksToUpdate.add(new Task(
                Id = activityId,
                WhatId = opportunityId
            ));
        }
    }

    private void copyPopulatedSalesData(final Opportunity oldOpportunity,
                                        final Opportunity existingOpportunity,
                                        final Opportunity updatedOpportunity) {
        if(!existingOpportunity.Owner.Profile.Name.containsIgnoreCase('Renewal')) {
            updatedOpportunity.OwnerId = oldOpportunity.Owner.IsActive
                                     ? oldOpportunity.OwnerId
                                     : WrikeConstants.SF_ADMIN_ID;
        }
        if(oldOpportunity.Owner.IsActive) {
            updatedOpportunity.StageName = oldOpportunity.StageName;
        }
        if(existingOpportunity.StageName == 'Need to Contact') {
            updatedOpportunity.StageName = oldOpportunity.StageName;
        }
        if(existingOpportunity.AE_Sourced__c == false && oldOpportunity.AE_Sourced__c == true) {
            updatedOpportunity.AE_Sourced__c = true;
        }
        if(existingOpportunity.Forecast__c == false && oldOpportunity.Forecast__c == true) {
            updatedOpportunity.Forecast__c = true;
        }
        if(String.isBlank(existingOpportunity.NextStep) && String.isNotBlank(oldOpportunity.NextStep)) {
            updatedOpportunity.NextStep = oldOpportunity.NextStep;
        }
        if(String.isBlank(existingOpportunity.Next_Step__c) && String.isNotBlank(oldOpportunity.Next_Step__c)) {
            updatedOpportunity.Next_Step__c = oldOpportunity.Next_Step__c;
        }
        if(String.isBlank(existingOpportunity.Wrike_Task_URL__c) && String.isNotBlank(oldOpportunity.Wrike_Task_URL__c)) {
            updatedOpportunity.Wrike_Task_URL__c = oldOpportunity.Wrike_Task_URL__c;
        }
        if(String.isBlank(existingOpportunity.Manager_Notes__c) && String.isNotBlank(oldOpportunity.Manager_Notes__c)) {
            updatedOpportunity.Manager_Notes__c = oldOpportunity.Manager_Notes__c;
        }
    }

    private Map<Decimal, Opportunity> mapByWrikeAccountId(final List<Opportunity> opportunities) {
        final Map<Decimal, Opportunity> opportunityMap = new Map<Decimal, Opportunity>();
        for(Opportunity opp : opportunities) {
            if(!opportunityMap.containsKey(opp.Wrike_Account_Id__c)) {
                opportunityMap.put(opp.Wrike_Account_Id__c, opp);
            }
        }
        return opportunityMap;
    }

    public void finish(final Database.BatchableContext context) {
    }
}
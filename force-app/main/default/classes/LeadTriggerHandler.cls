public class LeadTriggerHandler {

    public static LeadTriggerHandler getInstance() {
        return (LeadTriggerHandler)ServiceLocator.getInstance(LeadTriggerHandler.class);
    }

    @TestVisible
    private static Boolean requestsCreated = false;

    public void beforeInsert(final List<Lead> leads) {
        final List<Activity_Data__c> activityData = new List<Activity_Data__c>();
        for (Lead lead : leads) {
            activityData.add(new Activity_Data__c());
        }
        insert activityData;
        final Map<String, EmailData__c> emailDataMap = new Map<String, EmailData__c>();
        final Map<String, Scoring_Data__c> scoringDataMap = new Map<String, Scoring_Data__c>();
        final Set<String> emailDomains = new Set<String>();
        final Map<String, Lead> leadsToUpdateContact = new Map<String, Lead>();
        for (Integer i = 0; i < leads.size(); i++) {
            final Lead lead = leads.get(i);
            if (String.isBlank(lead.Email)) {
                lead.Email_Domain__c = null;
                lead.EmailData__c = null;
                lead.Scoring_Data__c = null;
            } else {
                lead.Email_Domain__c = EmailUtil.getEmailDomain(lead.Email);
                emailDataMap.put(lead.Email, new EmailData__c(Email__c = lead.Email));
                scoringDataMap.put(lead.Email, new Scoring_Data__c(Email__c = lead.Email));
            }
            if (String.isNotBlank(lead.Email_Domain__c)) {
                emailDomains.add(lead.Email_Domain__c);
            } else if (String.isNotBlank(lead.Business_Domain__c)) {
                emailDomains.add(lead.Business_Domain__c);
            }
            if (lead.Contact__c == null && lead.Email != null) {
                leadsToUpdateContact.put(lead.Email, lead);
            }
            lead.Activity_Data__c = activityData.get(i).Id;
            lead.Original_Lead_Source__c = lead.LeadSource;
            lead.Region__c = RegionUtil.getRegionByCountryCode(lead.CountryCode);
            if(lead.Country != null && lead.CountryCode == null) {
                lead.CountryCode = CountryUtil.findCountryCodeByValue(lead.Country);
            }
        }
        if (!emailDataMap.isEmpty()) {
            updateEmailData(emailDataMap, leads);
        }
        if (!emailDomains.isEmpty()) {
            updateAccountByEmailDomain(emailDomains, leads);
        }
        if(!scoringDataMap.isEmpty()) {
            updateScoringData(scoringDataMap, leads);
        }
        if (!leadsToUpdateContact.isEmpty()) {
            updateLeadsContact(leadsToUpdateContact);
        }
        LeadService.getInstance().setCountryData(leads);
    }

    public void beforeUpdate(final Map<Id, Lead> oldMap, final Map<Id, Lead> newMap) {
        final List<Lead> leads = newMap.values();
        final Map<Id, Activity_Data__c> activityDataMap = new Map<Id, Activity_Data__c>();
        final Map<Id, WrikeData__c> wrikeDataMap = new Map<Id, WrikeData__c>();
        final Map<String, EmailData__c> emailDataMap = new Map<String, EmailData__c>();
        final Map<String, Scoring_Data__c> scoringDataMap = new Map<String, Scoring_Data__c>();
        final Set<String> emailDomains = new Set<String>();
        final Map<String, Lead> leadsToUpdateContact = new Map<String, Lead>();
        for(Lead lead : leads) {
            final Lead oldLead = oldMap.get(lead.Id);
            if (lead.Activity_Data__c == null
                    && lead.IsConverted == false
                    && lead.OwnerId != WrikeConstants.RLQ_ID
                    && oldLead.OwnerId == WrikeConstants.RLQ_ID) {
                activityDataMap.put(lead.Id, new Activity_Data__c());
            }
            if (lead.Wrike_Account_Id__c != oldLead.Wrike_Account_Id__c) {
                if (lead.Wrike_Account_Id__c == null) {
                    lead.Wrike_Data__c = null;
                } else {
                    wrikeDataMap.put(lead.Id,
                            new WrikeData__c(Wrike_Account_Id__c = lead.Wrike_Account_Id__c));
                }
            }
            if (lead.Email != oldLead.Email
                    || ((lead.EmailData__c == null || lead.Scoring_Data__c == null)
                            && lead.OwnerId != WrikeConstants.RLQ_ID
                            && oldLead.OwnerId == WrikeConstants.RLQ_ID)) {
                if (String.isBlank(lead.Email)) {
                    lead.Email_Domain__c = null;
                    lead.EmailData__c = null;
                    lead.Scoring_Data__c = null;
                } else {
                    lead.Email_Domain__c = EmailUtil.getEmailDomain(lead.Email);
                    emailDataMap.put(lead.Email, new EmailData__c(Email__c = lead.Email));
                    scoringDataMap.put(lead.Email, new Scoring_Data__c(Email__c = lead.Email));
                }
            }
            if (oldLead.Country != lead.Country && oldLead.CountryCode == lead.CountryCode) {
                lead.CountryCode = CountryUtil.findCountryCodeByValue(lead.Country);
            }
            if (oldLead.CountryCode != lead.CountryCode) {
                lead.Region__c = RegionUtil.getRegionByCountryCode(lead.CountryCode);
            }
            if (lead.Email != oldLead.Email && lead.Contact__c == null) {
                leadsToUpdateContact.put(lead.Email, lead);
            }
        }
        if (!activityDataMap.isEmpty()) {
            insert activityDataMap.values();
            for (Id leadId : activityDataMap.keySet()) {
                newMap.get(leadId).Activity_Data__c = activityDataMap.get(leadId).Id;
            }
        }
        if (!wrikeDataMap.isEmpty()) {
            Database.upsert(wrikeDataMap.values(), Schema.WrikeData__c.Wrike_Account_Id__c, false);
            for (Id leadId : wrikeDataMap.keySet()) {
                newMap.get(leadId).Wrike_Data__c = wrikeDataMap.get(leadId).Id;
            }
        }
        if (!emailDataMap.isEmpty()) {
            updateEmailData(emailDataMap, leads);
        }
        if (!emailDomains.isEmpty()) {
            updateAccountByEmailDomain(emailDomains, leads);
        }
        if(!scoringDataMap.isEmpty()) {
            updateScoringData(scoringDataMap, leads);
        }
        if (!leadsToUpdateContact.isEmpty()) {
            updateLeadsContact(leadsToUpdateContact);
        }
        LeadService.getInstance().setCountryData(getLeadsToPopulateCountryData(newMap, oldMap));
    }

    public void afterInsert(final List<Lead> leads) {
        if (!requestsCreated && Settings__c.getOrgDefaults().RequestsDisabled__c != true) {
            RequestService.getInstance().createRequests(leads, null);
            requestsCreated = true;
        }
    }

    public void afterUpdate(final Map<Id, Lead> oldMap, final Map<Id, Lead> newMap) {
        final List<Lead> leads = newMap.values();
        final List<Id> reassignedLeadIds = new List<Id>();
        final List<Id> recycledLeadIds = new List<Id>();
        final Map<Id, Id> contactOpportunityMap = new Map<Id, Id>();
        final Map<Id, Id> convertedContactIds = new Map<Id, Id>();
        for (Lead lead : leads) {
            final Lead oldLead = oldMap.get(lead.Id);
            if(lead.ConvertedOpportunityId != null
                    && lead.ConvertedContactId != null
                    && oldLead.ConvertedContactId == null) {
                contactOpportunityMap.put(lead.ConvertedContactId, lead.ConvertedOpportunityId);
            }
            if(lead.isConverted == false && oldLead.OwnerId != lead.OwnerId) {
                if(ApexUtils.isUser(lead.OwnerId)) {
                    reassignedLeadIds.add(lead.Id);
                } else if(lead.OwnerId == WrikeConstants.RLQ_ID) {
                    recycledLeadIds.add(lead.Id);
                }
            }
            if (lead.IsConverted
                    && oldLead.ConvertedContactId == null
                    && lead.ConvertedContactId != null
                    && lead.Sync_to_Marketo__c) {
                convertedContactIds.put(lead.Id, lead.ConvertedContactId);
            }
        }
        if (!requestsCreated && Settings__c.getOrgDefaults().RequestsDisabled__c != true) {
            RequestService.getInstance().createRequests(leads, oldMap);
            requestsCreated = true;
        }
        if (!contactOpportunityMap.isEmpty()) {
            createBuyerMapRecords(contactOpportunityMap);
        }
        CampaignService.getInstance().leadCampaignConditionCheck(leads, oldMap);

        if (!reassignedLeadIds.isEmpty()) {
            updateReassignedLeadTasks(reassignedLeadIds, newMap);
        }
        if (!recycledLeadIds.isEmpty()) {
            updateRecycledLeadEvents(recycledLeadIds);
        }
        if (!convertedContactIds.isEmpty()) {
            updateConvertedContacts(convertedContactIds, newMap);
        }
    }

    private void updateReassignedLeadTasks(final List<Id> reassignedLeadIds, final Map<Id, Lead> leads) {
        List<Task> tasksToUpdate = new List<Task>();
        List<Task> tasks = [
                SELECT Id, OwnerId, WhoId
                FROM Task
                WHERE Status = 'Open'
                AND WhoId IN :reassignedLeadIds
                AND CreatedDate >= LAST_N_DAYS:30
        ];
        for(Task task : tasks) {
            final Id newOwnerId = leads.get(task.WhoId).OwnerId;
            if(task.OwnerId != newOwnerId) {
                tasksToUpdate.add(new Task(Id = task.Id, OwnerId = newOwnerId));
            }
        }
        if(!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }

    private void updateRecycledLeadEvents(final List<Id> leadIds) {
        final List<Event__c> events = EventQueryService.getInstance().listEventsForLeadList(leadIds);
        for (Event__c event : events) {
            event.Status__c = 'Cancelled';
            event.Recycle_Date__c = Datetime.now();
        }
        update events;
    }

    private void createBuyerMapRecords(final Map<Id, Id> contactOpportunityMap) {
        final List<Key_Players_Influencers__c> buyerMapRecords = new List<Key_Players_Influencers__c>();
        final Set<String> existingBuyerMapRecords = new Set<String>();
        for(Key_Players_Influencers__c newBuyerMap : [
                SELECT Name__c, Opportunity__c
                FROM Key_Players_Influencers__c
                WHERE Name__c IN: contactOpportunityMap.keySet()
                AND Opportunity__c IN: contactOpportunityMap.values()
        ]){
            existingBuyerMapRecords.add(newBuyerMap.Name__c + '_' + newBuyerMap.Opportunity__c);
        }
        for(Id contactId : contactOpportunityMap.keySet()) {
            if(!existingBuyerMapRecords.contains(contactId + '_' + contactOpportunityMap.get(contactId))){
                buyerMapRecords.add(new Key_Players_Influencers__c(
                        Name__c = contactId,
                        Opportunity__c = contactOpportunityMap.get(contactId),
                        Primary__c = true
                ));
            }
        }
        if(!buyerMapRecords.isEmpty()){
            insert buyerMapRecords;
        }
    }

    private void updateAccountByEmailDomain(final Set<String> emailDomains, final List<Lead> leads) {
        final List<Account> accounts = [
                SELECT Id, Email_Domain__c
                FROM Account
                WHERE RecordType.DeveloperName = :RecordTypeQueryService.ACCOUNT_CUSTOMER
                AND Email_Domain__c IN :emailDomains
                ORDER BY Subscription_MRR_Sum__c ASC
        ];
        if(!accounts.isEmpty()) {
            final Map<String, Id> accountMap = new Map<String, Id>();
            for(Account account : accounts) {
                accountMap.put(account.Email_Domain__c , account.Id);
            }
            for(Lead lead : leads) {
                final String emailDomain = String.isNotBlank(lead.Email_Domain__c) ? lead.Email_Domain__c : lead.Business_Domain__c;
                if(String.isNotBlank(emailDomain)) {
                    final Id accountId = accountMap.get(emailDomain);
                    if(accountId != null) {
                        lead.Account__c = accountId;
                    }
                }
            }
        }
    }

    private void updateEmailData(final Map<String, EmailData__c> emailDataMap, final List<Lead> leads) {
        Database.upsert(emailDataMap.values(), Schema.EmailData__c.Email__c, false);
        final Map<Id, EmailData__c> emailDataByIdMap = new Map<Id, EmailData__c> (
                EmailDataQueryService.getInstance().listByEmails(emailDataMap.keySet()));
        for(Lead lead : leads) {
            final Id emailDataId = emailDataMap.containsKey(lead.Email) ? emailDataMap.get(lead.Email).Id : null;
            if(emailDataId != null) {
                final EmailData__c emailData = emailDataByIdMap.get(emailDataId);
                if(emailData != null) {
                    lead.EmailData__c = emailData.Id;
                    lead.Referral_Code__c = emailData.ReferralCode__c;
                }
            }
        }
    }

    private void updateScoringData(final Map<String, Scoring_Data__c> scoringDataMap, final List<Lead> leads) {
        Database.upsert(scoringDataMap.values(), Schema.Scoring_Data__c.Email__c, false);
        for(Lead lead : leads) {
            final Scoring_Data__c scoringData = scoringDataMap.get(lead.Email);
            if(scoringData != null) {
                lead.Scoring_Data__c = scoringData.Id;
            }
        }
    }

    private List<Lead> getLeadsToPopulateCountryData(final Map<Id, Lead> newMap, final Map<Id, Lead> oldMap) {
        List<Lead> leadsToPopulateCountryData = new List<Lead>();
        for (Id leadId : Trigger.newMap.keySet()) {
            final Lead oldLead = oldMap.get(leadId);
            final Lead newLead = newMap.get(leadId);
            final Boolean isCountryCodeChanged = oldLead.CountryCode != newLead.CountryCode;
            final Boolean isCameFromRecycle = newLead.CountryData__c == null
                    && newLead.IsConverted == false
                    && newLead.OwnerId != WrikeConstants.RLQ_ID
                    && oldLead.OwnerId == WrikeConstants.RLQ_ID;
            if (isCountryCodeChanged || isCameFromRecycle) {
                leadsToPopulateCountryData.add(newLead);
            }
        }
        return leadsToPopulateCountryData;
    }

    private void updateLeadsContact(final Map<String, Lead> emailLeadMap) {
        final Map<String, Id> emailContactMap =
                ContactQueryService.getInstance().findEmailContactIdMap(new List<String>(emailLeadMap.keySet()));
        for (String email : emailLeadMap.keySet()) {
            emailLeadMap.get(email).Contact__c = emailContactMap.get(email);
        }
    }

    private void updateConvertedContacts(final Map<Id, Id> convertedContactIds, final Map<Id, Lead> leadMap) {
        final List<Contact> contacts = new List<Contact>();
        for (Id convertedLeadId : convertedContactIds.keySet()) {
            final Lead lead = leadMap.get(convertedLeadId);
            final Id contactId = convertedContactIds.get(convertedLeadId);
            contacts.add(new Contact(
                    Id = contactId,
                    Sync_to_Marketo__c = true,
                    Last_request_date__c = lead.Last_request_date__c,
                    Last_request_type__c = lead.Last_request_type__c,
                    Last_request_subtype__c = lead.Last_request_subtype__c,
                    Last_request_comment__c = lead.Last_request_comment__c,
                    Last_request_wrike_account_ID__c = lead.Last_request_wrike_account_ID__c,
                    LastRequestId__c = lead.LastRequestId__c,
                    MarketingAssignmentId__c = lead.MarketingAssignmentId__c,
                    Last_Trial_Start_Date__c = lead.Last_Trial_Start_Date__c
            ));
        }
        update contacts;
    }
}
public class AccountUpdateJob implements Database.Batchable<SObject>, Schedulable {

    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this);
    }

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Wrike_Account_Id__c, Wrike_Subscription_Terms__c,
                   Subscription_License_Users_Sum__c, Subscription_Users_Sum__c, Subscription_Collaborators_Sum__c,
                   Subscription_MRR_Sum__c, Subscription_Upgrade_Score__c, Subscription_Edit_Wau__c,
                   Subscription_Approval_Reviews_Created__c, Subscription_Proofing_Comments_Added__c,
                   Subscription_Reports_Available__c, Subscription_Request_Forms_Available__c,
                   Subscription_Request_Forms_Used_28_Days__c, Subscription_Forms_Requests_28_Days__c,
                   Subscription_CF__c, Subscription_CF_Usage_28_Days__c, Subscription_Unique_CF_Used_28_Days__c,
                   Subscription_PA_Available__c, Subscription_PA_Usage_28_Days__c, Subscription_Unique_PA_Used_28_Days__c,
                   Subscription_Reports_Usage_28_Days__c, Subscription_Unique_Reports_Used_28_Days__c,
                   Subscription_CLD_Available__c, Subscription_CLD_Usage_28_Days__c, Subscription_Unique_CLD_Used_28_Days__c,
                   Subscription_DB_Available__c, Subscription_DB_Usage_28_Days__c, Subscription_Unique_DB_Usage_28_Days__c,
                   Product_Type__c, Aggregate_Account_Health_Score__c,
                   Next_Annual_Renewal_Date__c, Account_Renewal_Manager__c,
            	   IsActiveAccountProspects__c, OwnerId, Last_Inbound_Activity_new__c, Customer_MRR_Sum__c,n2de__Distribution_engine_details__c,
            	   Level_3_Area__c, Level_5_Territory__c, Level_6_Sub_Territory__c, Number_of_Employees_from_Account__c,
            	   n2de__Distribution_engine_details__r.n2de__Territory__c,
               (
                    SELECT Id, Owner.Email
                    FROM Opportunities
                    WHERE Type = 'Renewal'
                        AND Assigned__c = true
                    ORDER BY CreatedDate DESC
                    LIMIT 1
               )
            FROM Account
            WHERE RecordType.DeveloperName = :RecordTypeQueryService.ACCOUNT_CUSTOMER
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Account> accounts) {
        Map<Id,AggregateResult> contactMaxLastInboundActivityMap = new Map<Id,AggregateResult>([
            SELECT AccountId Id, MAX(Last_Inbound_Activity__c) maxLastInboundActivity
            FROM Contact
            WHERE Last_Inbound_Activity__c != null
            AND AccountId IN :new Map<Id, Account> (accounts).keySet()
            GROUP BY AccountId
        ]);
        
        final List<Subscription__c> subscriptions = [
            SELECT Account__c, Wrike_Account_Id__c, Wrike_Data__r.MRR__c,
                   Wrike_Data__r.Activity_Score__c, Wrike_Data__r.UpgradeScore__c,
                   Wrike_Data__r.Annual__c, Wrike_Data__r.Contract_End_Date__c,
                   Wrike_Data__r.Enterprise__c, Wrike_Data__r.Enterprise_Creative__c,
                   Wrike_Data__r.Professional__c, Wrike_Data__r.Business__c, Wrike_Data__r.Business_Creative__c,
                   Wrike_Data__r.License_Users__c, Wrike_Data__r.Users__c, Wrike_Data__r.Collaborators__c,
                   Wrike_Data__r.EditWau__c, Wrike_Data__r.ApprovalReviewsCreated__c, Wrike_Data__r.ProofingCommentsAdded__c,
                   Wrike_Data__r.ReportsAvailable__c, Wrike_Data__r.RequestFormsAvailable__c,
                   Wrike_Data__r.RequestsFromRequestFormsPast28Days__c, Wrike_Data__r.UniqueRequestFormsUsedPast28Days__c,
                   Wrike_Data__r.Custom_Fields__c, Wrike_Data__r.CustomFieldsUsagePast28Days__c, Wrike_Data__r.UniqueCustomFieldsUsedPast28Days__c,
                   Wrike_Data__r.PAAvailable__c, Wrike_Data__r.PAUsagePast28Days__c, Wrike_Data__r.UniquePAUsedPast28Days__c,
                   Wrike_Data__r.ReportsUsagePast28Days__c, Wrike_Data__r.UniqueReportsUsedPast28Days__c,
                   Wrike_Data__r.CalendarsAvailable__c, Wrike_Data__r.CalendarsUsagePast28Days__c,
                   Wrike_Data__r.UniqueCalendarsUsedPast28Days__c, Wrike_Data__r.DashboardsAvailable__c,
                   Wrike_Data__r.DashboardsUsagePast28Days__c, Wrike_Data__r.UniqueDashboardsUsedPast28Days__c, Wrike_Data__r.Customer_MRR__c
            FROM Subscription__c
            WHERE Account__c IN :new Map<Id, Account> (accounts).keySet()
              AND Status__c = 'Active'
              AND Wrike_Data__r.MRR__c > 0
            ORDER BY Account__c, Wrike_Data__r.MRR__c DESC, CreatedDate 
        ];

        final Map<Id, List<Subscription__c>> accountSubscriptionMap = new Map<Id, List<Subscription__c>>();
        for(Subscription__c subscription : subscriptions) {
            if(!accountSubscriptionMap.containsKey(subscription.Account__c)) {
                accountSubscriptionMap.put(subscription.Account__c, new List<Subscription__c>());
            }
            accountSubscriptionMap.get(subscription.Account__c).add(subscription);
        }
        final List<Id> matchAccountList = new List<Id>();
        final Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for(Account account : accounts) {
            Boolean annual = false;
            Decimal licenseUsersSum = 0;
            Decimal usersSum = 0;
            Decimal collaboratorsSum = 0;
            Decimal editWauSum = 0;
            Decimal mrrSum = 0;
            Decimal customerMRRSum = 0;
            Decimal activityScoreSum = 0;
            Decimal approvalReviewsSum = 0;
            Decimal proofingCommentsSum = 0;
            Decimal reportsAvailableSum = 0;
            Decimal requestFormsSum = 0;
            Decimal formRequests28DaysSum = 0;
            Decimal requestFormsUsed28DaysSum = 0;
            Decimal customFieldsSum = 0;
            Decimal customFields28DaysSum = 0;
            Decimal uniqueCustomFields28DaysSum = 0;
            Decimal proofingAndApprovalsSum = 0;
            Decimal proofingAndApprovals28DaysSum = 0;
            Decimal uniqueProofingAndApprovals28DaysSum = 0;
            Decimal reports28DaysSum = 0;
            Decimal uniqueReports28DaysSum = 0;
            Decimal calendarsAvailableSum = 0;
            Decimal calendarsUsage28DaysSum = 0;
            Decimal uniqueCalendarsUsed28DaysSum = 0;
            Decimal dashboardsAvailableSum = 0;
            Decimal dashboardsUsage28DaysSum = 0;
            Decimal uniqueDashboardsUsed28DaysSum = 0;
            Decimal maxUpgradeScore = null;
            Date nextAnnualRenewalDate = null;
            String accountProductType = null;
            String renewalManagerEmail = null;
            final List<Subscription__c> accountSubscriptions = accountSubscriptionMap.get(account.Id);
            if(accountSubscriptions != null) {
                for(Subscription__c subscription : accountSubscriptions) {
                    final WrikeData__c wrikeData = subscription.Wrike_Data__r;
                    annual = annual || (wrikeData.Annual__c == true);
                    if(wrikeData.License_Users__c != null) {
                        licenseUsersSum = licenseUsersSum + wrikeData.License_Users__c;
                    }
                    if(wrikeData.Users__c != null) {
                        usersSum = usersSum + wrikeData.Users__c;
                    }
                    if(wrikeData.Collaborators__c != null) {
                        collaboratorsSum = collaboratorsSum + wrikeData.Collaborators__c;
                    }
                    if(wrikeData.EditWau__c != null) {
                        editWauSum = editWauSum + wrikeData.EditWau__c;
                    }
                    if(wrikeData.MRR__c != null) {
                        mrrSum = mrrSum + wrikeData.MRR__c;
                    }
                    if(wrikeData.Customer_MRR__c != null) {
                        customerMRRSum = customerMRRSum + wrikeData.Customer_MRR__c;
                    }
                    if(wrikeData.Activity_Score__c != null) {
                        activityScoreSum = activityScoreSum + wrikeData.Activity_Score__c;
                    }
                    if(wrikeData.ApprovalReviewsCreated__c != null) {
                        approvalReviewsSum = approvalReviewsSum + wrikeData.ApprovalReviewsCreated__c;
                    }
                    if(wrikeData.ProofingCommentsAdded__c != null) {
                        proofingCommentsSum = proofingCommentsSum + wrikeData.ProofingCommentsAdded__c;
                    }
                    if(wrikeData.ReportsAvailable__c != null) {
                        reportsAvailableSum = reportsAvailableSum + wrikeData.ReportsAvailable__c;
                    }
                    if(wrikeData.RequestFormsAvailable__c != null) {
                        requestFormsSum = requestFormsSum + wrikeData.RequestFormsAvailable__c;
                    }
                    if(wrikeData.RequestsFromRequestFormsPast28Days__c != null) {
                        formRequests28DaysSum = formRequests28DaysSum + wrikeData.RequestsFromRequestFormsPast28Days__c;
                    }
                    if(wrikeData.UniqueRequestFormsUsedPast28Days__c != null) {
                        requestFormsUsed28DaysSum = requestFormsUsed28DaysSum + wrikeData.UniqueRequestFormsUsedPast28Days__c;
                    }
                    if(wrikeData.Custom_Fields__c != null) {
                        customFieldsSum = customFieldsSum + wrikeData.Custom_Fields__c;
                    }
                    if(wrikeData.CustomFieldsUsagePast28Days__c != null) {
                        customFields28DaysSum = customFields28DaysSum + wrikeData.CustomFieldsUsagePast28Days__c;
                    }
                    if(wrikeData.UniqueCustomFieldsUsedPast28Days__c != null) {
                        uniqueCustomFields28DaysSum = uniqueCustomFields28DaysSum + wrikeData.UniqueCustomFieldsUsedPast28Days__c;
                    }
                    if(wrikeData.PAAvailable__c != null) {
                        proofingAndApprovalsSum = proofingAndApprovalsSum + wrikeData.PAAvailable__c;
                    }
                    if(wrikeData.PAUsagePast28Days__c != null) {
                        proofingAndApprovals28DaysSum = proofingAndApprovals28DaysSum + wrikeData.PAUsagePast28Days__c;
                    }
                    if(wrikeData.UniquePAUsedPast28Days__c != null) {
                        uniqueProofingAndApprovals28DaysSum = uniqueProofingAndApprovals28DaysSum + wrikeData.UniquePAUsedPast28Days__c;
                    }
                    if(wrikeData.ReportsUsagePast28Days__c != null) {
                        reports28DaysSum = reports28DaysSum + wrikeData.ReportsUsagePast28Days__c;
                    }
                    if(wrikeData.UniqueReportsUsedPast28Days__c != null) {
                        uniqueReports28DaysSum = uniqueReports28DaysSum + wrikeData.UniqueReportsUsedPast28Days__c;
                    }
                    if(wrikeData.CalendarsAvailable__c != null) {
                        calendarsAvailableSum = calendarsAvailableSum + wrikeData.CalendarsAvailable__c;
                    }
                    if(wrikeData.CalendarsUsagePast28Days__c != null) {
                        calendarsUsage28DaysSum = calendarsUsage28DaysSum + wrikeData.CalendarsUsagePast28Days__c;
                    }
                    if(wrikeData.UniqueCalendarsUsedPast28Days__c != null) {
                        uniqueCalendarsUsed28DaysSum = uniqueCalendarsUsed28DaysSum + wrikeData.UniqueCalendarsUsedPast28Days__c;
                    }
                    if(wrikeData.DashboardsAvailable__c != null) {
                        dashboardsAvailableSum = dashboardsAvailableSum + wrikeData.DashboardsAvailable__c;
                    }
                    if(wrikeData.DashboardsUsagePast28Days__c != null) {
                        dashboardsUsage28DaysSum = dashboardsUsage28DaysSum + wrikeData.DashboardsUsagePast28Days__c;
                    }
                    if(wrikeData.UniqueDashboardsUsedPast28Days__c != null) {
                        uniqueDashboardsUsed28DaysSum = uniqueDashboardsUsed28DaysSum + wrikeData.UniqueDashboardsUsedPast28Days__c;
                    }
                    if(wrikeData.UpgradeScore__c != null && (maxUpgradeScore == null || wrikeData.UpgradeScore__c > maxUpgradeScore)) {
                        maxUpgradeScore = wrikeData.UpgradeScore__c;
                    }
                    if(wrikeData.Annual__c == true
                            && wrikeData.Contract_End_Date__c != null
                            && wrikeData.Contract_End_Date__c.date() > Date.today()
                            && (nextAnnualRenewalDate == null || nextAnnualRenewalDate > wrikeData.Contract_End_Date__c.date())) {
                        nextAnnualRenewalDate = wrikeData.Contract_End_Date__c.date();
                    }
                    final String productType = getProductType(wrikeData);
                    if(accountProductType == null) {
                        accountProductType = productType;
                    } else if(accountProductType != productType) {
                        accountProductType = 'Multiple';
                    }
                }
                if(!accountSubscriptions.isEmpty()) {
                    final Decimal wrikeAccountId = accountSubscriptions[0].Wrike_Account_Id__c;
                    if(account.Wrike_Account_Id__c != wrikeAccountId) {
                        addAccountToUpdate(account.Id, accountsToUpdate).Wrike_Account_Id__c = wrikeAccountId;
                    }
                }
            }
            if(account.Opportunities != null && !account.Opportunities.isEmpty()) {
                renewalManagerEmail = account.Opportunities[0].Owner.Email;
            }
            final String subscriptionTerms = annual ? 'Annual' : 'Monthly';
            if(account.Wrike_Subscription_Terms__c != subscriptionTerms) {
                addAccountToUpdate(account.Id, accountsToUpdate).Wrike_Subscription_Terms__c = subscriptionTerms;
            }
            if(account.Subscription_Users_Sum__c != usersSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Users_Sum__c = usersSum;
            }
            if(account.Subscription_Collaborators_Sum__c != collaboratorsSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Collaborators_Sum__c = collaboratorsSum;
            }
            if(account.Subscription_License_Users_Sum__c != licenseUsersSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_License_Users_Sum__c = licenseUsersSum;
            }
            if(account.Subscription_Edit_Wau__c != editWauSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Edit_Wau__c = editWauSum;
            }
            if(account.Subscription_MRR_Sum__c != mrrSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_MRR_Sum__c = mrrSum;
            }
            if(account.Customer_MRR_Sum__c != customerMRRSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Customer_MRR_Sum__c = customerMRRSum;
            }
            if(account.Subscription_Upgrade_Score__c != maxUpgradeScore) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Upgrade_Score__c = maxUpgradeScore;
            }
            if(account.Aggregate_Account_Health_Score__c != activityScoreSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Aggregate_Account_Health_Score__c = activityScoreSum;
            }
            if(account.Subscription_Approval_Reviews_Created__c != approvalReviewsSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Approval_Reviews_Created__c = approvalReviewsSum;
            }
            if(account.Subscription_Proofing_Comments_Added__c != proofingCommentsSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Proofing_Comments_Added__c = proofingCommentsSum;
            }
            if(account.Subscription_Reports_Available__c != reportsAvailableSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Reports_Available__c = reportsAvailableSum;
            }
            if(account.Subscription_Request_Forms_Available__c != requestFormsSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Request_Forms_Available__c = requestFormsSum;
            }
            if(account.Subscription_Forms_Requests_28_Days__c != formRequests28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Forms_Requests_28_Days__c = formRequests28DaysSum;
            }
            if(account.Subscription_Request_Forms_Used_28_Days__c != requestFormsUsed28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Request_Forms_Used_28_Days__c = requestFormsUsed28DaysSum;
            }
            if(account.Subscription_CF__c != customFieldsSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_CF__c = customFieldsSum;
            }
            if(account.Subscription_CF_Usage_28_Days__c != customFields28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_CF_Usage_28_Days__c = customFields28DaysSum;
            }
            if(account.Subscription_Unique_CF_Used_28_Days__c != uniqueCustomFields28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Unique_CF_Used_28_Days__c = uniqueCustomFields28DaysSum;
            }
            if(account.Subscription_PA_Available__c != proofingAndApprovalsSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_PA_Available__c = proofingAndApprovalsSum;
            }
            if(account.Subscription_PA_Usage_28_Days__c != proofingAndApprovals28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_PA_Usage_28_Days__c = proofingAndApprovals28DaysSum;
            }
            if(account.Subscription_Unique_PA_Used_28_Days__c != uniqueProofingAndApprovals28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Unique_PA_Used_28_Days__c = uniqueProofingAndApprovals28DaysSum;
            }
            if(account.Subscription_Reports_Usage_28_Days__c != reports28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Reports_Usage_28_Days__c = reports28DaysSum;
            }
            if(account.Subscription_Unique_Reports_Used_28_Days__c != uniqueReports28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Unique_Reports_Used_28_Days__c = uniqueReports28DaysSum;
            }
            if(account.Subscription_CLD_Available__c != calendarsAvailableSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_CLD_Available__c = calendarsAvailableSum;
            }
            if(account.Subscription_CLD_Usage_28_Days__c != calendarsUsage28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_CLD_Usage_28_Days__c = calendarsUsage28DaysSum;
            }
            if(account.Subscription_Unique_CLD_Used_28_Days__c != uniqueCalendarsUsed28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Unique_CLD_Used_28_Days__c = uniqueCalendarsUsed28DaysSum;
            }
            if(account.Subscription_DB_Available__c != dashboardsAvailableSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_DB_Available__c = dashboardsAvailableSum;
            }
            if(account.Subscription_DB_Usage_28_Days__c != dashboardsUsage28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_DB_Usage_28_Days__c = dashboardsUsage28DaysSum;
            }
            if(account.Subscription_Unique_DB_Usage_28_Days__c != uniqueDashboardsUsed28DaysSum) {
                addAccountToUpdate(account.Id, accountsToUpdate).Subscription_Unique_DB_Usage_28_Days__c = uniqueDashboardsUsed28DaysSum;
            }
            if(account.Product_Type__c != accountProductType) {
                addAccountToUpdate(account.Id, accountsToUpdate).Product_Type__c = accountProductType;
            }
            if(account.Next_Annual_Renewal_Date__c != nextAnnualRenewalDate) {
                addAccountToUpdate(account.Id, accountsToUpdate).Next_Annual_Renewal_Date__c = nextAnnualRenewalDate;
            }
            if(String.isNotBlank(renewalManagerEmail) && account.Account_Renewal_Manager__c != renewalManagerEmail) {
                addAccountToUpdate(account.Id, accountsToUpdate).Account_Renewal_Manager__c = renewalManagerEmail;
            }
            if(account.IsActiveAccountProspects__c){
            	if(account.OwnerId != WrikeConstants.SF_ADMIN_ID){
                    addAccountToUpdate(account.Id, accountsToUpdate).OwnerId = WrikeConstants.SF_ADMIN_ID;    
                }
            	matchAccountList.add(account.Id);
            }
            final Date contactLastInboundActivity = (Date)contactMaxLastInboundActivityMap.get(account.Id)?.get('maxLastInboundActivity');
            if(contactLastInboundActivity != account.Last_Inbound_Activity_new__c && contactLastInboundActivity != null){
                addAccountToUpdate(account.Id, accountsToUpdate).Last_Inbound_Activity_new__c = contactLastInboundActivity;  
            }
            if(account.n2de__Distribution_engine_details__c != null
                    && account.n2de__Distribution_engine_details__r.n2de__Territory__c != null
                    && account.Level_3_Area__c == null
                    && account.Level_5_Territory__c == null
                    && account.Level_6_Sub_Territory__c == null) {
                final List<String> territoryList = account.n2de__Distribution_engine_details__r.n2de__Territory__c.split('\\.');
                if(!territoryList.isEmpty()) {
                    addAccountToUpdate(account.Id, accountsToUpdate).Level_3_Area__c = territoryList[0];
                    if(territoryList.size() > 1) {
                        addAccountToUpdate(account.Id, accountsToUpdate).Level_5_Territory__c = territoryList[1];
                        if(territoryList.size() > 2 && account.Number_of_Employees_from_Account__c < 750) {
                            addAccountToUpdate(account.Id, accountsToUpdate).Level_6_Sub_Territory__c = territoryList[2];
                        }
                    }
                }
            }
        }
        update accountsToUpdate.values();
        
        if(!matchAccountList.isEmpty()){
            List<Task> taskList = [
                SELECT Id 
                FROM Task 
                WHERE Status = 'Open' 
                AND WhatId IN :matchAccountList
            ];
            List<Opportunity> oppList = [
                SELECT Id
                FROM Opportunity 
                WHERE IsClosed = false 
                AND AccountId IN: matchAccountList
            ];
            for(Task newTask : taskList){
                newTask.Status = 'Completed';
                newTask.Description ='Task cancelled when opp was closed lost';
                newTask.Cancelled__c = true;
            }
            for(Opportunity opp : oppList){
                opp.StageName = 'Closed Lost';
            }
            update taskList;
            update oppList;
        }
    }

    private Account addAccountToUpdate(final Id accountId, final Map<Id, Account> accountMap) {
        if(!accountMap.containsKey(accountId)) {
            accountMap.put(accountId, new Account(Id = accountId));
        }
        return accountMap.get(accountId);
    }

    private String getProductType(final WrikeData__c wrikeData) {
        if(wrikeData.Enterprise_Creative__c) {
            return 'Enterprise Creative';
        } else if(wrikeData.Enterprise__c) {
            return 'Enterprise';
        } else if(wrikeData.Business__c) {
            return 'Business';
        } else if(wrikeData.Business_Creative__c) {
            return 'Business Creative';
        } else if(wrikeData.Professional__c) {
            return 'Professional';
        }
        return null;
    }
    
    private Boolean checkAccountTerritory(final Account account){
    	return (account.Level_3_Area__c == null && account.Level_5_Territory__c == null && account.Level_6_Sub_Territory__c == null);   
    }
    
    public void finish(final Database.BatchableContext context) {
    }
}
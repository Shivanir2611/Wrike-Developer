public class AccountTriggerHandler {
    
    public static AccountTriggerHandler getInstance() {
        return (AccountTriggerHandler)ServiceLocator.getInstance(AccountTriggerHandler.class);
    }
    
    public void beforeInsert(final List<Account> accounts) {
        for (Account newAccount : accounts) {
            accountCountryUpdate(newAccount);
        } 
    }
 
    public void beforeUpdate(final Map<Id, Account> oldMap, final Map<Id, Account> newMap) {
        final List<Account> geoTerritoryManagementList = new List<Account>();
        final List<Account> regionTerritoryManagementList = new List<Account>();
        for (Account newAccount : newMap.values()) { 
            final Account oldAccount = oldMap.get(newAccount.Id);
            if (oldAccount.BillingCountryCode != newAccount.BillingCountryCode) {
                accountCountryUpdate(newAccount);   
            }
            if (isAccountOwnerChanged(oldAccount, newAccount)) {
                newAccount.Customer_Request_Date__c = null;
                newAccount.Support_Request_Date__c = null;
            }
            if(oldAccount.Level_3_Area__c != newAccount.Level_3_Area__c){
            	geoTerritoryManagementList.add(newAccount);			    
            }
            if(oldAccount.Level_5_Territory__c != newAccount.Level_5_Territory__c){
            	regionTerritoryManagementList.add(newAccount);
            }
        }
        if(!geoTerritoryManagementList.isEmpty()){
            accountsGeoToUpdate(geoTerritoryManagementList);   
        }
        if(!regionTerritoryManagementList.isEmpty()){
            accountsRegionToUpdate(regionTerritoryManagementList);    
        }
    }

    public void afterUpdate(final Map<Id, Account> oldMap, final Map<Id, Account> newMap) {
        final Map<Id, Id> reassignedAccounts = new Map<Id, Id>();
        final String apiUserId = Settings__c.getOrgDefaults().Wrike_Integration_User_Id__c;
        for(Account newAccount : newMap.values()) {
            final Account oldAccount = oldMap.get(newAccount.Id);
            if(isAccountOwnerChanged(oldAccount, newAccount)) {
                reassignedAccounts.put(newAccount.Id, newAccount.OwnerId);
            }
        }
        if (!reassignedAccounts.isEmpty()){
            final List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            final List<Opportunity> openOpportunities = [
                SELECT Id, Owner.Id, Owner.IsActive, AccountId
                FROM Opportunity
                WHERE AccountId IN :reassignedAccounts.keySet()
                    AND isClosed = false
                    AND Type != 'Renewal'
                    AND eCommerce__c = false
            ];
            for (Opportunity opp : openOpportunities) {
                final Id newOwnerId = newMap.get(opp.AccountId).OwnerId;
                if ((opp.Owner.IsActive == false || opp.Owner.Id == apiUserId) && opp.OwnerId != newOwnerId) {
                    opportunitiesToUpdate.add(new Opportunity(Id = opp.Id, OwnerId = newOwnerId));
                }
            }
            if(!opportunitiesToUpdate.isEmpty()) {
                update opportunitiesToUpdate; 
            }
        }
        reassignedAccountsTasksToUpdate(reassignedAccounts);
    } 
    
    private Boolean isAccountOwnerChanged(final Account oldAccount, final Account newAccount){
        final String apiUserId = Settings__c.getOrgDefaults().Wrike_Integration_User_Id__c;
        return newAccount.OwnerId != apiUserId && oldAccount.OwnerId != newAccount.OwnerId;
    }

    private static void accountCountryUpdate(final Account account){
        account.CountryCode__c = account.BillingCountryCode;
        account.Region__c = RegionUtil.getRegionByCountryCode(account.BillingCountryCode);      
    }
    
    private static void reassignedAccountsTasksToUpdate(final Map<Id, Id> reassignedAccounts){
        if(!reassignedAccounts.isEmpty()) {
            final List<Task> tasksToUpdate = new List<Task>(); 
            final List<Task> openTasks = [
                SELECT Id, OwnerId, WhatId
                FROM Task
                WHERE Status = 'Open' 
                AND WhatId IN :reassignedAccounts.keySet()
                AND CreatedDate >= LAST_N_DAYS:30
            ];
            for(Task task : openTasks) {
                final Id newOwnerId = reassignedAccounts.get(task.WhatId);
                if(task.OwnerId != newOwnerId) {
                    tasksToUpdate.add(new Task(Id = task.Id, OwnerId = newOwnerId));
                }
            }
            if(!tasksToUpdate.isEmpty()) {
                update tasksToUpdate;
            }
        }   
    }
    
    private static void accountsGeoToUpdate(final List<Account> geoTerritoryManagementAccountList){
        final Map<String, String> geoAreaTerritoryMap = new Map<String, String>();
        final List<String> level3List = new List<String>();
        for(Account account : geoTerritoryManagementAccountList){
            level3List.add(account.Level_3_Area__c);
        }
        for(Territory_Management__mdt territoryManagement : getAreaManagementValues(level3List)){
            geoAreaTerritoryMap.put(territoryManagement.Level_3_Area__c, territoryManagement.Level_2_Geo__c);
        }
        for(Account account : geoTerritoryManagementAccountList){
            account.Level_2_Geo__c = geoAreaTerritoryMap.get(account.Level_3_Area__c);					
        }	    
    }
    
    private static void accountsRegionToUpdate(final List<Account> regionTerritoryManagementAccountList){
    	final Map<String, String> geoAreaTerritoryMap = new Map<String, String>();
        final List<String> level5List = new List<String>();
        for(Account account : regionTerritoryManagementAccountList){
            level5List.add(account.Level_5_Territory__c);
        }
        for(Territory_Management__mdt territoryManagement : getTerritoryManagementValues(level5List)){
            geoAreaTerritoryMap.put(territoryManagement.Level_5_Territory__c, territoryManagement.Level_4_Region__c);
        }
        for(Account account : regionTerritoryManagementAccountList){
            account.Level_4_Region__c = geoAreaTerritoryMap.get(account.Level_5_Territory__c);					
        }    
    }
    
    private static List<Territory_Management__mdt> getAreaManagementValues(List<String> level3){
        return [
            SELECT Level_3_Area__c, Level_2_Geo__c
            FROM Territory_Management__mdt
            WHERE Level_3_Area__c IN : level3
        ];
    }

    private static List<Territory_Management__mdt> getTerritoryManagementValues(List<String> level5){
        return [
            SELECT Level_4_Region__c, Level_5_Territory__c
            FROM Territory_Management__mdt
            WHERE Level_5_Territory__c IN : level5
        ];
    }
}
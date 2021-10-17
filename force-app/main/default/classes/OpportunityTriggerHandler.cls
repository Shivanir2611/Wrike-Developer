/*
 * Created by andrey.kuleshov on 26/03/2019.
 */
public class OpportunityTriggerHandler {

	public static OpportunityTriggerHandler getInstance() {
		return (OpportunityTriggerHandler)ServiceLocator.getInstance(OpportunityTriggerHandler.class);
	}

	public void beforeInsert(final List<Opportunity> opps) {
		final Id renewalRecordTypeId = SchemaUtils.getRecordTypeIdByName(Opportunity.getSObjectType(), RecordTypeQueryService.OPPORTUNITY_RENEWAL);
		final Set<Id> contractIds = new Set<Id>();
		for (Opportunity opportunity : opps) {
			if (opportunity.SBQQ__RenewedContract__c != null) {
				contractIds.add(opportunity.SBQQ__RenewedContract__c);
			}
		}
		if (!contractIds.isEmpty()) {
			final List<Contract> contracts = [
					SELECT Id, Wrike_Account_ID__c, EndDate, ContractTerm, Account.Name, SBQQ__RenewalTerm__c, CPQMigration__c
					FROM Contract
					WHERE Id IN :contractIds
			];
			final Map<Id, Contract> contractByIdMap = new Map<Id, Contract>(contracts);
			final Map<Decimal, String> subscriptionNameMap = getSubscriptionNameMap(contracts);
			final Id cpqMigrationUserId = CPQSettings__c.getOrgDefaults().CPQMigrationUserId__c;
			for (Opportunity opportunity : opps) {
				if (opportunity.SBQQ__RenewedContract__c != null) {
					final Contract contract = contractByIdMap.get(opportunity.SBQQ__RenewedContract__c);
					if(contract.CPQMigration__c == true) {
						if(opportunity.OwnerId == WrikeConstants.SF_ADMIN_ID) {
							opportunity.OwnerId = cpqMigrationUserId;
						}
					} else {
						opportunity.OwnerId = WrikeConstants.SF_ADMIN_ID;
					}
					opportunity.Wrike_Account_Id__c = contract.Wrike_Account_ID__c;
					opportunity.RecordTypeId = renewalRecordTypeId;
					opportunity.Type = 'Renewal';
					opportunity.StageName = 'Need To Contact';
					if(contract.SBQQ__RenewalTerm__c != null) {
						final Date contractStartDate = contract.EndDate.addDays(1);
						opportunity.Contract_Start_Date__c = contractStartDate;
						opportunity.Contract_End_Date__c = contractStartDate.addMonths(contract.SBQQ__RenewalTerm__c.intValue());
					}
					final String subscriptionName = subscriptionNameMap.get(contract.Wrike_Account_ID__c);
					final String accountName = contract.Account != null ? contract.Account.Name : '';
					opportunity.Name = String.join(new List<String> {
						StringUtils.defaultIfBlank(subscriptionName, accountName).left(40),
						String.valueOf(contract.Wrike_Account_ID__c),
						'Renewal',
						contract.EndDate.addDays(1).format()
					}, ' - ');
				}
			}
		}
		final List<Decimal> wrikeAccountIds = new List<Decimal>();
		for (Opportunity opp : opps) {
			if (opp.Wrike_Account_Id__c > 0 && opp.Wrike_Data__c == null) {
				wrikeAccountIds.add(opp.Wrike_Account_Id__c);
			}
			if (opp.RecordTypeId != renewalRecordTypeId) {
				opp.Pricebook2Id = Settings__c.getOrgDefaults().StandardPriceBookId__c;
			}
		}
		if (!wrikeAccountIds.isEmpty()) {
			final Map<Decimal, Id> wrikeDataMap = new Map<Decimal, Id>();
			for (WrikeData__c wrikeData : [
					SELECT Id, Wrike_Account_Id__c
					FROM WrikeData__c
					WHERE Wrike_Account_Id__c IN :wrikeAccountIds]) {
				wrikeDataMap.put(wrikeData.Wrike_Account_Id__c, wrikeData.Id);
			}
			for (Opportunity opp : opps) {
				if (opp.Wrike_Account_Id__c > 0 && opp.Wrike_Data__c == null) {
					opp.Wrike_Data__c = wrikeDataMap.get(opp.Wrike_Account_Id__c);
				}
			}
		}
	}

	private Map<Decimal, String> getSubscriptionNameMap(final List<Contract> contracts) {
		final List<Decimal> contractWrikeAccountIds = new List<Decimal>();
		for(Contract contract : contracts) {
			contractWrikeAccountIds.add(contract.Wrike_Account_ID__c);
		}
		final List<Subscription__c> subscriptions = [
				SELECT Name, Wrike_Account_Id__c
				FROM Subscription__c
				WHERE Wrike_Account_Id__c IN :contractWrikeAccountIds
		];
		final Map<Decimal, String> subscriptionNameMap = new Map<Decimal, String>();
		for(Subscription__c subscription : subscriptions) {
			subscriptionNameMap.put(subscription.Wrike_Account_Id__c, subscription.Name);
		}
		return subscriptionNameMap;
	}

	public void beforeUpdate(final Map<Id, Opportunity> oldMap, final Map<Id, Opportunity> newMap) {
		createDeployments(oldMap, newMap);
		updateWrikeData(oldMap, newMap);
		updateTrialStageLastDate(oldMap, newMap);
	}

	public void afterInsert(final Map<Id, Opportunity> newMap) {
		OpportunityDataService.getInstance().createOpportunityData(newMap.values());
		createRelatedPartnersForRenewals(newMap.values());
	}

	public void afterUpdate(final Map<Id, Opportunity> oldMap, final Map<Id, Opportunity> newMap) {
		final List<Id> reassignedOppIds = new List<Id>();
		for (Id oppId : newMap.keySet()) {
			if (oldMap.get(oppId).OwnerId != newMap.get(oppId).OwnerId) {
				reassignedOppIds.add(oppId);
			}
		}
		if (!reassignedOppIds.isEmpty()) {
			final List<Task> tasksToUpdate = new List<Task>();
			final List<Task> openTasks = [
					SELECT Id, OwnerId, WhatId
					FROM Task
					WHERE Status = 'Open'
					AND WhatId IN :reassignedOppIds
                                        AND CreatedDate >= LAST_N_DAYS:30
			];
			for (Task task : openTasks) {
				final Id newOwnerId = newMap.get(task.WhatId).OwnerId;
				if (task.OwnerId != newOwnerId) {
					tasksToUpdate.add(new Task(Id = task.Id, OwnerId = newOwnerId));
				}
			}

			if (!tasksToUpdate.isEmpty()) {
				update tasksToUpdate;
			}
		}
	}

	public void beforeDelete(final Map<Id, Opportunity> oldMap) {
		if (!OrganizationService.getInstance().isSandbox()) {
			for (Opportunity opp : oldMap.values()) {
				if(opp.SBQQ__RenewedContract__c != null) {
					opp.addError('CPQ Renewal Opportunity can not be deleted: ' + opp.Id);
				}
			}
		}
		QuoteService.getInstance().deleteQuoteProductsAndDeleteQuotesInWrike(oldMap.keySet());
	}

	private void updateTrialStageLastDate(final Map<Id, Opportunity> oldMap, final Map<Id, Opportunity> newMap) {
		for (Opportunity newOpportunity : newMap.values()) {
			final Opportunity oldOpportunity = oldMap.get(newOpportunity.Id);

			if (newOpportunity.StageName != oldOpportunity.StageName &&
					(newOpportunity.StageName == '0-MQL' || newOpportunity.StageName == 'Trial')) {
				newOpportunity.Trial_Stage_Last_Date__c = null;
			} else if (oldOpportunity.Trial_Stage_Last_Date__c == null &&
					needUpdateTrialStageLastDateToday(oldOpportunity, newOpportunity)) {
				newOpportunity.Trial_Stage_Last_Date__c = DateUtils.getPacificLocalDate();
			}
		}
	}

	private Boolean needUpdateTrialStageLastDateToday(final Opportunity oldOpportunity,
													  final Opportunity newOpportunity) {
		if (oldOpportunity.Trial_Stage_Last_Date__c != null) {
			return false;
		}

		final Boolean stageNameChanged = newOpportunity.StageName != oldOpportunity.StageName;
		final Boolean demoPursueChanged = newOpportunity.Demo_Pursue__c != oldOpportunity.Demo_Pursue__c;

		if (newOpportunity.Demo_Pursue__c && newOpportunity.StageName == '1-Connect'
				&& (demoPursueChanged || stageNameChanged)) {
			return true;
		}

		return stageNameChanged &&
				(oldOpportunity.StageName == '0-MQL'
						|| oldOpportunity.StageName == 'Trial'
						|| oldOpportunity.StageName == '1-Connect')
				&& (newOpportunity.StageName == '2-Create'
						|| newOpportunity.StageName == '3-Collaborate'
						|| newOpportunity.StageName == '4-Confirm'
						|| newOpportunity.StageName == 'Closed Won - Pending'
						|| newOpportunity.StageName == 'Closed Won');
	}

	private void createDeployments(final Map<Id, Opportunity> oldMap, final Map<Id, Opportunity> newMap) {
		final List<Decimal> deploymentWrikeAccountIds = new List<Decimal>();
		final List<Id> closedWonOpportunityIds = new List<Id>();
		for (Opportunity newOpportunity : newMap.values()) {
			final Opportunity oldOpportunity = oldMap.get(newOpportunity.Id);
			if (newOpportunity.StageName == 'Closed Won' &&
							oldOpportunity.StageName != 'Closed Won' &&
							newOpportunity.Deployment_Created__c == false &&
							newOpportunity.eCommerce__c == false) {
				closedWonOpportunityIds.add(newOpportunity.Id);
				newOpportunity.Deployment_Created__c = true;
				if (newOpportunity.Wrike_Account_Id__c > 0) {
					deploymentWrikeAccountIds.add(newOpportunity.Wrike_Account_Id__c);
				}
			}
		}
		final List<Deployment__c> deployments = DeploymentService.getInstance().createDeployments(closedWonOpportunityIds);

		if (!deployments.isEmpty()) {
			final Map<Decimal, Id> subscriptionMap = new Map<Decimal, Id>();
			final List<Subscription__c> subscriptions = [
					SELECT Id, Wrike_Account_Id__c
					FROM Subscription__c
					WHERE Wrike_Account_Id__c IN :deploymentWrikeAccountIds
			];

			for (Subscription__c subscription : subscriptions) {
				subscriptionMap.put(subscription.Wrike_Account_Id__c, subscription.Id);
			}

			for (Deployment__c deployment : deployments) {
				final Decimal wrikeAccountId = newMap.get(deployment.Opportunity__c).Wrike_Account_Id__c;
				deployment.Subscription__c = subscriptionMap.get(wrikeAccountId);
			}
			insert deployments;

			final List<Id> deploymentIds = new List<Id>();
			for (Deployment__c deployment : deployments) {
				deploymentIds.add(deployment.Id);
			}
                        System.enqueueJob(new DeploymentUtilQueueable(deploymentIds));
		}
	}

	private void updateWrikeData(final Map<Id, Opportunity> oldMap, final Map<Id, Opportunity> newMap) {
		final Map<Id, WrikeData__c> wrikeDataMap = new Map<Id, WrikeData__c>();

		for (Opportunity newOpportunity : newMap.values()) {
			final Opportunity oldOpportunity = oldMap.get(newOpportunity.Id);
			if (newOpportunity.Wrike_Account_Id__c != oldOpportunity.Wrike_Account_Id__c) {
				if (newOpportunity.Wrike_Account_Id__c == null) {
					newOpportunity.Wrike_Data__c = null;
				} else {
					wrikeDataMap.put(newOpportunity.Id, new WrikeData__c(
							Wrike_Account_Id__c = newOpportunity.Wrike_Account_Id__c
					));
				}
			}
		}

		if (!wrikeDataMap.isEmpty()) {
			Database.upsert(wrikeDataMap.values(), Schema.WrikeData__c.Wrike_Account_Id__c, false);
			for (Id opportunityId : wrikeDataMap.keySet()) {
				newMap.get(opportunityId).Wrike_Data__c = wrikeDataMap.get(opportunityId).Id;
			}
		}
	}

	private void createRelatedPartnersForRenewals(final List<Opportunity> opportunities) {
		final Set<Id> renewedContractIds = new Set<Id>();
		for (Opportunity opportunity : opportunities) {
			if (opportunity.SBQQ__RenewedContract__c != null) {
				renewedContractIds.add(opportunity.SBQQ__RenewedContract__c);
			}
		}
		final Map<Id, Contract> contractMap = new Map<Id, Contract>([
				SELECT Id, ResellerAccount__r.Id, ResellerAccount__r.AgreementType__c
				FROM Contract
				WHERE Id IN :renewedContractIds
				AND ResellerAccount__c != null
		]);
		final List<Partner__c> relatedPartnersToCreate = new List<Partner__c>();
		for (Opportunity opportunity : opportunities) {
			if (opportunity.SBQQ__RenewedContract__c != null) {
				final Contract renewedContract = contractMap.get(opportunity.SBQQ__RenewedContract__c);
				if (renewedContract != null) {
					relatedPartnersToCreate.add(new Partner__c(
							Opportunity__c = opportunity.Id,
							Partner__c = renewedContract.ResellerAccount__r.Id,
							Engagement_Level__c = renewedContract.ResellerAccount__r.AgreementType__c
					));
				}
			}
		}
		if (!relatedPartnersToCreate.isEmpty()) {
			insert relatedPartnersToCreate;
		}
	}
}
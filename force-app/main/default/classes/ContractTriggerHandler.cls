public class ContractTriggerHandler {

    public static ContractTriggerHandler getInstance() {
        return (ContractTriggerHandler)ServiceLocator.getInstance(ContractTriggerHandler.class);
    }

    public void beforeUpdate(final Map<Id, Contract> oldMap, final Map<Id, Contract> newMap) {
        final List<Contract> contracts = newMap.values();
        final Set<Id> orderIds = new Set<Id>();
        final Map<Id, Contract> updatedContractMap = new Map<Id, Contract>();
        for (Contract contract : contracts) {
            final Contract oldContract = oldMap.get(contract.Id);
            if (oldContract.SBQQ__Order__c == null && contract.SBQQ__Order__c != null) {
                orderIds.add(contract.SBQQ__Order__c);
            }
            if (oldContract.SBQQ__Order__c != contract.SBQQ__Order__c) {
                updatedContractMap.put(contract.Id, contract);
            }
            if (oldContract.Status == 'Activated'
                    && (contract.Status == 'Cancelled'
                            || contract.Status == 'Suspended'
                            || contract.Status == 'Expired')) {
                contract.NetSuiteContractStatusChanged__c = true;
            }
        }
        if (!orderIds.isEmpty()) {
            final Map<Id, Order> orderByIdMap = new Map<Id, Order>([
                    SELECT Id,
                           QS_Bill_To__c,
                           QS_Ship_To__c,
                           WrikeAccountId__c,
                           SBQQ__Quote__r.QuoteSubType__c,
                           SBQQ__Quote__r.SBQQ__PaymentTerms__c,
                           SBQQ__Quote__r.SBQQ__BillingFrequency__c,
                           SBQQ__Quote__r.SBQQ__RenewalTerm__c,
                           SBQQ__Quote__r.Automatic_Renewal__c,
                           SBQQ__Quote__r.Governing_Terms__c,
                           SBQQ__Quote__r.Tax_Exempt__c,
                           SBQQ__Quote__r.Date_of_Agreement__c,
                           SBQQ__Quote__r.Price_Protection_at_Renewal__c,
                           SBQQ__Quote__r.Removal_of_Publicity_Logo_Rights__c,
                           SBQQ__Quote__r.Addition_of_Co_Marketing__c,
                           SBQQ__Quote__r.Governing_Law__c,
                           SBQQ__Quote__r.DataCenter__c,
                           SBQQ__Quote__r.Additional_users_price_mo__c,
                           SBQQ__Quote__r.Additional_users_increments__c,
                           SBQQ__Quote__r.Additional_Collaborators_price_mo__c,
                           SBQQ__Quote__r.Additional_Collaborators_increments__c,
                           SBQQ__Quote__r.Internal_Notes__c,
                           SBQQ__Quote__r.CurrencyIsoCode,
                           SBQQ__Quote__r.CustomGoverningTerms__c,
                           SBQQ__Quote__r.Other_Governing_Law__c,
                           SBQQ__Quote__r.ResellerAccount__c,
                           SBQQ__Quote__r.AdjustPartnerCommission__c,
                           SBQQ__Quote__r.PurchasingByPO__c,
                           SBQQ__Quote__r.IgnoreQuantityValidation__c

                    FROM Order
                    WHERE Id IN :orderIds
            ]);
            final Id cpqRecordTypeId = SchemaUtils.getRecordTypeIdByName(Contract.getSObjectType(), 'CPQ Contracts');
            for (Contract contract : contracts) {
                final Order order = orderByIdMap.get(contract.SBQQ__Order__c);
                if (order != null) {
                    final SBQQ__Quote__c quote = order.SBQQ__Quote__r;
                    contract.QS_Bill_To__c = order.QS_Bill_To__c;
                    contract.QS_Ship_To__c = order.QS_Ship_To__c;
                    contract.Wrike_Account_ID__c = order.WrikeAccountId__c;
                    contract.RecordTypeId = cpqRecordTypeId;
                    contract.SBQQ__PreserveBundleStructureUponRenewals__c = true;
                    contract.SBQQ__RenewalForecast__c = quote != null
                            && !'New Pilot'.equals(quote.QuoteSubType__c)
                            && !'New POC'.equals(quote.QuoteSubType__c);
                    contract.Status = 'Activated';
                    if(quote != null) {
                        contract.BillingFrequency__c = quote.SBQQ__BillingFrequency__c;
                        contract.PaymentTerms__c = quote.SBQQ__PaymentTerms__c;
                        contract.Auto_Renew__c = quote.Automatic_Renewal__c;
                        contract.GoverningTerms__c = 'New MSA'.equals(quote.Governing_Terms__c)
                                                     ? 'Existing MSA'
                                                     : quote.Governing_Terms__c;
                        contract.QuoteGoverningLaw__c = quote.Governing_Law__c;
                        contract.AgreementDate__c = quote.Date_of_Agreement__c;
                        contract.TaxExempt__c = quote.Tax_Exempt__c;
                        contract.AdditionalUsersPrice__c = quote.Additional_users_price_mo__c;
                        contract.AdditionalUsersIncrements__c = quote.Additional_users_increments__c;
                        contract.AdditionalCollaboratorsPrice__c = quote.Additional_Collaborators_price_mo__c;
                        contract.AdditionalCollaboratorsIncrements__c = quote.Additional_Collaborators_increments__c;
                        contract.RenewalPriceProtection__c = quote.Price_Protection_at_Renewal__c;
                        contract.PublicityLogoRightsRemoval__c = quote.Removal_of_Publicity_Logo_Rights__c;
                        contract.CoMarketingAddition__c = quote.Addition_of_Co_Marketing__c;
                        contract.DataCenter__c = quote.DataCenter__c;
                        contract.InternalNotes__c = quote.Internal_Notes__c;
                        contract.CurrencyIsoCode = quote.CurrencyIsoCode;
                        contract.CustomGoverningTerms__c = quote.CustomGoverningTerms__c;
                        contract.OtherGoverningLaw__c = quote.Other_Governing_Law__c;
                        contract.ResellerAccount__c = quote.ResellerAccount__c;
                        contract.AdjustPartnerCommission__c = quote.AdjustPartnerCommission__c;
                        contract.PurchasingByPO__c = quote.PurchasingByPO__c;
                        contract.IgnoreQuantityValidation__c = quote.IgnoreQuantityValidation__c;
                    }
                }
            }
        }
        if (!updatedContractMap.isEmpty()) {
            final List<SBQQ__Subscription__c> subscriptions = [
                    SELECT SBQQ__Contract__c, MRR__c, SBQQ__EndDate__c
                    FROM SBQQ__Subscription__c
                    WHERE SBQQ__Contract__c IN :updatedContractMap.keySet()
                    ORDER BY SBQQ__Contract__c
            ];
            final Map<Id, Decimal> contractMrrMap = new Map<Id, Decimal>();
            for (SBQQ__Subscription__c subscription : subscriptions) {
                final Contract contract = newMap.get(subscription.SBQQ__Contract__c);
                if (contract.EndDate == subscription.SBQQ__EndDate__c) {
                    final Decimal prevMrr = contractMrrMap.containsKey(subscription.SBQQ__Contract__c)
                                            ? contractMrrMap.get(subscription.SBQQ__Contract__c)
                                            : 0;
                    contractMrrMap.put(subscription.SBQQ__Contract__c, prevMrr + subscription.MRR__c);
                }
            }
            for (Id contractId : contractMrrMap.keySet()) {
                updatedContractMap.get(contractId).ContractEndDateMRR__c = contractMrrMap.get(contractId);
            }
        }
    }

    public void beforeDelete(final List<Contract> contracts) {
        final Id cpqRecordTypeId = SchemaUtils.getRecordTypeIdByName(Contract.getSObjectType(), 'CPQ Contracts');
        final Boolean hasPermissionToDelete = FeatureManagement.checkPermission('CPQContractDeletion');
        final Boolean sandbox = OrganizationService.getInstance().isSandbox();
        for (Contract contract : contracts) {
            if (contract.RecordTypeId == cpqRecordTypeId && !hasPermissionToDelete && !sandbox) {
                contract.addError('CPQ Contract cannot be deleted. Id: ' + contract.Id);
            }
        }
    }

    public void afterUpdate(final Map<Id, Contract> oldMap, final Map<Id, Contract> newMap) {
        final Map<Id, Order> orders = new Map<Id, Order>();
        for (Contract contract : newMap.values()) {
            final Id orderId = contract.SBQQ__Order__c;
            if (orderId != null
                    && orderId != oldMap.get(contract.Id).SBQQ__Order__c ) {
                orders.put(orderId, new Order(
                        Id = orderId,
                        CPQContract__c = contract.Id
                ));
            }
        }
        if (!orders.isEmpty()) {
            update orders.values();
            System.enqueueJob(new CPQOrderNetsuiteSyncJob(orders.keySet()));
        }
    }
}
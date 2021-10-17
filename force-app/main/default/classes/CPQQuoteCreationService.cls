public class CPQQuoteCreationService {

    private final ContractQueryService contractQuerySrv = ContractQueryService.getInstance();
    private final CPQQuoteService quoteSrv = CPQQuoteService.getInstance();
    private final OpportunityQueryService opportunityQuerySrv = OpportunityQueryService.getInstance();
    private final AccountQueryService accountQuerySrv = AccountQueryService.getInstance();
    private final CPQSubscriptionService subscriptionSrv = CPQSubscriptionService.getInstance();

    public static CPQQuoteCreationService getInstance() {
        return (CPQQuoteCreationService)ServiceLocator.getInstance(CPQQuoteCreationService.class);
    }

    public Id createdNewSubscriptionQuote(final Id opportunityId,
                                          final String quoteType,
                                          final String quoteSubType,
                                          final String numberOfTeams) {
        return createdNewSubscriptionQuote(
                opportunityId,
                quoteType,
                quoteSubType,
                numberOfTeams,
                DateUtils.getPacificLocalDate()
        );
    }

    public Id createdNewSubscriptionQuote(final Id opportunityId,
                                          final String quoteType,
                                          final String quoteSubType,
                                          final String numberOfTeams,
                                          final Date startDate) {
        final List<Opportunity> opportunities = [
                SELECT Id, AccountId, Wrike_Account_Id__c, OwnerId
                FROM Opportunity
                WHERE Id = :opportunityId
        ];
        if(!opportunities.isEmpty()) {
            final Opportunity opportunity = opportunities.get(0);
            final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                    SBQQ__Type__c = 'Quote',
                    SBQQ__Status__c = 'Draft',
                    SBQQ__Account__c = opportunity.AccountId,
                    SBQQ__Opportunity2__c = opportunityId,
                    SBQQ__Primary__c = hasNoExistingQuotes(opportunityId),
                    SBQQ__ExpirationDate__c = getQuoteExpirationDate(),
                    WrikeAccountId__c = opportunity.Wrike_Account_Id__c,
                    QuoteType__c = quoteType,
                    QuoteSubType__c = quoteSubType,
                    NumberOfTeams__c = numberOfTeams
            );
            if ('New Pilot'.equals(quoteSubType)) {
                quote.Automatic_Renewal__c = 'No';
                quote.Governing_Terms__c = 'Custom Pilot';
            }
            if ('New POC'.equals(quoteSubType)) {
                quote.Automatic_Renewal__c = 'No';
                quote.Governing_Terms__c = 'POC with Online T&C';
            }
            insert quote;
            final CPQQuoteGroupService groupService = CPQQuoteGroupService.getInstance();
            final SBQQ__QuoteLineGroup__c recurrentGroup = groupService.newGroup('Group1', quote.Id, 1, false);
            recurrentGroup.SBQQ__StartDate__c = startDate;
            recurrentGroup.SBQQ__EndDate__c = startDate.addYears(1).addDays(-1);
            final SBQQ__QuoteLineGroup__c oneTimeGroup = groupService.newGroup('Non-Recurring Products', quote.Id, 2, true);
            oneTimeGroup.SBQQ__StartDate__c = startDate;
            oneTimeGroup.SBQQ__EndDate__c = startDate;
            insert new List<SBQQ__QuoteLineGroup__c> { recurrentGroup, oneTimeGroup };
            quote.SBQQ__LineItemsGrouped__c = true;
            quote.SBQQ__SalesRep__c = opportunity.OwnerId;
            final Account resellerAccount = getResellerAccountFromOpportunity(opportunityId);
            if (resellerAccount != null) {
                quoteSrv.setQuoteFieldsFromResellerAccount(quote, resellerAccount);
            }
            update quote;
            return quote.Id;
        }
        return null;
    }

    public CPQQuoteCreationResponse createAmendmentQuote(final Id opportunityId,
                                                         final Id contractId,
                                                         final String quoteType,
                                                         final String quoteSubType,
                                                         final String numberOfTeams) {
        if ('Restructure'.equals(quoteType)
                && 'Restart Contract (new contract - create)'.equals(quoteSubType)) {
            return createRestructureNewQuote(opportunityId, contractId, quoteType, quoteSubType, numberOfTeams);
        } else {
            return createNewAmendmentQuote(opportunityId, contractId, quoteType, quoteSubType, numberOfTeams);
        }
    }

    private CPQQuoteCreationResponse createRestructureNewQuote(final Id opportunityId,
                                                               final Id contractId,
                                                               final String quoteType,
                                                               final String quoteSubType,
                                                               final String numberOfTeams) {
        final Contract contract = contractQuerySrv.findContractById(contractId);
        if (contract != null) {
            update new Opportunity(
                    Id = opportunityId,
                    Wrike_Account_Id__c = contract.Wrike_Account_ID__c,
                    SBQQ__AmendedContract__c = contract.Id,
                    CurrencyIsoCode = contract.CurrencyIsoCode
            );
            final Id quoteId = createdNewSubscriptionQuote(
                    opportunityId,
                    quoteType,
                    quoteSubType,
                    numberOfTeams,
                    findAmendmentStartDate(contract.Id)
            );
            final Boolean legacySKUs = subscriptionSrv.checkContractHasLegacySKUSubscriptions(contract.Id);
            update new SBQQ__Quote__c(
                    Id = quoteId,
                    CancelledContract__c = contract.Id,
                    ContractHasLegacySKU__c = legacySKUs
            );
            final Opportunity opportunity = opportunityQuerySrv.findOpportunityById(opportunityId);
            final Opportunity cancellationOpportunity = new Opportunity(
                    AccountId = opportunity.AccountId,
                    CloseDate = opportunity.CloseDate,
                    Wrike_Account_Id__c = contract.Wrike_Account_ID__c,
                    StageName = '1-Connect',
                    Type = 'Restructure',
                    RecordTypeId = SchemaUtils.getRecordTypeIdByName(Opportunity.getSObjectType(), 'Fast Track'),
                    Name = 'Contract Restructure – Cancel [' + contract.Wrike_Account_ID__c + ']',
                    CurrencyIsoCode = contract.CurrencyIsoCode,
                    OwnerId = opportunity.OwnerId
            );
            insert cancellationOpportunity;
            final CPQQuoteCreationResponse cancellationQuoteResponse = createNewAmendmentQuote(
                    cancellationOpportunity.Id,
                    contract.Id,
                    'Restructure',
                    'Restart Contract (old contract - cancel)',
                    numberOfTeams
            );
            update new SBQQ__Quote__c(
                    Id = cancellationQuoteResponse.quoteId,
                    RestructureNewQuote__c = quoteId
            );
            quoteSrv.nullifyQuoteLinesQuantity(cancellationQuoteResponse.quoteId);
            if (hasNoExistingQuotes(opportunityId)) {
                update new Opportunity(
                        Id = opportunityId,
                        SBQQ__PrimaryQuote__c = quoteId
                );
            }
            return new CPQQuoteCreationResponse(quoteId);
        }
        return new CPQQuoteCreationResponse('Contract is not found. ' + contractId);
    }

    private CPQQuoteCreationResponse createNewAmendmentQuote(final Id opportunityId,
                                                             final Id contractId,
                                                             final String quoteType,
                                                             final String quoteSubType,
                                                             final String numberOfTeams) {
        final Contract contract = contractQuerySrv.findContractById(contractId);
        if (contract != null) {
            update new Opportunity(
                    Id = opportunityId,
                    Wrike_Account_Id__c = contract.Wrike_Account_ID__c,
                    SBQQ__AmendedContract__c = contract.Id,
                    CurrencyIsoCode = contract.CurrencyIsoCode
            );
            final Id resellerAccountId = contract.ResellerAccount__c;
            final List<Partner__c> relatedPartners = opportunityQuerySrv.findOpportunityResellerPartners(opportunityId);
            final String errorMessage = validateAmendmentRelatedPartners(relatedPartners, resellerAccountId);
            if (errorMessage != null) {
                return new CPQQuoteCreationResponse(errorMessage);
            }
            if (relatedPartners.isEmpty() && resellerAccountId != null) {
                createRelatedPartner(
                        opportunityId,
                        resellerAccountId,
                        contract.ResellerAccount__r.AgreementType__c
                );
            }
            final Date amendmentStartDate = findAmendmentStartDate(contractId);
            update new Contract(
                    Id = contractId,
                    SBQQ__AmendmentStartDate__c = amendmentStartDate
            );
            final String quoteJSON =
                    SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
            final QuoteModel quoteModel = (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
            final Id quoteId = quoteModel.record.Id;
            CPQQuoteGroupService.getInstance().restoreQuoteGroups(quoteModel.record, amendmentStartDate, false);
            final Id amendmentOpportunityId = CPQQuoteQueryService.getInstance().findOpportunityIdByQuoteId(quoteId);
            final Boolean makePrimary = hasNoExistingQuotes(opportunityId);
            if (makePrimary != quoteModel.record.SBQQ__Primary__c) {
                /*
                 * This separate update is needed because SBQQ__Primary__c and SBQQ__Opportunity2__c field updates
                 * can't be combined in one action due to inconsistent CPQ logic of SBQQ__PrimaryQuote__c field.
                 */
                update new SBQQ__Quote__c(
                        Id = quoteId,
                        SBQQ__Primary__c = makePrimary
                );
            }
            final Boolean legacySKUs = subscriptionSrv.checkContractHasLegacySKUSubscriptions(contractId);
            final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                    Id = quoteId,
                    SBQQ__Opportunity2__c = opportunityId,
                    SBQQ__ExpirationDate__c = getQuoteExpirationDate(),
                    QuoteType__c = quoteType,
                    QuoteSubType__c = quoteSubType,
                    NumberOfTeams__c = numberOfTeams,
                    SBQQ__LineItemsGrouped__c = true,
                    SBQQ__SalesRep__c = opportunityQuerySrv.findOwnerIdById(opportunityId),
                    ContractHasLegacySKU__c = legacySKUs,
                    AllowLegacyBasePlans__c = legacySKUs
            );
            final Account resellerAccount = resellerAccountId != null
                                            ? accountQuerySrv.findResellerAccountById(resellerAccountId)
                                            : null;
            if (resellerAccount != null) {
                quoteSrv.setQuoteFieldsFromResellerAccount(quote, resellerAccount);
            }
            update quote;
            if (makePrimary) {
                update new Opportunity(
                        Id = opportunityId,
                        SBQQ__PrimaryQuote__c = quoteId
                );
            }
            if (amendmentOpportunityId != null && amendmentOpportunityId != opportunityId) {
                delete new Opportunity(
                        Id = amendmentOpportunityId
                );
            }
            return new CPQQuoteCreationResponse(quoteId);
        }
        return new CPQQuoteCreationResponse('Contract is not found. ' + contractId);
    }

    public Id createAutoRenewalQuote(final Id opportunityId, final Id selectedContractId) {
        return createRenewalQuote(opportunityId, '0', selectedContractId, true);
    }

    public Id createRenewalQuote(final Id opportunityId,
                                 final String numberOfTeams,
                                 final Id selectedContractId) {
        return createRenewalQuote(opportunityId, numberOfTeams, selectedContractId, false);
    }

    private Id createRenewalQuote(final Id opportunityId,
                                  final String numberOfTeams,
                                  final Id selectedContractId,
                                  final Boolean autoRenewal) {
        final Opportunity opportunity = [
                SELECT Id, SBQQ__RenewedContract__r.Id, OwnerId
                FROM Opportunity
                WHERE Id = :opportunityId
        ];
        final Id contractId = opportunity.SBQQ__RenewedContract__r != null
                              ? opportunity.SBQQ__RenewedContract__r.Id
                              : selectedContractId;
        final Contract contract = contractId != null
                                  ? contractQuerySrv.findContractById(contractId)
                                  : null;
        if (contract != null) {
            if (opportunity.SBQQ__RenewedContract__r.Id != selectedContractId) {
                update new Opportunity(
                        Id = opportunityId,
                        Wrike_Account_Id__c = contract.Wrike_Account_ID__c,
                        SBQQ__RenewedContract__c = contract.Id,
                        CurrencyIsoCode = contract.CurrencyIsoCode
                );
            }
            final Boolean primaryQuote = hasNoExistingQuotes(opportunityId);
            final RenewalContext renewalContext = new RenewalContext(
                    contractId,
                    new List<Contract> {new Contract(Id = contractId)}
            );
            final String quoteJSON = SBQQ.ServiceRouter.load(
                    'SBQQ.ContractManipulationAPI.ContractRenewer',
                    contractId,
                    JSON.serialize(renewalContext));
            final List<QuoteModel> quotes = (List<QuoteModel>) JSON.deserialize(quoteJSON, List<QuoteModel>.class);
            if (!quotes.isEmpty()) {
                CPQQuoteGroupService.getInstance().restoreQuoteGroups(quotes[0].record, null, true);
                final Id quoteId = quotes[0].record.Id;
                final Boolean legacySKUs = subscriptionSrv.checkContractHasLegacySKUSubscriptions(contractId);
                final SBQQ__Quote__c updatedQuote = new SBQQ__Quote__c(
                        Id = quoteId,
                        SBQQ__Primary__c = primaryQuote,
                        SBQQ__ExpirationDate__c = findContractEndDate(contractId),
                        QuoteType__c = 'Renewal',
                        NumberOfTeams__c = numberOfTeams,
                        SBQQ__Opportunity2__c = opportunityId,
                        SBQQ__LineItemsGrouped__c = true,
                        BypassValidationRules__c = false,
                        SBQQ__SalesRep__c = opportunity.OwnerId,
                        ContractHasLegacySKU__c = legacySKUs,
                        AllowLegacyBasePlans__c = legacySKUs
                );
                if (autoRenewal) {
                    if ('Custom schedule'.equalsIgnoreCase(contract.BillingFrequency__c)) {
                        updatedQuote.SBQQ__BillingFrequency__c = 'Upfront';
                    }
                    updatedQuote.ApprovalRequired__c = false;
                    updatedQuote.RemoveSignatureBlock__c = true;
                    updatedQuote.SBQQ__SalesRep__c = WrikeConstants.SF_ADMIN_ID;
                }
                final List<Partner__c> relatedPartners =
                        opportunityQuerySrv.findOpportunityResellerPartners(opportunityId);
                if (relatedPartners.isEmpty() && contract.ResellerAccount__c != null) {
                    createRelatedPartner(
                            opportunityId,
                            contract.ResellerAccount__r.Id,
                            contract.ResellerAccount__r.AgreementType__c
                    );
                }
                final Id resellerAccountId = relatedPartners.size() == 1
                                             ? relatedPartners.get(0).Partner__c
                                             : contract.ResellerAccount__c;
                final Account resellerAccount = resellerAccountId != null
                                                ? accountQuerySrv.findResellerAccountById(resellerAccountId)
                                                : null;
                if (resellerAccount != null) {
                    quoteSrv.setQuoteFieldsFromResellerAccount(updatedQuote, resellerAccount);
                }
                update updatedQuote;
                if (primaryQuote) {
                    update new Opportunity(
                            Id = opportunityId,
                            SBQQ__PrimaryQuote__c = quoteId
                    );
                }
                return quoteId;
            }
        }
        return null;
    }

    public Id createSelfRenewalQuote(final Id contractId,
                                     final String userName,
                                     final String userEmail) {
        final Contract contract = [
                SELECT Id, SBQQ__RenewalOpportunity__c, BillingFrequency__c
                FROM Contract
                WHERE Id = :contractId
                  AND Status = 'Activated'
        ];
        final RenewalContext renewalContext = new RenewalContext(
                contractId,
                new List<Contract> {new Contract(Id = contractId)}
        );
        final String quoteJSON = SBQQ.ServiceRouter.load(
                'SBQQ.ContractManipulationAPI.ContractRenewer',
                contractId,
                JSON.serialize(renewalContext));
        final List<QuoteModel> quotes = (List<QuoteModel>) JSON.deserialize(quoteJSON, List<QuoteModel>.class);
        final Id quoteId = quotes[0].record.Id;
        final Id opportunityId = contract.SBQQ__RenewalOpportunity__c;
        final Boolean primaryQuote = hasNoExistingQuotes(opportunityId);
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__Primary__c = primaryQuote,
                SBQQ__ExpirationDate__c = findContractEndDate(contractId),
                QuoteType__c = 'Renewal',
                NumberOfTeams__c = '0',
                SBQQ__Opportunity2__c = opportunityId,
                SBQQ__LineItemsGrouped__c = true,
                eCommerce__c = true,
                SelfServiceRenewal__c = true,
                SelfServiceUserName__c = StringUtils.getEmptyIfNull(userName).left(80),
                SelfServiceUserEmail__c = StringUtils.getEmptyIfNull(userEmail).left(80),
                BypassValidationRules__c = true
        );
        if ('Custom schedule'.equalsIgnoreCase(contract.BillingFrequency__c)) {
            quote.SBQQ__BillingFrequency__c = 'Upfront';
        }
        quote.ApprovalRequired__c = false;
        quote.RemoveSignatureBlock__c = true;
        quote.SBQQ__SalesRep__c = WrikeConstants.SF_ADMIN_ID;
        update quote;
        return quoteId;
    }

    private String validateAmendmentRelatedPartners(final List<Partner__c> relatedPartners,
                                                    final Id contractResellerAccountId) {
        if (!relatedPartners.isEmpty() && contractResellerAccountId == null) {
            return 'Contract you\'ve selected has no Partner ID. ' +
                    'To amend this contract, the opportunity must have no Related Partner on it.';
        }
        if (!relatedPartners.isEmpty() && contractResellerAccountId != null) {
            Boolean partnerMatch = false;
            for (Partner__c relatedPartner : relatedPartners) {
                if (contractResellerAccountId == relatedPartner.Partner__c) {
                    partnerMatch = true;
                }
            }
            if (!partnerMatch) {
                return 'Contract you\'ve selected has a Partner ID different ' +
                        'from the Opportunity Related Partner. To continue, either remove Related Partner ' +
                        'from the Opportunity or create a new subscription quote.';
            }
        }
        return null;
    }

    public Date findAmendmentStartDate(final Id contractId) {
        final List<AggregateResult> subscriptionData = [
                SELECT min(SBQQ__StartDate__c) lastStartDate
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c = :contractId
                  AND SBQQ__EndDate__c >= :DateUtils.getPacificLocalDate()
        ];
        return subscriptionData.isEmpty()
               ? null
               : (Date)subscriptionData[0].get('lastStartDate');
    }

    public Date findContractEndDate(final Id contractId) {
        final List<AggregateResult> subscriptionData = [
                SELECT max(SBQQ__EndDate__c) lastEndDate
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c = :contractId
        ];
        return subscriptionData.isEmpty()
               ? null
               : (Date)subscriptionData[0].get('lastEndDate');
    }

    public Boolean hasNoExistingQuotes(final Id opportunityId) {
        return [
                SELECT Id
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__c = :opportunityId
        ].isEmpty();
    }

    @TestVisible
    private Date getQuoteExpirationDate() {
        final Date today = DateUtils.getPacificLocalDate();
        final Date monthLastDay = today
                .toStartOfMonth()
                .addMonths(1)
                .addDays(-1);
        final Date lastBusinessDay = getBusinessDay(monthLastDay);
        return today > lastBusinessDay ? today : lastBusinessDay;
    }

    private Date getBusinessDay(final Date value) {
        switch on DateUtils.format(value, 'EEE') {
            when 'Sun' {
                return value.addDays(-2);
            }
            when 'Sat' {
                return value.addDays(-1);
            }
            when else {
                return value;
            }
        }
    }

    private Account getResellerAccountFromOpportunity(final Id opportunityId) {
        final List<Partner__c> partners = [
                SELECT Id, Partner__r.Id, Partner__r.AgreementType__c, Partner__r.TaxExempt__c,
                       Partner__r.GoverningTerms__c, Partner__r.GoverningTermsDate__c,
                       Partner__r.PaymentTerms__c, Partner__r.NewSubscriptionCommission__c,
                       Partner__r.RenewalSubscriptionCommission__c, Partner__r.OnetimeFeesCommission__c
                FROM Partner__c
                WHERE Opportunity__c = :opportunityId
                AND (Engagement_Level__c = 'Reseller'
                OR Engagement_Level__c = 'Local Agent')
        ];
        if (partners.size() == 1) {
            return partners.get(0).Partner__r;
        }
        return null;
    }

    private void createRelatedPartner(final Id opportunityId,
                                      final Id resellerAccountId,
                                      final String engagementLevel) {
        insert new Partner__c(
                Opportunity__c = opportunityId,
                Partner__c = resellerAccountId,
                Engagement_Level__c = engagementLevel
        );
    }

    public class QuoteModel {
        public SBQQ__Quote__c record;
    }

    public class RenewalContext {
        public RenewalContext(Id masterContractId, List<Contract> renewedContracts) {
            this.masterContractId = masterContractId;
            this.renewedContracts = renewedContracts;
        }

        public Id masterContractId;
        public List<Contract> renewedContracts;
    }

    public class CPQQuoteCreationResponse {
        @AuraEnabled
        public Id quoteId {get; set;}
        @AuraEnabled
        public String errorMessage {get; set;}

        public CPQQuoteCreationResponse(final String errorMessage) {
            this.errorMessage = errorMessage;
        }

        public CPQQuoteCreationResponse(final Id quoteId) {
            this.quoteId = quoteId;
        }
    }
}
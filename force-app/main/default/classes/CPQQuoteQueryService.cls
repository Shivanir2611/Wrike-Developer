public class CPQQuoteQueryService {

    public static CPQQuoteQueryService getInstance() {
        return (CPQQuoteQueryService)ServiceLocator.getInstance(CPQQuoteQueryService.class);
    }

    public SBQQ__Quote__c findQuoteById(final Id quoteId) {
        final List<SBQQ__Quote__c> quotes = [
                SELECT Id, Name, SBQQ__BillingFrequency__c, SubscriptionTotal__c, OneTimeTotal__c, SBQQ__StartDate__c,
                       SBQQ__EndDate__c, SBQQ__Status__c, SBQQ__Account__c, SBQQ__Account__r.Id, SBQQ__Account__r.Name,
                       Document__c, Document__r.SBQQ__DocumentId__c, QS_Bill_To__r.Id, QS_Bill_To__r.VATNumber__c,
                       QS_Bill_To__r.QS_Country_Code__c, QS_Bill_To__r.QS_State_Code__c, QS_Bill_To__r.QS_Zip_Postal_Code__c,
                       QS_Ship_To__c, WrikeAccountId__c, EndCustomer__c, PreSignDocument__c, AllowLegacyBasePlans__c,
                       CurrencyIsoCode, SBQQ__Primary__c, Delta_MRR__c, NumberOfTeams__c, SBQQ__Type__c,
                       QuoteType__c, QuoteSubType__c, SBQQ__ExpirationDate__c, SBQQ__PaymentTerms__c,
                       Governing_Terms__c, Date_of_Agreement__c, ResellerAccount__c, PurchasingByPO__c,
                       BillingFrequencyMonths__c, Number_of_Invoices__c, Subscription_Monthly_Rate__c,
                       Term_in_Months__c, CustomGoverningTerms__c, RestructureNewQuote__c,
                       SBQQ__Opportunity2__r.Id, SBQQ__Opportunity2__r.Name, SBQQ__Opportunity2__r.Wrike_Account_Id__c,
                       SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, DocumentHasDraftWatermark__c,
                       SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,
                       SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.ActivatedRenewalQuote__c,
                       SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.ActivatedRenewalQuote__r.SBQQ__Opportunity2__c,
                       SBQQ__Opportunity2__r.RecordTypeId,
                       ApprovalRequired__c, ApprovalStatus__c, CancelledContract__c,
                       DocuSignEnvelope__r.dsfs__DocuSign_Envelope_ID__c,
                       (SELECT Id, Name, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c, SBQQ__SubscriptionType__c,
                               SBQQ__NetTotal__c, SBQQ__EffectiveQuantity__c, Effective_Price__c, NonRenewableDiscount__c,
                               SBQQ__Quote__c, SBQQ__Bundled__c, CurrencyIsoCode,
                               SBQQ__Product__r.Id, SBQQ__Product__r.Name, SBQQ__Product__r.NetsuiteIntegrationId__c,
                               SBQQ__Product__r.PG1__c, SBQQ__Product__r.PG2__c, SBQQ__Product__r.PG3__c,
                               SBQQ__Product__r.SBQQ__ChargeType__c, SBQQ__Product__r.MaxNumberOfTeams__c, SBQQ__Product__r.ParentProduct__c,
                               SBQQ__Product__r.ProductCode
                          FROM SBQQ__LineItems__r
                         WHERE EffectiveLine__c = true
                      ORDER BY SBQQ__Product__r.SBQQ__SortOrder__c),
                       (SELECT Id, Name, Invoice_Number__c, Subscription_Amount__c, One_Time_Fee_Amount__c, Invoice_Date__c,
                               Service_Start_Date__c, Service_End_Date__c, Service_Term_In_Months__c, Quote__c
                          FROM Billing_Schedules__r
                      ORDER BY Invoice_Number__c),
                       (SELECT Id, OrderNumber
                          FROM SBQQ__Orders__r
                         LIMIT 1)
                  FROM SBQQ__Quote__c
                 WHERE Id = :quoteId
        ];
        return quotes.isEmpty() ? null : quotes.get(0);
    }

    public SBQQ__Quote__c findWithStatusForUpdateById(final Id quoteId) {
        final List<SBQQ__Quote__c> quotes = [
                SELECT Id, SBQQ__Status__c
                  FROM SBQQ__Quote__c
                 WHERE Id = :quoteId
                FOR UPDATE
        ];
        return quotes.isEmpty() ? null : quotes.get(0);
    }

    public Id findOneTimeGroupId(final Id quoteId) {
        return [
                SELECT Id
                FROM SBQQ__QuoteLineGroup__c
                WHERE OneTime__c = true
                AND SBQQ__Quote__c = :quoteId
        ]?.Id;
    }

    public Id findDeploymentsBundleId(final Id quoteId) {
        final List<SBQQ__QuoteLine__c> items = [
                SELECT Id
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Product__c = :Settings__c.getOrgDefaults().ProfessionalServicesPackageId__c
                AND SBQQ__Quote__c = :quoteId
        ];
        return items.isEmpty() ? null : items.get(0).Id;
    }

    public Id findOpportunityIdByQuoteId(final Id quoteId) {
        final List<SBQQ__Quote__c> quotes = [
                SELECT SBQQ__Opportunity2__c
                  FROM SBQQ__Quote__c
                 WHERE Id = :quoteId
        ];
        return quotes.isEmpty() ? null : quotes.get(0).SBQQ__Opportunity2__c;
    }

    public Id findExistingPrimaryQuoteId(final Id opportunityId) {
        final List<SBQQ__Quote__c> quotes = [
                SELECT Id
                  FROM SBQQ__Quote__c
                 WHERE SBQQ__Opportunity2__c = :opportunityId
                   AND SBQQ__Primary__c = true
        ];
        return quotes.isEmpty() ? null : quotes.get(0).Id;
    }

    public String findExistingPrimaryQuoteStatus(final Id opportunityId) {
        final List<SBQQ__Quote__c> quotes = [
                SELECT Id, SBQQ__Status__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__c = :opportunityId
                AND SBQQ__Primary__c = true
        ];
        return quotes.isEmpty() ? null : quotes.get(0).SBQQ__Status__c;
    }

    public SBQQ__Quote__c findWithBillToShipToById(final String quoteId) {
        final List<SBQQ__Quote__c> quotes = [
                SELECT Id, SBQQ__Account__c, WrikeAccountId__c, ResellerAccount__c,
                       QS_Bill_To__r.Id, QS_Bill_To__r.QS_Email__c, QS_Bill_To__r.QS_Country_Code__c,
                       QS_Bill_To__r.QS_State_Code__c, QS_Bill_To__r.QS_City__c, QS_Bill_To__r.QS_Street_1__c,
                       QS_Bill_To__r.QS_Street_2__c, QS_Bill_To__r.QS_Attention_To__c,
                       QS_Bill_To__r.QS_Zip_Postal_Code__c, QS_Bill_To__r.QS_Phone__c,
                       QS_Bill_To__r.QS_Invoice_via_Email__c,
                       QS_Bill_To__r.QS_Invoice_via_Portal__c, QS_Bill_To__r.Billing_Comments__c,
                       QS_Bill_To__r.QS_Secondary_Email__c, QS_Bill_To__r.RegionState__c,
                       QS_Bill_To__r.QS_Company_Name__c, QS_Bill_To__r.QS_Bill_To__c,
                       QS_Bill_To__r.QS_Account__c, QS_Bill_To__r.Wrike_Account_ID__c,
                       QS_Bill_To__r.VATNumber__c, QS_Bill_To__r.PartnerAccount__c,
                       QS_Bill_To__r.QS_Ship_To__c, QS_Bill_To__r.EndCustomer__c,

                       QS_Ship_To__r.Id, QS_Ship_To__r.QS_Email__c, QS_Ship_To__r.QS_Country_Code__c,
                       QS_Ship_To__r.QS_State_Code__c, QS_Ship_To__r.QS_City__c, QS_Ship_To__r.QS_Street_1__c,
                       QS_Ship_To__r.QS_Street_2__c, QS_Ship_To__r.QS_Attention_To__c,
                       QS_Ship_To__r.QS_Zip_Postal_Code__c, QS_Ship_To__r.QS_Phone__c,
                       QS_Ship_To__r.QS_Secondary_Email__c, QS_Ship_To__r.RegionState__c,
                       QS_Ship_To__r.QS_Company_Name__c, QS_Ship_To__r.QS_Ship_To__c,
                       QS_Ship_To__r.QS_Account__c, QS_Ship_To__r.Wrike_Account_ID__c,
                       QS_Ship_To__r.PartnerAccount__c, QS_Ship_To__r.QS_Bill_To__c,
                       QS_Ship_To__r.EndCustomer__c,

                       EndCustomer__r.Id, EndCustomer__r.QS_Email__c, EndCustomer__r.QS_Country_Code__c,
                       EndCustomer__r.QS_State_Code__c, EndCustomer__r.QS_City__c, EndCustomer__r.QS_Street_1__c,
                       EndCustomer__r.QS_Street_2__c, EndCustomer__r.QS_Attention_To__c,
                       EndCustomer__r.QS_Zip_Postal_Code__c, EndCustomer__r.QS_Phone__c,
                       EndCustomer__r.QS_Secondary_Email__c, EndCustomer__r.RegionState__c,
                       EndCustomer__r.QS_Company_Name__c, EndCustomer__r.QS_Ship_To__c,
                       EndCustomer__r.QS_Account__c, EndCustomer__r.Wrike_Account_ID__c,
                       EndCustomer__r.PartnerAccount__c, EndCustomer__r.QS_Bill_To__c,
                       EndCustomer__r.EndCustomer__c
                  FROM SBQQ__Quote__c
                 WHERE Id = :quoteId
        ];
        return quotes.isEmpty() ? null : quotes.get(0);
    }

    public dsfs__DocuSign_Status__c findDocuSignStatusByQuoteId(final Id quoteId) {
        final List<dsfs__DocuSign_Status__c> statuses = [
                SELECT Id
                FROM dsfs__DocuSign_Status__c
                WHERE Quote__c = :quoteId
        ];
        return statuses.isEmpty() ? null : statuses.get(0);
    }

    public List<SBQQ__Quote__c> findQuotesApprovalInfoByIds(final Set<Id> quoteIds) {
        return [
                SELECT Id, Name, Delta_MRR__c, SBQQ__Opportunity2__r.Id, SBQQ__Opportunity2__r.Name,
                       SBQQ__SalesRep__r.Id, SBQQ__SalesRep__r.Name, Total_Order_Value__c, SBQQ__Status__c,
                       CurrencyIsoCode
                FROM SBQQ__Quote__c
                WHERE Id IN :quoteIds
                AND SBQQ__Status__c = 'PendingApproval'
        ];
    }

    public List<SBQQ__Quote__c> findActivatedRenewalQuotesByContract(final Id contractId) {
        return [
                SELECT Id
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__r.SBQQ__RenewedContract__c = :contractId
                AND SBQQ__Type__c = 'Renewal'
                AND SBQQ__Status__c != 'Draft'
        ];
    }

    public List<SBQQ__QuoteLine__c> findQuoteLinesByQuoteId(final Id quoteId) {
        return [
                SELECT Id, SBQQ__ChargeType__c, NonRenewableDiscount__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
        ];
    }
}
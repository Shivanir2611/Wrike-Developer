public with sharing class QuoteQueryService {

    public static QuoteQueryService getInstance() {
        return (QuoteQueryService)ServiceLocator.getInstance(QuoteQueryService.class);
    }

    public List<Quote__c> findWithItemsById(final String quoteId) {
        return [
            SELECT Id, CreatedDate, Name, Primary__c, AmendmentType__c,
                CurrencyIsoCode, Opportunity__c, Zuora_Account_Id__c, Zuora_Subscription_Id__c,
                EffectiveDate__c, SubscriptionStartDate__c, SubscriptionEndDate__c, Number__c, QuoteType__c,
                Status__c, Pdf_Id__c, Total__c, DeltaMrr__c, BaseLicenseMrr__c, TargetInvoiceDate__c, InvoiceDate__c,
                ValidUntil__c, WrikeAccountId__c, CompanyName__c, Notes__c, ZuoraAccountName__c, ZuoraSubscriptionName__c,
                SalesName__c, SalesEmail__c, SalesPhone__c, InitialTerm__c, NewTerm__c, RenewalTerm__c,
                PaymentTerm__c, LegalTerms__c, LegalTermsEffectiveDate__c, CreditCardLink__c,
                HashCode__c, Reason_for_Approval_Request__c, Reason_for_Discount__c, LastEditDateTime__c, TaxExempt__c,
                TaxExemptCertificateId__c, DataCenter__c, OriginalQuote__c, IsOriginalQuoteApproved__c, LicenseDiscount__c,
                DeploymentDiscount__c, DeploymentName__c, BillingPeriodName__c,
                OldProductName__c, NewProductName__c, OldQuantity__c, NewQuantity__c,
                AddonQuantity__c, AdvancedFeatureAddonQuantity__c, CollaboratorBaseLicenseRate__c,
                OldPricePerUserPerMonth__c, NewPricePerUserPerMonth__c, IsTravelPaid__c, NoPSIntegrate__c, OnetimeDiscountIncluded__c,
                NumberOfTeams__c, HasCustomDeployment__c, AdditionalUsers__c, AutoRenewalRemoval__c, RenewalPriceProtection__c,
                PublicityRightsRemoval__c, CoMarketingAddition__c, GoverningLaw__c, TermsDataCenter__c,
                AgencyReliefOfferDiscount__c, PremiumSupportMismatch__c, OriginalQuote__r.Name,
                Opportunity__r.Name, Opportunity__r.AccountId, Opportunity__r.Billing_Contact__r.Email,
                Opportunity__r.Billing_Contact__r.FirstName, Opportunity__r.Billing_Contact__r.LastName,
                Opportunity__r.OpportunityData__c, Opportunity__r.Owner.Name, Opportunity__r.Owner.Email,
                Opportunity__r.Owner.Phone, Opportunity__r.RecordType.DeveloperName, Opportunity__r.CurrencyIsoCode,
                Opportunity__r.Vertical_Segment__c,
                (
                    SELECT Id, State__c, Product__c, Quote__c, UID__c, ParentItemUID__c,
                        Product__r.Id, Product__r.Name, Product__r.Description__c, Product__r.MRR__c,
                        Product__r.Quantity__c, Product__r.Term__c, Product__r.ChargeType__c, Product__r.ChargeModel__c, Product__r.ChargeNumber__c,
                        Product__r.BillingIntervalListPrice__c, Product__r.Price__c, Product__r.PricePerUserPerMonth__c, Product__r.PriceFormat__c,
                        Product__r.ServiceType__c, Product__r.Discount__c, Product__r.DiscountReason__c,
                        Product__r.BillingPeriodName__c, Product__r.ZuoraProductId__c, Product__r.ZuoraProductRatePlanId__c,
                        Product__r.ZuoraProductRatePlanChargeId__c, Product__r.ZuoraProductRatePlanChargeName__c,
                        Product__r.ZuoraRatePlanId__c, Product__r.ZuoraRatePlanChargeId__c, Product__r.Product__c,
                        Product__r.SoftBundleDiscountApplied__c
                    FROM Quote_Items__r
                    ORDER BY State__c
                )
            FROM Quote__c
            WHERE Id = :quoteId
        ];
    }

    public List<Quote__c> findWithOpportunityAndContactById(final String quoteId) {
        return [
            SELECT Id, Name, Primary__c, AmendmentType__c, CreditCardLink__c,
                CurrencyIsoCode, Opportunity__c, Zuora_Account_Id__c, Zuora_Subscription_Id__c, ZuoraCreditCardId__c,
                EffectiveDate__c, SubscriptionStartDate__c, SubscriptionEndDate__c, Number__c, QuoteType__c, Status__c, Pdf_Id__c,
                ValidUntil__c, WrikeAccountId__c, CompanyName__c, Notes__c, ZuoraAccountName__c, ZuoraSubscriptionName__c,
                SalesName__c, SalesEmail__c, SalesPhone__c, Reason_for_Approval_Request__c, Reason_for_Discount__c,
                Total__c, LicenseDiscount__c, DeploymentDiscount__c, DeploymentName__c, BillingPeriodName__c, OldProductName__c, NewProductName__c,
                OldQuantity__c, NewQuantity__c, AddonQuantity__c, AdvancedFeatureAddonQuantity__c, OldPricePerUserPerMonth__c, NewPricePerUserPerMonth__c,
                InvoiceDate__c, TaxExempt__c, TaxExemptCertificateId__c, DataCenter__c, OriginalQuote__c, IsOriginalQuoteApproved__c,
                IsTravelPaid__c, NoPSIntegrate__c,
                OriginalQuote__r.Name,
                Opportunity__r.AccountId, Opportunity__r.Name, Opportunity__r.BillingCountryCode__c, Opportunity__r.VAT__c,
                Opportunity__r.VAT_Valid__c, Opportunity__r.RecordType.DeveloperName,
                Opportunity__r.Billing_Contact__r.Name,
                Opportunity__r.Billing_Contact__r.FirstName, Opportunity__r.Billing_Contact__r.LastName,
                Opportunity__r.Billing_Contact__r.Email, Opportunity__r.Billing_Contact__r.MailingStreet,
                Opportunity__r.Billing_Contact__r.MailingCity, Opportunity__r.Billing_Contact__r.MailingStateCode,
                Opportunity__r.Billing_Contact__r.MailingPostalCode, Opportunity__r.Billing_Contact__r.MailingCountryCode,
                Opportunity__r.Billing_Contact__r.MailingCountry, Opportunity__r.Billing_Contact__r.MailingState,
                Opportunity__r.Owner.Name, Opportunity__r.Owner.Email, Opportunity__r.Owner.Phone
            FROM Quote__c
            WHERE Id = :quoteId
        ];
    }

    public List<Quote__c> findWithItemsAndOpportunityAndContactById(final String quoteId) {
        return [
            SELECT Id, CreatedDate, Name, Primary__c, AmendmentType__c,
                CurrencyIsoCode, Opportunity__c, Zuora_Account_Id__c, Zuora_Subscription_Id__c, ZuoraCreditCardId__c,
                EffectiveDate__c, SubscriptionStartDate__c, SubscriptionEndDate__c, Number__c, QuoteType__c,
                Status__c, Pdf_Id__c, Total__c, DeltaMrr__c, BaseLicenseMrr__c, TargetInvoiceDate__c, InvoiceDate__c,
                ValidUntil__c, WrikeAccountId__c, CompanyName__c, Notes__c, ZuoraAccountName__c, ZuoraSubscriptionName__c,
                SalesName__c, SalesEmail__c, SalesPhone__c, InitialTerm__c, NewTerm__c, RenewalTerm__c,
                PaymentTerm__c, LegalTerms__c, LegalTermsEffectiveDate__c, CreditCardLink__c,
                HashCode__c, Reason_for_Approval_Request__c, Reason_for_Discount__c, LastEditDateTime__c, TaxExempt__c,
                TaxExemptCertificateId__c, DataCenter__c, OriginalQuote__c, IsOriginalQuoteApproved__c,
                LicenseDiscount__c, DeploymentDiscount__c, DeploymentName__c, BillingPeriodName__c,
                OldProductName__c, NewProductName__c, OldQuantity__c, NewQuantity__c,
                AddonQuantity__c, AdvancedFeatureAddonQuantity__c, CollaboratorBaseLicenseRate__c,
                OldPricePerUserPerMonth__c, NewPricePerUserPerMonth__c, IsTravelPaid__c, NoPSIntegrate__c, OnetimeDiscountIncluded__c,
                NumberOfTeams__c, HasCustomDeployment__c, AdditionalUsers__c, AutoRenewalRemoval__c, RenewalPriceProtection__c,
                PublicityRightsRemoval__c, CoMarketingAddition__c, GoverningLaw__c, TermsDataCenter__c,
                AgencyReliefOfferDiscount__c, PremiumSupportMismatch__c, OriginalQuote__r.Name,
                Opportunity__r.AccountId, Opportunity__r.Name, Opportunity__r.BillingCountryCode__c, Opportunity__r.VAT__c,
                Opportunity__r.VAT_Valid__c, Opportunity__r.RecordType.DeveloperName,
                Opportunity__r.Billing_Contact__r.Name,
                Opportunity__r.Billing_Contact__r.FirstName, Opportunity__r.Billing_Contact__r.LastName,
                Opportunity__r.Billing_Contact__r.Email, Opportunity__r.Billing_Contact__r.MailingStreet,
                Opportunity__r.Billing_Contact__r.MailingCity, Opportunity__r.Billing_Contact__r.MailingStateCode,
                Opportunity__r.Billing_Contact__r.MailingPostalCode, Opportunity__r.Billing_Contact__r.MailingCountryCode,
                Opportunity__r.Billing_Contact__r.MailingCountry, Opportunity__r.Billing_Contact__r.MailingState,
                Opportunity__r.Owner.Name, Opportunity__r.Owner.Email, Opportunity__r.Owner.Phone,
                Opportunity__r.Vertical_Segment__c,Opportunity__r.Competitor_Lost_To__c, Opportunity__r.Reasons_Lost__c,
            	Opportunity__r.Sub_Reason__c, Opportunity__r.Lost_Reason_Detail__c, Opportunity__r.Other_Competitors_Won_Lost_To__c, 
            	Opportunity__r.Other_Won_Lost_Reasons__c,
                (
                    SELECT Id, State__c, Product__c, Quote__c, UID__c, ParentItemUID__c,
                        Product__r.Id, Product__r.Name, Product__r.Description__c, Product__r.MRR__c,
                        Product__r.Quantity__c, Product__r.Term__c, Product__r.ChargeType__c, Product__r.ChargeModel__c, Product__r.ChargeNumber__c,
                        Product__r.BillingIntervalListPrice__c, Product__r.Price__c, Product__r.PricePerUserPerMonth__c, Product__r.PriceFormat__c,
                        Product__r.Discount__c, Product__r.DiscountReason__c, Product__r.ServiceType__c,
                        Product__r.BillingPeriodName__c, Product__r.ZuoraProductId__c, Product__r.ZuoraProductRatePlanId__c,
                        Product__r.ZuoraProductRatePlanChargeId__c, Product__r.ZuoraProductRatePlanChargeName__c,
                        Product__r.ZuoraRatePlanId__c, Product__r.ZuoraRatePlanChargeId__c, Product__r.Product__c,
                        Product__r.SoftBundleDiscountApplied__c
                    FROM Quote_Items__r
                )
            FROM Quote__c
            WHERE Id = :quoteId
        ];
    }

    public List<Quote__c> findWithStatusByIds(final List<String> quoteIds) {
        return [
            SELECT Id, Status__c, WrikeAccountId__c
            FROM Quote__c
            WHERE Id IN :quoteIds
        ];
    }

    public List<Quote__c> findById(final String quoteId) {
        return [
            SELECT Id, Primary__c, Number__c, Opportunity__c, PurchaseOrderAttachmentId__c, Pdf_Id__c, Zuora_Account_Id__c, ZuoraCreditCardId__c
            FROM Quote__c
            WHERE Id = :quoteId
        ];
    }

    public List<Quote__c> findWithStatusForUpdateById(final String quoteId) {
        return [
            SELECT Id, Status__c
            FROM Quote__c
            WHERE Id = :quoteId
            FOR UPDATE
        ];
    }
    
    public Id findQuoteOperationId(final String key) {
        final List<Quote_Operation__c> operations = [
            SELECT Id
            FROM Quote_Operation__c
            WHERE Key__c = :key
        ];
        return operations.isEmpty() ? null : operations[0].Id;
    }

    public Quote__c findSubscriptionPreviewById(final String quoteId) {
        final List<Quote__c> quotes = [
            SELECT SubscriptionPreview__c, SubscriptionPreviewInvoices__c
            FROM Quote__c
            WHERE Id = :quoteId
        ];
        return quotes.isEmpty() ? null : quotes[0];
    }

    public List<Quote__c> findWithDocuSignStatusByOpportunityId(String opportunityId, Integer recordsLimit, Integer recordsOffset) {
        return [
            SELECT Id, Name, Primary__c, InitialTerm__c, NewTerm__c, CreatedDate, ValidUntil__c, DeltaMrr__c, Status__c, Pdf_Id__c,
                (
                    SELECT Id, Name, dsfs__Envelope_Status__c
                    FROM DocuSignStatus__r
                    ORDER BY CreatedDate DESC
                )
            FROM Quote__c
            WHERE Opportunity__c = :opportunityId
            LIMIT :recordsLimit
            OFFSET :recordsOffset
        ];
    }

    public List<Quote__c> findWithDocuSignStatusByOpportunityId(final String opportunityId) {
        return [
            SELECT Id, Name, Primary__c, InitialTerm__c, NewTerm__c, CreatedDate, ValidUntil__c, DeltaMrr__c, Status__c, Pdf_Id__c,
                (
                    SELECT Id, Name, dsfs__Envelope_Status__c
                    FROM DocuSignStatus__r
                    ORDER BY CreatedDate DESC
                )
            FROM Quote__c
            WHERE Opportunity__c = :opportunityId
        ];
    }

    public List<Quote__c> findWithItemsByOpportunityIds(final Set<Id> opportunityIds) {
        return [
            SELECT Id,
                (
                    SELECT Id, Product__c
                    FROM Quote_Items__r
                )
            FROM Quote__c
            WHERE Opportunity__c IN :opportunityIds
        ];
    }

    public List<Quote__c> findByZuoraAccountIds(final List<String> zuoraAccountIds, final Set<Id> exceptQuoteIds, final List<String> exceptStatuses) {
        return [
            SELECT Id
            FROM Quote__c
            WHERE Zuora_Account_Id__c IN :zuoraAccountIds
                AND Id NOT IN :exceptQuoteIds
                AND Status__c NOT IN :exceptStatuses
        ];
    }

    public Id findOpportunityIdByQuoteId(final Id quoteId) {
        final List<Quote__c> quotes = [
            SELECT Opportunity__c
            FROM Quote__c
            WHERE Id = :quoteId
        ];
        return quotes.isEmpty() ? null : quotes[0].Opportunity__c;
    }

    public List<Quote__c> listPrimaryQuotesByOpportunityId(final Id opportunityId) {
        return [
            SELECT Id, Status__c
            FROM Quote__c
            WHERE Opportunity__c = :opportunityId
              AND Primary__c = true
        ];
    }
}
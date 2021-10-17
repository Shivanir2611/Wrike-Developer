public class ContractService {

    public static ContractService getInstance() {
        return (ContractService)ServiceLocator.getInstance(ContractService.class);
    }

    public void updateContractFromQuote(final Id contractId, final Id quoteId) {
        final SBQQ__Quote__c quote = [
                SELECT Id, QS_Bill_To__c, QS_Ship_To__c, SBQQ__BillingFrequency__c, SBQQ__PaymentTerms__c,
                       Automatic_Renewal__c, Governing_Terms__c, Governing_Law__c, Date_of_Agreement__c,
                       Tax_Exempt__c, Additional_users_price_mo__c, Additional_users_increments__c,
                       Additional_Collaborators_price_mo__c, Additional_Collaborators_increments__c,
                       Price_Protection_at_Renewal__c, Removal_of_Publicity_Logo_Rights__c,
                       Addition_of_Co_Marketing__c, DataCenter__c, Internal_Notes__c, CurrencyIsoCode,
                       Other_Governing_Law__c, CustomGoverningTerms__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
        if (quote != null) {
            update new Contract(
                    Id = contractId,
                    QS_Bill_To__c = quote.QS_Bill_To__c,
                    QS_Ship_To__c = quote.QS_Ship_To__c,
                    BillingFrequency__c = quote.SBQQ__BillingFrequency__c,
                    PaymentTerms__c = quote.SBQQ__PaymentTerms__c,
                    Auto_Renew__c = quote.Automatic_Renewal__c,
                    GoverningTerms__c = 'New MSA'.equals(quote.Governing_Terms__c)
                                        ? 'Existing MSA'
                                        : quote.Governing_Terms__c,
                    QuoteGoverningLaw__c = quote.Governing_Law__c,
                    AgreementDate__c = quote.Date_of_Agreement__c,
                    TaxExempt__c = quote.Tax_Exempt__c,
                    AdditionalUsersPrice__c = quote.Additional_users_price_mo__c,
                    AdditionalUsersIncrements__c = quote.Additional_users_increments__c,
                    AdditionalCollaboratorsPrice__c = quote.Additional_Collaborators_price_mo__c,
                    AdditionalCollaboratorsIncrements__c = quote.Additional_Collaborators_increments__c,
                    RenewalPriceProtection__c = quote.Price_Protection_at_Renewal__c,
                    PublicityLogoRightsRemoval__c = quote.Removal_of_Publicity_Logo_Rights__c,
                    CoMarketingAddition__c = quote.Addition_of_Co_Marketing__c,
                    DataCenter__c = quote.DataCenter__c,
                    InternalNotes__c = quote.Internal_Notes__c,
                    CurrencyIsoCode = quote.CurrencyIsoCode,
                    OtherGoverningLaw__c = quote.Other_Governing_Law__c,
                    CustomGoverningTerms__c = quote.CustomGoverningTerms__c
            );
        }
    }
}
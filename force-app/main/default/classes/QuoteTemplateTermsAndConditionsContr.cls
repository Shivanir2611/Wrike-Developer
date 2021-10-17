public class QuoteTemplateTermsAndConditionsContr {

    public Id quoteId;
    public CPQQuote quote {get; set;}
    public Boolean quoteTotalIsNegative {get; set;}
    public Boolean needRenderSection {get; set;}
    public Boolean hasReseller {get; set;}

    public boolean cbAdditionOfCoMarketing {get;set;}
    public boolean cbAdditionalUsersAtSameRate {get;set;}
    public boolean cbPriceProtectionatRenewal {get;set;}
    public boolean cbRemovalofPublicityLogoRights {get;set;}
    public boolean cbRemovalofAutomaticRenewal {get;set;}
    public boolean cbGoverningTerms {get;set;}
    public boolean cbDataCenter {get;set;}
    public string priceProtectionAtRenewal {get;set;}
    public string governingLaw {get;set;}
    public string coMarketing {get;set;}
    public string governingTerms{get;set;}
    public string customGoverningTerms{get;set;}
    public boolean isGoverningTermsExist{get;set;}
    public string dateOfAgreement{get;set;}
    public boolean cbAdditionOfProfessionalServices{get;set;}
    public boolean productFamilyDeployment{get;set;}
    public boolean productFamilyAddOn{get;set;}
    public boolean productFamilyIntegrate{get;set;}
    public string otherTerms {get;set;}
    public boolean DisplayAdditionalUsersPricePerMonth {get;set;}
    public boolean DisplayAdditionalCollabPricePerMonth {get;set;}
    public string additionalUsersIncrements {get;set;}
    public decimal additionalUsersPrice {get;set;}
    public string additionalCollabIncrements {get;set;}
    public decimal additionalCollabPrice {get;set;}
    public string quoteCurrency {get;set;}
    public Boolean purchasingByPO {get;set;}
    public String partnerAgreementType {get; set;}
    
    Public QuoteTemplateTermsAndConditionsContr(){
        quoteId = (Id)ApexPages.currentPage().getParameters().get(Constants.QID);
        this.quoteTotalIsNegative = false;
        this.needRenderSection = false;
        priceProtectionAtRenewal='';
        governingLaw = '';
        cbAdditionOfCoMarketing = false;
        cbAdditionalUsersAtSameRate = false;
        cbPriceProtectionatRenewal = false;
        cbRemovalofPublicityLogoRights = false;
        cbRemovalofAutomaticRenewal = false;
        cbGoverningTerms = false;
        cbDataCenter = false;
        dateOfAgreement = '';
        cbAdditionOfProfessionalServices = false;
        productFamilyDeployment = false;
        productFamilyAddOn = false;
        productFamilyIntegrate = false;
        otherTerms = '';
        DisplayAdditionalUsersPricePerMonth = false;
        DisplayAdditionalCollabPricePerMonth = false;
        additionalUsersIncrements = '';
        additionalUsersPrice = 0;
        additionalCollabIncrements = '';
        additionalCollabPrice = 0;
        quoteCurrency = 'USD';
        this.purchasingByPO = false;
        this.hasReseller = false;
        this.partnerAgreementType = null;
    }
    public void getTermsAndConditions(){
        this.quote = CPQQuoteService.getInstance().findQuoteById(quoteId);
        this.quoteTotalIsNegative = ((quote.subscriptionTotal != null ? quote.subscriptionTotal : 0)
        + (quote.oneTimeTotal != null ? quote.oneTimeTotal : 0)) < 0;
        this.hasReseller = quote.resellerAccountId != null;
        List<SBQQ__Quote__c> quoteList = [
                SELECT Id, CurrencyIsoCode, Price_Protection_at_Renewal__c, Governing_Law__c, CB_Addition_of_Co_Marketing__c,
                       CB_Price_Protection_at_Renewal__c, CB_Removal_of_Publicity_Logo_Rights__c,
                       CB_Removal_of_Automatic_Renewal__c, CB_Governing_Law__c, CB_Data_Center__c, Governing_Terms__c,
                       Date_of_Agreement__c, Other_Terms__c, Additional_users_price_mo__c,
                       Additional_Collaborators_price_mo__c, Additional_users_increments__c,
                       Additional_Collaborators_increments__c, PurchasingByPO__c, CustomGoverningTerms__c, Other_Governing_Law__c,
                       PartnerAgreementType__c
                FROM SBQQ__Quote__c
                WHERE id =: quoteId
        ];
        List<SBQQ__QuoteLine__c> quoteLineList = [Select id, SBQQ__ProductFamily__c, SBQQ__Product__r.Product_Grouping__c, SBQQ__Product__r.DeploymentExhibit__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: quoteList[0].Id];
        for(SBQQ__Quote__c quote : quoteList){
            Boolean professionalServicesCheck = false;
            for(SBQQ__QuoteLine__c quoteline : quoteLineList){
                if(quoteline.SBQQ__Product__r.Product_Grouping__c == 'Services'){
                    if(quoteline.SBQQ__Product__r.DeploymentExhibit__c == 'B'){
                        productFamilyDeployment = true;
                    }
                    if(quoteline.SBQQ__Product__r.DeploymentExhibit__c == 'D'){
                        productFamilyAddOn = true;
                    }
                    if(quoteline.SBQQ__Product__r.DeploymentExhibit__c == 'C'){
                        productFamilyIntegrate = true;
                    }
                    professionalServicesCheck = true;
                }
            }
            if(quote.Price_Protection_at_Renewal__c != null && quote.Price_Protection_at_Renewal__c != ''){
                priceProtectionAtRenewal = quote.Price_Protection_at_Renewal__c;
            }
            if (!String.isBlank(quote.Governing_Law__c)){
                governingLaw = 'Other'.equals(quote.Governing_Law__c) ? quote.Other_Governing_Law__c : quote.Governing_Law__c;
            }
            this.partnerAgreementType = quote.PartnerAgreementType__c;
            if(quote.Governing_Terms__c != null){
                governingTerms = quote.Governing_Terms__c;
                customGoverningTerms = quote.CustomGoverningTerms__c == null
                                       ? null
                                       : quote.CustomGoverningTerms__c.replaceAll('&', '&amp;');
                isGoverningTermsExist = true;
                if(quote.Date_of_Agreement__c != null){
                    dateOfAgreement = returnMonthName(quote.Date_of_Agreement__c.month())+' '+quote.Date_of_Agreement__c.day()+', '+quote.Date_of_Agreement__c.year();
                    //dateOfAgreement = string.valueOf(quote.Date_of_Agreement__c);
                }
            }
            if(string.isnotblank(quote.Other_Terms__c) && quote.Other_Terms__c != ''){                             
                otherTerms = quote.Other_Terms__c;
            }
            if(quote.Additional_users_price_mo__c != null){
                DisplayAdditionalUsersPricePerMonth = true;
                if(string.isnotblank(quote.Additional_users_increments__c) && quote.Additional_users_increments__c != ''){
                    additionalUsersIncrements = quote.Additional_users_increments__c;
                }
                additionalUsersPrice = quote.Additional_users_price_mo__c;
            }
            if(quote.Additional_Collaborators_price_mo__c != null){
                DisplayAdditionalCollabPricePerMonth = true;
                if(string.isnotblank(quote.Additional_Collaborators_increments__c) && quote.Additional_Collaborators_increments__c != ''){
                    additionalCollabIncrements = quote.Additional_Collaborators_increments__c;
                }
                additionalCollabPrice = quote.Additional_Collaborators_price_mo__c;
            }
            quoteCurrency = quote.CurrencyIsoCode;
            cbAdditionOfCoMarketing = quote.CB_Addition_of_Co_Marketing__c;
            cbPriceProtectionatRenewal = quote.CB_Price_Protection_at_Renewal__c;
            cbRemovalofPublicityLogoRights = quote.CB_Removal_of_Publicity_Logo_Rights__c;
            cbRemovalofAutomaticRenewal = quote.CB_Removal_of_Automatic_Renewal__c;
            cbGoverningTerms = quote.CB_Governing_Law__c;
            cbDataCenter = quote.CB_Data_Center__c;
            cbAdditionOfProfessionalServices = professionalServicesCheck;
            this.purchasingByPO = quote.PurchasingByPO__c;
            this.needRenderSection = (cbAdditionOfCoMarketing
                    || cbAdditionalUsersAtSameRate
                    || cbPriceProtectionatRenewal
                    || cbRemovalofPublicityLogoRights
                    || cbRemovalofAutomaticRenewal
                    || cbGoverningTerms
                    || cbDataCenter
                    || isGoverningTermsExist
                    || purchasingByPO
                    || cbAdditionOfProfessionalServices)
                    && (!quoteTotalIsNegative
                            || String.isNotBlank(otherTerms));
        }
    }
    public static string returnMonthName(Integer month) {
        String monthName = '';
        if (month == 1) {
            monthName = 'January';
        } else if (month == 2) {
            monthName = 'February';
        } else if (month == 3) {
            monthName = 'March';
        } else if (month == 4) {
            monthName = 'April';
        } else if (month == 5) {
            monthName = 'May';
        } else if (month == 6) {
            monthName = 'June';
        } else if (month == 7) {
            monthName = 'July';
        } else if (month == 8) {
            monthName = 'August';
        } else if (month == 9) {
            monthName = 'September';
        } else if (month == 10) {
            monthName = 'October';
        } else if (month == 11) {
            monthName = 'November';
        } else if (month == 12) {
            monthName = 'December';
        }
        return monthName;
    }
}
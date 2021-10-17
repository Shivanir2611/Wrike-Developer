public class CPQQuoteTemplateHeaderController {

    public SBQQ__Quote__c quote {get; set;}
    public SBQQ__QuoteTemplate__c template {get; set;}
    public Boolean hasReseller {get; set;}
    public String logoBase64 {get; set;}
    public String salesRepEmail {get; set;}

    public CPQQuoteTemplateHeaderController() {
        final Id quoteId = (Id)ApexPages.currentPage().getParameters().get('qid');
        this.quote = [
                SELECT Id, Name, ResellerAccount__c, PO_Number__c, SBQQ__SalesRep__r.Email,
                       WrikeAccountId__c, CurrencyIsoCode, SBQQ__PaymentTerms__c, SBQQ__BillingFrequency__c,
                       SBQQ__ExpirationDate__c, SBQQ__StartDate__c,

                       QS_Bill_To__r.Id, QS_Bill_To__r.QS_Company_Name__c,
                       QS_Bill_To__r.QS_Attention_To__c, QS_Bill_To__r.QS_Email__c, QS_Bill_To__r.QS_Street_1__c,
                       QS_Bill_To__r.QS_Street_2__c, QS_Bill_To__r.QS_State_Code__c,
                       QS_Bill_To__r.QS_City__c, QS_Bill_To__r.RegionState__c,
                       QS_Bill_To__r.QS_Country__c, QS_Bill_To__r.QS_Zip_Postal_Code__c,
                       QS_Bill_To__r.VATNumber__c,

                       QS_Ship_To__r.Id, QS_Ship_To__r.QS_Company_Name__c,
                       QS_Ship_To__r.QS_Attention_To__c, QS_Ship_To__r.QS_Email__c, QS_Ship_To__r.QS_Street_1__c,
                       QS_Ship_To__r.QS_Street_2__c, QS_Ship_To__r.QS_State_Code__c,
                       QS_Ship_To__r.QS_City__c, QS_Ship_To__r.RegionState__c,
                       QS_Ship_To__r.QS_Country__c, QS_Ship_To__r.QS_Zip_Postal_Code__c,
                       QS_Ship_To__r.VATNumber__c,

                       EndCustomer__r.Id, EndCustomer__r.QS_Company_Name__c,
                       EndCustomer__r.QS_Attention_To__c, EndCustomer__r.QS_Email__c, EndCustomer__r.QS_Street_1__c,
                       EndCustomer__r.QS_Street_2__c, EndCustomer__r.QS_State_Code__c,
                       EndCustomer__r.QS_City__c, EndCustomer__r.RegionState__c,
                       EndCustomer__r.QS_Country__c, EndCustomer__r.QS_Zip_Postal_Code__c,
                       EndCustomer__r.VATNumber__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
        this.template = [
                SELECT Id, SBQQ__CompanyName__c, SBQQ__CompanyStreet__c, SBQQ__CompanyCity__c, SBQQ__CompanyState__c,
                       SBQQ__CompanyPostalCode__c, SBQQ__CompanyCountry__c, SBQQ__LogoDocumentId__c
                FROM SBQQ__QuoteTemplate__c
                WHERE Id = :CPQSettings__c.getOrgDefaults().QuoteDocumentTemplateId__c
        ];
        final StaticResource logoStaticResource = [
                SELECT Id, Body
                FROM StaticResource
                WHERE Name = 'quoteWrikeLogo'
        ];
        this.logoBase64 = EncodingUtil.base64Encode(logoStaticResource.Body);
        this.hasReseller = quote.ResellerAccount__c != null;
        this.salesRepEmail = 'salesforce.integration@team.wrike.com'.equalsIgnoreCase(quote.SBQQ__SalesRep__r.Email)
                             ? 'ar@team.wrike.com'
                             : quote.SBQQ__SalesRep__r.Email;
    }

    public Boolean getEndCustomerNewLine() {
        return quote.QS_Bill_To__r.QS_Email__c.length() > 27
                || quote.QS_Ship_To__r.QS_Email__c.length() > 27
                || quote.EndCustomer__r != null
                        && quote.EndCustomer__r.QS_Email__c != null
                        && quote.EndCustomer__r.QS_Email__c.length() > 27;
    }
}
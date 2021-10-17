public class CPQQuoteTemplateSignatureController {

    public SBQQ__Quote__c quote {get; set;}

    public CPQQuoteTemplateSignatureController() {
        final Id quoteId = (Id)ApexPages.currentPage().getParameters().get('qid');
        this.quote = [
                SELECT Id, ResellerAccount__c, PreSignDocument__c, AdditionalSignatures__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
    }

    public String getWrikeSignatureBase64() {
        final List<StaticResource> signatureStaticResources = [
                SELECT Id, Body
                FROM StaticResource
                WHERE Id = :CPQSettings__c.getOrgDefaults().WrikeSignatureStaticResourceId__c
        ];
        if (signatureStaticResources.isEmpty()) {
            throw new LogicException('Wrike signature Static Resource is not found.');
        }
        return EncodingUtil.base64Encode(signatureStaticResources.get(0).Body);
    }

    public String getWrikeSignerName() {
        return CPQSettings__c.getOrgDefaults().WrikeSignerName__c;
    }

    public String getWrikeSignFormattedDate() {
        return DateUtils.format(DateUtils.getPacificLocalDate());
    }

    public Boolean getPreSigned() {
        return quote.PreSignDocument__c;
    }

    public Boolean getHasReseller() {
        return quote.ResellerAccount__c != null;
    }

    public Integer getAdditionalCustomerSignatures() {
        return quote.AdditionalSignatures__c == null
               ? 0
               : Integer.valueOf(quote.AdditionalSignatures__c);
    }

    public String getWrikeSignerNumber() {
        return String.valueOf(getAdditionalCustomerSignatures() + 2);
    }

    public List<Integer> getAdditionalSignatureNumbers() {
        final List<Integer> additionalSignatureNumbers = new List<Integer>();
        for (Integer i = 1; i <= getAdditionalCustomerSignatures(); i++) {
            additionalSignatureNumbers.add(i + 1);
        }
        return additionalSignatureNumbers;
    }
}
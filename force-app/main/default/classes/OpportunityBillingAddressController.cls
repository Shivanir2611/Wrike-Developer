public class OpportunityBillingAddressController {

    public Boolean isVatRequired {get; set;}
    private Opportunity opportunity;
    private List<SelectOption> countries;
    private List<SelectOption> states;
    private BillingInfo billingAddress = new BillingInfo();
    private AddressService addressSrv;
    private static Map<String, List<SelectOption>> statesMap = new Map<String, List<SelectOption>> {
        'US' => CountryUtil.getUsStates(),
        'CA' => CountryUtil.getCanadaStates()
    };
    
    public OpportunityBillingAddressController(final ApexPages.StandardController standardController) {
        this.opportunity = [SELECT Id, Vat__c, Account.Id, Account.BillingCountryCode, Account.BillingStateCode,
                    Account.BillingCity, Account.BillingStreet, Account.BillingPostalCode, Billing_Contact__c
             FROM Opportunity 
             WHERE Id = :StandardController.getRecord().Id
        ];
        if(this.opportunity.Billing_Contact__c != null) {
            final Contact contact = ContactQueryService.getInstance().findContactWithAddressById(this.opportunity.Billing_Contact__c);
            if(contact != null) {
                billingAddress = OpportunityBillingContactService.getInstance().getUpdatedBillingAddress(contact, billingAddress, this.opportunity);
            }
        }
        billingAddress.vatNumber = this.opportunity.VAT__c;
        this.countries = CountryUtil.getIsoCountries();
        this.addressSrv = AddressService.getInstance();
        if (String.isNotBlank(billingAddress.country)) {
            checkVatCountry();
        }
    }
    
    public BillingInfo getBillingAddress() {
        return this.billingAddress;
    }
    
    public List<SelectOption> getCountries() {
        return countries;
    }
    
    public List<SelectOption> getStates() {
        final List<SelectOption> countryStates = statesMap.get(this.billingAddress.country);
        return countryStates != null ? countryStates : new List<SelectOption> (); 
    }
    
    public Boolean getPopulated() {
        return billingAddress.getPopulated();
    }
    
    public PageReference back() {
        return new PageReference('/' + this.opportunity.Id);
    }
    
    public PageReference save() {
        Opportunity opportunity2Update = new Opportunity(Id = this.opportunity.Id);
        opportunity2Update.VAT__c = this.billingAddress.vatNumber;
        if (String.isNotBlank(this.billingAddress.vatNumber)) {
            VatNumberDto vatNumberDto = addressSrv.checkVatNumber(this.billingAddress.country, this.billingAddress.vatNumber);
            if (vatNumberDto.isValid) {
                if (vatNumberDto.isValidationServiceAvalible) {
                    opportunity2Update.VAT_Valid__c = AddressService.VAT_VALID;
                } else {
                    opportunity2Update.VAT_Valid__c = AddressService.VAT_INVALID;
                }
            } else {
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.WARNING, 'Entered VAT number doesn\'t correspond with a billing country. ' +
                    'Please double check billing country and ensure the country is correct.'));
                return null;
            }
        }
        OpportunityBillingContactService.getInstance().updateOpportunityBillingContact(this.billingAddress, this.opportunity, this.opportunity.AccountId);
        return new PageReference('/' + this.opportunity.Id);
    }

    public void checkVatCountry() {
        this.isVatRequired = addressSrv.isVatNumberRequired(this.billingAddress.country);
    }
}
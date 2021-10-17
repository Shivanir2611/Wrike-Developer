public class OpportunityVatNumberController {

    public Boolean isVatRequired {get; set;}
    public BillingInfo billingAddress {get; private set;}
    public Contact contact {get; private set;}

    private List<SelectOption> countries;
    private Opportunity opportunity;
    private ApexPages.StandardController standardController;

    private AddressService addressSrv;
    private DatabaseService databaseSrv;
    private OpportunityQueryService opportunityQueries;
    private static final Logger log = Logger.create(OpportunityVatNumberController.class);

    public OpportunityVatNumberController(ApexPages.StandardController standardController) {
        this.addressSrv = AddressService.getInstance();
        this.databaseSrv = DatabaseService.getInstance();
        this.opportunityQueries = OpportunityQueryService.getInstance();

        this.standardController = standardController;
        this.countries = CountryUtil.getIsoCountries();

        String opportunityId = standardController.getId();
        List<Opportunity> opportunities = opportunityQueries.findWithContactsById(opportunityId);
        if (!opportunities.isEmpty()) {
            this.opportunity = opportunities[0];
        } else {
            ApexPageMessageUtils.addError('Opportunity with id = ' + opportunityId + ' do not exist.');
            return;
        }

        this.billingAddress = new BillingInfo();
        if (this.opportunity.Billing_Contact__c != null) {
            this.contact = this.opportunity.Billing_Contact__r;
            this.billingAddress.country = this.contact.MailingCountryCode;
            this.billingAddress.countryFullName = this.contact.MailingCountry;
            this.billingAddress.state = this.contact.MailingStateCode;
            this.billingAddress.city = this.contact.MailingCity;
            this.billingAddress.address1 = this.contact.MailingStreet;
            this.billingAddress.zip = this.contact.MailingPostalCode;
        } else {
            this.billingAddress.country = this.opportunity.BillingCountryCode__c;
            this.billingAddress.countryFullName = CountryUtil.findCountryCodeByValue(this.billingAddress.country);
        }
        this.billingAddress.vatNumber = this.opportunity.VAT__c;

        if (String.isNotBlank(this.billingAddress.country)) {
            checkVatCountry();
        }
    }

    public List<SelectOption> getCountries() {
        return countries;
    }

    public PageReference cancel() {
        return standardController.view();
    }

    public PageReference goToBillingAddressForm() {
        PageReference billingAddressPage = Page.OpportunityBillingAddress;
        billingAddressPage.getParameters().put('id', opportunity.Id);
        return billingAddressPage;
    }

    public void checkVatCountry() {
        this.isVatRequired = addressSrv.isVatNumberRequired(this.billingAddress.country);
        if (!this.isVatRequired) {
            ApexPageMessageUtils.addWarn('VAT number is not required for selected country.');
        }
    }

    public PageReference submit() {
        VatNumberDto vatNumberDto = addressSrv.checkVatNumber(this.billingAddress.country, this.billingAddress.vatNumber);
        if (vatNumberDto == null) {
            ApexPageMessageUtils.addError('Country or VAT number is empty.');
            return null;
        }

        if (vatNumberDto.isValid) {
            this.opportunity.VAT__c = this.billingAddress.vatNumber;
            this.opportunity.BillingCountryCode__c = this.billingAddress.country;
            this.opportunity.VAT_Info__c = (vatNumberDto.name + ' ' + vatNumberDto.address).left(255);
            if (vatNumberDto.isValidationServiceAvalible) {
                this.opportunity.VAT_Valid__c = AddressService.VAT_VALID;
            } else {
                this.opportunity.VAT_Valid__c = AddressService.VAT_INVALID;
            }
        } else {
            ApexPageMessageUtils.addWarn('Entered VAT number doesn\'t correspond with a billing country. ' +
                'Please double check billing country and ensure the country is correct.');
            return null;
        }

        Boolean updateResult = databaseSrv.updateSObject(opportunity);
        if (updateResult) {
            return standardController.view();
        } else {
            ApexPageMessageUtils.addError('Something went wrong during update the record.');
            return null;
        }
    }
}
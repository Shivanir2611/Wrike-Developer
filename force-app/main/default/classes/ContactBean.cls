public class ContactBean {

    public String firstname {get; set;}
    public String lastname {get; set;}
    public String email {get; set;}
    public String mailingStreet {get; set;}
    public String mailingCity {get; set;}
    public String mailingState {get; set;}
    public String mailingStateCode {get; set;}
    public String mailingCountryCode {get; set;}
    public String mailingCountry {get; set;}
    public String mailingPostalCode {get; set;}


    public BillingInfo getBillingInfo() {
        final BillingInfo billingInfo = new BillingInfo();
        billingInfo.firstName = this.firstName;
        billingInfo.lastName = this.lastName;
        billingInfo.email = this.email;
        billingInfo.country = this.mailingCountryCode;
        billingInfo.countryFullName = this.mailingCountry;
        billingInfo.state = this.mailingStateCode;
        billingInfo.stateFullName = this.mailingState;
        billingInfo.city = this.mailingCity;
        billingInfo.address1 = this.mailingStreet;
        billingInfo.zip = this.mailingPostalCode;
        return billingInfo;
    }
}
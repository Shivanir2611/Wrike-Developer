public class BillingInfo {
    public String id {get; set;}
    public String firstName {get; set;}
    public String lastName {get; set;}
    public String email {get; set {email = (value != null ? value.trim() : value);}}
    public String country {get; set;}
    public String countryFullName {get; set;}
    public String state {get; set;}
    public String stateFullName {get; set;}
    public String city {get; set;}
    public String address1 {get; set;}
    public String address2 {get; set;}
    public String zip {get; set;}
    public String contactId {get; set;}
    public String cardNumber {get; set;}
    public Integer cardExpirationMonth {get; set;}
    public Integer cardExpirationYear {get; set;}
    public String cardHolderName {get; set;}
    public String vatNumber {get; set;}
    public Boolean taxExempt {get; set;}
    public String taxExemptCertificateId {get; set;}
    public Boolean defaultPaymentMethod {get; set;}

    public BillingInfo() {
        this.defaultPaymentMethod = false;
    }

    public Boolean getPopulated() {
        return String.isNotBlank(this.firstName) && 
               String.isNotBlank(this.lastName) && 
               String.isNotBlank(this.country) && 
               (!new Set<String> {'US', 'CA'}.contains(this.country) || String.isNotBlank(this.state)) && 
               String.isNotBlank(this.city) &&
               String.isNotBlank(this.address1) &&
               String.isNotBlank(this.zip) 
               && EmailUtil.isValidEmail(this.email);
    }
}
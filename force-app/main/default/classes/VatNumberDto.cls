public class VatNumberDto {

    public Boolean isValidationServiceAvalible {get; set;}
    public Boolean isValid {get; set;}
    public String countryCode {get; set;}
    public String vatNumber {get; set;}
    public Date requestDate {get; set;}
    public String name {get; set;}
    public String address {get; set;}

    public VatNumberDto(Boolean isValidationServiceAvaloble) {
        this.isValidationServiceAvalible = isValidationServiceAvaloble;
    }

    public VatNumberDto(Boolean isValidationServiceAvaloble, Boolean isValid) {
        this.isValidationServiceAvalible = isValidationServiceAvaloble;
        this.isValid = isValid;
    }
}
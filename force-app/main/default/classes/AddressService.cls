public with sharing class AddressService {

    public static AddressService getInstance() {
        return (AddressService)ServiceLocator.getInstance(AddressService.class);
    }

    public static final String VAT_VALID = 'Valid';
    public static final String VAT_INVALID = 'Invalid';

    private static final Set<String> VAT_COUNTRIES = new Set<String> {'AT','BE','BG','CY','CZ','DE','DK','EE','EL','ES',
        'FI','FR','GB', 'GR','HR','HU','IE','IT','LT','LU','LV','MT','NL','PL','PT','RO','SE','SI','SK'};

    public Boolean isVatNumberRequired(String countryCode) {
        return VAT_COUNTRIES.contains(countryCode);
    }

    public VatNumberDto checkVatNumber(String countryCode, String vatNumber) {
        if (String.isBlank(countryCode) || String.isBlank(vatNumber)) {
            return null;
        }
        try {
            CheckVat.checkVatPort checkVatWsdlPort = new CheckVat.checkVatPort();
            checkVatWsdlPort.timeout_x = 60000;
            final CheckVatTypes.checkVatResponse_element response = checkVatWsdlPort.checkVat(countryCode, vatNumber);
            VatNumberDto vatNumberDto = new VatNumberDto(true);
            vatNumberDto.isValid = response.valid;
            vatNumberDto.countryCode = response.countryCode;
            vatNumberDto.vatNumber = response.vatNumber;
            vatNumberDto.requestDate = response.requestDate;
            vatNumberDto.name = response.name;
            vatNumberDto.address = response.address;
            return vatNumberDto;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            VatNumberDto vatNumberDto = new VatNumberDto(false, true);
            return vatNumberDto;
        }
    }
}
public class CountryDataQueryService {

    public static CountryDataQueryService getInstance() {
        return (CountryDataQueryService)ServiceLocator.getInstance(CountryDataQueryService.class);
    }

    public List<CountryData__c> listCountryDataByCoutryCode(final List<String> countryCodes) {
        return [
            SELECT Id, CountryCode__c
            FROM CountryData__c
            WHERE CountryCode__c IN :countryCodes
        ];
    }
}
public class LeadService {

    public static final String RECYCLE_STATUS = 'Unqualified';
    public static final String EMPTY_COUNTRY_CODE = '--';

    private static final Logger log = Logger.create(LeadService.class);

    private LeadQueryService leadQuerySrv = LeadQueryService.getInstance();
    private CountryDataQueryService countryDataQuerySrv = CountryDataQueryService.getInstance();

    public static LeadService getInstance() {
        return (LeadService)ServiceLocator.getInstance(LeadService.class);
    }

    public void setCountryData(final List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }
        final List<String> countryCodes = SobjectUtils.extractNotNullByFieldName(leads, 'CountryCode');
        countryCodes.add(EMPTY_COUNTRY_CODE);
        final List<CountryData__c> countryDataList = countryDataQuerySrv.listCountryDataByCoutryCode(countryCodes);
        final Map<String, String> countryCodeToDataId = SobjectUtils.createMapBetweenTwoField(countryDataList, 'CountryCode__c', 'Id');
        final String emptyCountryCodeData = countryCodeToDataId.get(EMPTY_COUNTRY_CODE);
        for (Lead lead : leads) {
            lead.CountryCode__c = lead.CountryCode;
            final String countryDataId = countryCodeToDataId.get(lead.CountryCode);
            if (countryDataId != null) {
                lead.CountryData__c = countryDataId;
            } else {
                lead.CountryData__c = emptyCountryCodeData;
            }
        }
    }
}
public class CountryUtil {
    private static final List<SelectOption> countries = new List<SelectOption>();
    private static final Map<String, String> countryCodeMap = new Map<String, String>();
    private static final Map<String, String> countryNameMap = new Map<String, String>();
    private static final Map<String, String> canadaStateMap = new Map<String, String> {
        'AB' => 'Alberta',
        'BC' => 'British Columbia',
        'MB' => 'Manitoba',
        'NB' => 'New Brunswick',
        'NL' => 'Newfoundland and Labrador',
        'NS' => 'Nova Scotia',
        'NT' => 'Northwest Territories',
        'NU' => 'Nunavut',
        'ON' => 'Ontario',
        'PE' => 'Prince Edward Island',
        'QC' => 'Quebec',
        'SK' => 'Saskatchewan',
        'YT' => 'Yukon'
    };
    private static final Map<String, String> usStateMap = new Map<String, String> {
            'AL' => 'Alabama',
            'AK' => 'Alaska',
            'AS' => 'American Samoa',
            'AZ' => 'Arizona',
            'AR' => 'Arkansas',
            'CA' => 'California',
            'CO' => 'Colorado',
            'CT' => 'Connecticut',
            'DE' => 'Delaware',
            'DC' => 'District of Columbia',
            'FL' => 'Florida',
            'GA' => 'Georgia',
            'GU' => 'Guam',
            'HI' => 'Hawaii',
            'ID' => 'Idaho',
            'IL' => 'Illinois',
            'IN' => 'Indiana',
            'IA' => 'Iowa',
            'KS' => 'Kansas',
            'KY' => 'Kentucky',
            'LA' => 'Louisiana',
            'ME' => 'Maine',
            'MD' => 'Maryland',
            'MH' => 'Marshall Islands',
            'MA' => 'Massachusetts',
            'MI' => 'Michigan',
            'FM' => 'Micronesia',
            'MN' => 'Minnesota',
            'MS' => 'Mississippi',
            'MO' => 'Missouri',
            'MT' => 'Montana',
            'NE' => 'Nebraska',
            'NV' => 'Nevada',
            'NH' => 'New Hampshire',
            'NJ' => 'New Jersey',
            'NM' => 'New Mexico',
            'NY' => 'New York',
            'NC' => 'North Carolina',
            'ND' => 'North Dakota',
            'MP' => 'Northern Marianas',
            'OH' => 'Ohio',
            'OK' => 'Oklahoma',
            'OR' => 'Oregon',
            'PW' => 'Palau',
            'PA' => 'Pennsylvania',
            'PR' => 'Puerto Rico',
            'RI' => 'Rhode Island',
            'SC' => 'South Carolina',
            'SD' => 'South Dakota',
            'TN' => 'Tennessee',
            'TX' => 'Texas',
            'UT' => 'Utah',
            'VT' => 'Vermont',
            'VA' => 'Virginia',
            'VI' => 'Virgin Islands',
            'WA' => 'Washington',
            'WV' => 'West Virginia',
            'WI' => 'Wisconsin',
            'WY' => 'Wyoming'};
    
    static {
        final List<PicklistEntry> countryValues = Lead.CountryCode.getDescribe().getPicklistValues();
        countries.add(new SelectOption('', ''));
        for (PicklistEntry country : countryValues) {
            final String countryCode = country.getValue();
            final String countryName = country.getLabel();
            countries.add(new SelectOption(countryCode, countryName));
            countryCodeMap.put(countryCode, countryName);
            countryNameMap.put(countryName.toUpperCase(), countryCode);
        }
    }
    
    public static List<SelectOption> getIsoCountries() {
        return countries;
    }
    
    public static List<SelectOption> getUsStates() {
        return getStatesOptions(usStateMap);
    }
    
    public static List<SelectOption> getCanadaStates() {
        return getStatesOptions(canadaStateMap);
    }
    
    private static List<SelectOption> getStatesOptions(final Map<String, String> stateMap) {
        final List<SelectOption> options = new List<SelectOption>();
        final List<String> stateCodes = new List<String>(stateMap.keySet());
        stateCodes.sort();
        options.add(new SelectOption('',''));
        for(String stateCode : stateCodes) {
            options.add(new SelectOption(stateCode, stateMap.get(stateCode)));
        }
        return options;
    }
    
    
    public static Map<String, String> getUsIsoStates() {
        return usStateMap;
    }
    
    public static Map<String, String> getCanadaIsoStates() {
        return canadaStateMap;
    }
    
    public static Boolean isValidCanadaUsState(final String countryCode, final String stateCode) {
        if(countryCode == 'US') {
            return usStateMap.get(stateCode) != null;
        }
        if(countryCode == 'CA') {
            return canadaStateMap.get(stateCode) != null;
        }
        return false;
    }
    
    public static String findCountryCodeByValue(final String country) {
        if(String.isBlank(country)) {
            return null;
        }
        final String value = country.trim().toUpperCase();
        if(countryCodeMap.containsKey(value)) {
            return value;
        }
        return countryNameMap.get(value);
    }
    
    public static String findStateCodeByValue(final String value) {
        if('Washington DC' == value) {
            return 'DC';
        }
        if(String.isNotBlank(value)) {
            for(String stateCode : usStateMap.keySet()) {
                if(stateCode.equalsIgnoreCase(value) || usStateMap.get(stateCode).equalsIgnoreCase(value)) {
                    return stateCode;    
                }
            }
            for(String stateCode : canadaStateMap.keySet()) {
                if(stateCode.equalsIgnoreCase(value) || canadaStateMap.get(stateCode).equalsIgnoreCase(value)) {
                    return stateCode;    
                }
            }
        }
        return null;
    }

    public static Map<String, String> getCountryCodeMap() {
        return countryCodeMap;
    }

    public static Boolean isValidCountryCode(final String value) {
        return countryCodeMap.containsKey(value);
    }
}
@IsTest
public class CountryUtilTest {

    @IsTest
    public static void testIsValidCanadaUsState() {
        System.assertEquals(true, CountryUtil.isValidCanadaUsState('US', 'CA'));
        System.assertEquals(true, CountryUtil.isValidCanadaUsState('US', 'TX'));
        System.assertEquals(true, CountryUtil.isValidCanadaUsState('US', 'NY'));
        System.assertEquals(false, CountryUtil.isValidCanadaUsState('ZZ', 'CA'));
        System.assertEquals(true, CountryUtil.isValidCanadaUsState('CA', 'YT'));
        System.assertEquals(true, CountryUtil.isValidCanadaUsState('CA', 'ON'));
        System.assertEquals(true, CountryUtil.isValidCanadaUsState('CA', 'QC'));
        System.assertEquals(false, CountryUtil.isValidCanadaUsState('CA', 'ZZ'));
    }
    
    @IsTest
    public static void testFindCountryCodeByValue() {
        System.assertEquals('US', CountryUtil.findCountryCodeByValue('United States'));
        System.assertEquals('CA', CountryUtil.findCountryCodeByValue('Canada'));
        System.assertEquals('MX', CountryUtil.findCountryCodeByValue('Mexico'));       
    }
    
    @IsTest
    public static void testFindStateCodeByValue() {
        System.assertEquals('CA', CountryUtil.findStateCodeByValue('California'));
        System.assertEquals('TX', CountryUtil.findStateCodeByValue('Texas'));
        System.assertEquals('DC', CountryUtil.findStateCodeByValue('Washington DC'));
        System.assertEquals('QC', CountryUtil.findStateCodeByValue('Quebec'));       
    }
    
    @IsTest
    public static void testGetCanadaStates() {
        final List<SelectOption> stateOptions = CountryUtil.getCanadaStates();
        System.assertEquals('AB', stateOptions.get(1).getValue());
        System.assertEquals('Alberta', stateOptions.get(1).getLabel());
    }
    
    @IsTest
    public static void testGetUsStates() {
        final List<SelectOption> stateOptions = CountryUtil.getUsStates();
        System.assertEquals('AK', stateOptions.get(1).getValue());
        System.assertEquals('Alaska', stateOptions.get(1).getLabel());
    }
}
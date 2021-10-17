public class BillingAddressComponentController {
	private List<SelectOption> countries = CountryUtil.getIsoCountries();
	private static Map<String, List<SelectOption>> statesMap = new Map<String, List<SelectOption>> {
		'US' => CountryUtil.getUsStates(),
		'CA' => CountryUtil.getCanadaStates()
	};
	public BillingInfo billingAddress {get; set;}

	public List<SelectOption> getCountries() {
		return this.countries;
	}

	public List<SelectOption> getStates() {
		final List<SelectOption> countryStates = statesMap.get(this.billingAddress.country);
		return countryStates != null ? countryStates : new List<SelectOption> ();
	}
}
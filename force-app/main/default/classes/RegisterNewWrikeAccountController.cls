/*
 * Created by andrey.kuleshov on 10/02/2019.
 */
public class RegisterNewWrikeAccountController {
	private QuoteService quoteSrv = QuoteService.getInstance();
	private ValidationResult validationResults = new ValidationResult();
	private final WrikeQuote wrikeQuote;
	public String firstName {get; set;}
	public String lastName {get; set;}
	public String email {get; set;}

	public RegisterNewWrikeAccountController() {
		final String quoteId = ApexPages.currentPage().getParameters().get(RequestParam.ID_PARAM);
		try {
			if (String.isBlank(quoteId)) {
				throw new LogicException('Quote Id parameter is not defined.');
			}
			final QuoteService.WrikeQuoteWithValidation quoteWithValidation = this.quoteSrv.findAndValidate(quoteId, true);
			this.wrikeQuote = quoteWithValidation.wQuote;
			if (String.isNotBlank(quoteWithValidation.message)) {
				throw new LogicException(quoteWithValidation.message);
			}
			if(this.wrikeQuote.contact != null) {
				this.firstName = this.wrikeQuote.contact.firstname;
				this.lastName = this.wrikeQuote.contact.lastname;
				this.email = this.wrikeQuote.contact.email;
			}
		} catch(LogicException logicExp) {
			this.validationResults.addError(logicExp.getMessage());
		}
	}

	public WrikeQuote getWrikeQuote() {
		return wrikeQuote;
	}

	public ValidationResult getValidationResults() {
		return this.validationResults;
	}

	public PageReference registerNewAccount() {
		validationResults.clear();
		if(String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email)) {
			this.validationResults.addError('Please populate all fields.');
			return null;
		} else if(!EmailUtil.isValidEmail(email)) {
			this.validationResults.addError('Please populate a valid email address.');
			return null;
		}
		try {
			final QuoteService.WrikeAccountRegistrationResult registrationResult = this.quoteSrv.registerNewWrikeAccount(
					this.wrikeQuote,
					firstName,
					lastName,
					email);
			if(registrationResult.getEmailInUse()) {
				this.validationResults.addError('The email address entered is associated to an existing Wrike User on non-US Data Center.' +
						' Provisioning of a new Wrike Account for this user will need to be performed manually' +
						' or select another email address to use as the Wrike account owner.');
				return null;
			}
			if(registrationResult.getWrikeAccountId() == null || registrationResult.getZuoraAccountId() == null) {
				this.validationResults.addError(registrationResult.getMessage());
				return null;
			}
			this.quoteSrv.setOutboundWrikeAccount(
					this.wrikeQuote.id,
					this.wrikeQuote.opportunityId,
					registrationResult.getWrikeAccountId(),
					registrationResult.getZuoraAccountId());
			final PageReference sendQuotePage = Page.SendQuote;
			sendQuotePage.getParameters().put(RequestParam.ID_PARAM, this.wrikeQuote.id);
			return sendQuotePage;
		} catch (final LogicException e) {
			this.validationResults.addError(e.getMessage());
		}
		return null;
	}

	public PageReference back() {
		final PageReference quoteViewPage = Page.ViewQuote;
		quoteViewPage.getParameters().put(RequestParam.ID_PARAM, this.wrikeQuote.Id);
		quoteViewPage.setRedirect(true);
		return quoteViewPage;
	}
}
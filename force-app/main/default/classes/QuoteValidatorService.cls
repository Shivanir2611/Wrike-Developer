public class QuoteValidatorService {

    public static QuoteValidatorService getInstance() {
        return (QuoteValidatorService)ServiceLocator.getInstance(QuoteValidatorService.class);
    }

    public QuoteValidator createValidator(final WrikeQuote wQuote) {
        return new QuoteValidatorImpl(wQuote);
    }
}
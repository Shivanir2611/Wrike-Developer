public class SubscriptionQuoteDateService extends QuoteDateService {

    public static SubscriptionQuoteDateService getInstance() {
        return (SubscriptionQuoteDateService)ServiceLocator.getInstance(SubscriptionQuoteDateService.class);
    }

    public override Date getEffectiveDate(WrikeQuote wQuote) {
        return DateUtils.getPacificLocalDate();
    }

    public override Date getMinEffectiveDate(WrikeQuote wQuote) {
        if (SettingsProvider.isSubscriptionStartDateInThePastAllowed()) {
            return null;
        }
        return DateUtils.getPacificLocalDate();
    }

    public override Date getMaxEffectiveDate(WrikeQuote wQuote) {
        return null;
    }

    public override Date getMaxValidUntil(WrikeQuote wQuote) {
        if (wQuote == null || wQuote.effectiveDate == null) {
            return null;
        }
        final Boolean effectiveDateInThePast = wQuote.effectiveDate < DateUtils.getPacificLocalDate().toStartOfMonth();
        if (effectiveDateInThePast && SettingsProvider.isSubscriptionStartDateInThePastAllowed()) {
            return DateUtils.getPacificLocalDate().toStartOfMonth().addMonths(1).addDays(-1);
        }
        return wQuote.effectiveDate.toStartOfMonth().addMonths(1).addDays(-1);
    }
}
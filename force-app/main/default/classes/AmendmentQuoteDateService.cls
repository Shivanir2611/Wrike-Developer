public class AmendmentQuoteDateService extends QuoteDateService {

    public static AmendmentQuoteDateService getInstance() {
        return (AmendmentQuoteDateService)ServiceLocator.getInstance(AmendmentQuoteDateService.class);
    }

    public override Date getEffectiveDate(final WrikeQuote wQuote) {
        if (wQuote.isBeforeRenewType()) {
            return DateUtils.getPacificLocalDate();
        } else {
            return wQuote.getEndDate();
        }
    }

    public override Date getMinEffectiveDate(final WrikeQuote wQuote) {
        if (wQuote == null || wQuote.subscriptionStartDate == null) {
            return null;
        }
        final Date firstDayOfTheCurrentMonth = DateUtils.getPacificLocalDate().toStartOfMonth();
        return wQuote.subscriptionStartDate > firstDayOfTheCurrentMonth ? wQuote.subscriptionStartDate : firstDayOfTheCurrentMonth;
    }

    public override Date getMaxEffectiveDate(final WrikeQuote wQuote) {
        if (wQuote == null) {
            return null;
        }
        return wQuote.getEndDate();
    }

    public override Date getMaxValidUntil(final WrikeQuote wQuote) {
        if (wQuote == null || wQuote.effectiveDate == null) {
            return null;
        }
        final Date lastDayOfTheEffectiveDateMonth = wQuote.effectiveDate.toStartOfMonth().addMonths(1).addDays(-1);
        return wQuote.getEndDate() < lastDayOfTheEffectiveDateMonth ? wQuote.getEndDate() : lastDayOfTheEffectiveDateMonth;
    }
}
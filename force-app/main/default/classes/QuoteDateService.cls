public abstract class QuoteDateService {

    public abstract Date getEffectiveDate(WrikeQuote wQuote);

    public Date getValidUntil(final WrikeQuote wQuote) {
        if (wQuote == null) {
            return null;
        }
        final Date maxValidUntilDate = getMaxValidUntil(wQuote);
        final Date todayAnd7Days = DateUtils.getPacificLocalDate().addDays(7);
        return maxValidUntilDate < todayAnd7Days ? maxValidUntilDate : todayAnd7Days;
    }

    public abstract Date getMinEffectiveDate(final WrikeQuote wQuote);

    public abstract Date getMaxEffectiveDate(final WrikeQuote wQuote);

    public Date getMinValidUntil() {
        return DateUtils.getPacificLocalDate();
    }

    public abstract Date getMaxValidUntil(final WrikeQuote wQuote);

    public Date getMinInvoiceDate(final Date effectiveDate) {
        if (effectiveDate == null) {
            return null;
        }
        return effectiveDate;
    }

    public Date getMaxInvoiceDate(final Date effectiveDate) {
        if (effectiveDate == null) {
            return null;
        }
        final Date lastDayOfCurrentMonth = DateUtils.getPacificLocalDate().toStartOfMonth().addMonths(1).addDays(-1);
        final Date lastDayOfEffectiveDateMonth = effectiveDate.toStartOfMonth().addMonths(1).addDays(-1);
        return lastDayOfEffectiveDateMonth > lastDayOfCurrentMonth ? lastDayOfEffectiveDateMonth : lastDayOfCurrentMonth;
    }
}
/**
 * Created by sofia.kanukova on 16/12/2019.
 */

@IsTest
public class AmendmentQuoteDateServiceTest {

    @IsTest
    static void testGetEffectiveDateBeforeRenewal() {
        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.amendmentType = WrikeQuote.AmendmentType.AMEND_BEFORE_RENEWAL;
        final Date effectiveDate = AmendmentQuoteDateService.getInstance().getEffectiveDate(wQuote);
        System.assertEquals(DateUtils.getPacificLocalDate(), effectiveDate);
    }

    @IsTest
    static void testGetEffectiveDateUponRenewal() {
        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.subscriptionEndDate = DateUtils.getPacificLocalDate().addMonths(11);
        wQuote.amendmentType = WrikeQuote.AmendmentType.AMEND_ON_RENEWAL;
        final Date effectiveDate = AmendmentQuoteDateService.getInstance().getEffectiveDate(wQuote);
        System.assertEquals(wQuote.subscriptionEndDate, effectiveDate);
    }

    @IsTest
    static void testGetMinEffectiveDateFirstDayOfMonth() {
        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.subscriptionStartDate = DateUtils.getPacificLocalDate().addMonths(-1);
        final Date minEffectiveDate = AmendmentQuoteDateService.getInstance().getMinEffectiveDate(wQuote);
        System.assertEquals(DateUtils.getPacificLocalDate().toStartOfMonth(), minEffectiveDate);
    }

    @IsTest
    static void testGetMinEffectiveDateNullSubscriptionStartDate() {
        final Date minEffectiveDate = AmendmentQuoteDateService.getInstance().getMinEffectiveDate(new WrikeQuote());
        System.assertEquals(null, minEffectiveDate);
    }

    @IsTest
    static void testGetMaxEffectiveDate() {
        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.subscriptionEndDate = DateUtils.getPacificLocalDate().addMonths(11);
        final Date maxEffectiveDate = AmendmentQuoteDateService.getInstance().getMaxEffectiveDate(wQuote);
        System.assertEquals(DateUtils.getPacificLocalDate().addMonths(11), maxEffectiveDate);
    }

    @IsTest
    static void testGetMaxValidUntilNullEffectiveDate() {
        final Date maxValidUntil = AmendmentQuoteDateService.getInstance().getMaxValidUntil(new WrikeQuote());
        System.assertEquals(null, maxValidUntil);
    }

    @IsTest
    static void testGetMaxValidUntilLastDayOfTheEffectiveDateMonth() {
        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.effectiveDate = DateUtils.getPacificLocalDate().addMonths(1);
        wQuote.subscriptionEndDate = DateUtils.getPacificLocalDate().addMonths(2);
        final Date maxValidUntil = AmendmentQuoteDateService.getInstance().getMaxValidUntil(wQuote);
        final Date lastDayOfTheEffectiveDateMonth = wQuote.effectiveDate.toStartOfMonth().addMonths(1).addDays(-1);
        System.assertEquals(lastDayOfTheEffectiveDateMonth, maxValidUntil);
    }
}
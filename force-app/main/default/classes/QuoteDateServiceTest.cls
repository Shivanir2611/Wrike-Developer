/**
 * Created by sofia.kanukova on 16/12/2019.
 */

@IsTest
public class QuoteDateServiceTest {

    @IsTest
    static void testGetValidUntil() {
        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.effectiveDate = DateUtils.getPacificLocalDate().addMonths(1);
        wQuote.subscriptionEndDate = DateUtils.getPacificLocalDate().addMonths(2);
        final Date validUntil = AmendmentQuoteDateService.getInstance().getValidUntil(wQuote);
        final Date todayAnd7Days = DateUtils.getPacificLocalDate().addDays(7);
        System.assertEquals(todayAnd7Days, validUntil);
    }

    @IsTest
    static void testGetMinValidUntil() {
        System.assertEquals(DateUtils.getPacificLocalDate(), AmendmentQuoteDateService.getInstance().getMinValidUntil());
    }

    @IsTest
    static void testGetMinInvoiceDate() {
        final Date minInvoiceDate = AmendmentQuoteDateService.getInstance().getMinInvoiceDate(DateUtils.getPacificLocalDate());
        System.assertEquals(DateUtils.getPacificLocalDate(), minInvoiceDate);
    }

    @IsTest
    static void testGetMaxInvoiceDate() {
        final Date lastDayOfEffectiveDateMonth = DateUtils.getPacificLocalDate().addMonths(1).toStartOfMonth().addMonths(1).addDays(-1);
        final Date maxInvoiceDate = AmendmentQuoteDateService.getInstance().getMaxInvoiceDate(DateUtils.getPacificLocalDate().addMonths(1));
        System.assertEquals(lastDayOfEffectiveDateMonth, maxInvoiceDate);
    }
}
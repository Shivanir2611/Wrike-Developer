/**
 * Created by sofia.kanukova on 16/12/2019.
 */

@IsTest
public class SubscriptionQuoteDateServiceTest {

    @IsTest
    static void testGetEffectiveDate() {
        final Date effectiveDate = SubscriptionQuoteDateService.getInstance().getEffectiveDate(null);
        System.assertEquals(DateUtils.getPacificLocalDate(), effectiveDate);
    }

    @IsTest
    static void testGetMinEffectiveDateSubscriptionStartDateInThePast() {
        TestDataFactory.insertSalesSettings();
        final Date minEffectiveDate = SubscriptionQuoteDateService.getInstance().getMinEffectiveDate(null);
        System.assertEquals(null, minEffectiveDate);
    }

    @IsTest
    static void testGetMinEffectiveDateSubscriptionStartDateNotInThePast() {
        final Date minEffectiveDate = SubscriptionQuoteDateService.getInstance().getMinEffectiveDate(null);
        System.assertEquals(DateUtils.getPacificLocalDate(), minEffectiveDate);
    }

    @IsTest
    static void testGetMaxValidUntilNullQuote() {
        final Date maxValidUntil = SubscriptionQuoteDateService.getInstance().getMaxValidUntil(null);
        System.assertEquals(null, maxValidUntil);
    }

    @IsTest
    static void testGetMaxValidUntilEffectiveDateInThePast() {
        TestDataFactory.insertSalesSettings();
        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.effectiveDate = DateUtils.getPacificLocalDate().addMonths(-1);
        final Date maxValidUntil = SubscriptionQuoteDateService.getInstance().getMaxValidUntil(wQuote);
        System.assertEquals(DateUtils.getPacificLocalDate().toStartOfMonth().addMonths(1).addDays(-1), maxValidUntil);
    }

    @IsTest
    static void testGetMaxValidUntilEffectiveDateNotInThePast() {
        TestDataFactory.insertSalesSettings();
        final WrikeQuote wQuote = new WrikeQuote();
        wQuote.effectiveDate = DateUtils.getPacificLocalDate();
        final Date maxValidUntil = SubscriptionQuoteDateService.getInstance().getMaxValidUntil(wQuote);
        System.assertEquals(wQuote.effectiveDate.toStartOfMonth().addMonths(1).addDays(-1), maxValidUntil);
    }
}
public class DateUtils {

    public static final String DEFAULT_FORMAT = 'MM/dd/yyyy';
    public static final String ZUORA_FORMAT = 'yyyy-MM-dd';
    public static final String DEFAULT_FORMAT_WITH_TIME = 'MM/dd/yyyy HH:mm:ss';

    public static final String PACIFIC_TIMEZONE = 'America/Los_Angeles';

    private static final Logger log = Logger.create(DateUtils.class);

    public static String format(Date dateToFormat) {
        return format(dateToFormat, DEFAULT_FORMAT);
    }

    public static String format(Date dateToFormat, String dateFormat) {
        if (dateToFormat == null) {
            return null;
        }
        Datetime datetimeToFormat = Datetime.newInstance(dateToFormat.year(), dateToFormat.month(), dateToFormat.day());
        return datetimeToFormat.format(dateFormat);
    }

    public static String format(Datetime datetimeToFormat) {
        if (datetimeToFormat == null) {
            return null;
        }
        return datetimeToFormat.format(DEFAULT_FORMAT);
    }

    public static String formatWithTime(Datetime datetimeToFormat) {
        if (datetimeToFormat == null) {
            return null;
        }
        return datetimeToFormat.format(DEFAULT_FORMAT_WITH_TIME);
    }

    public static Date parse(String dateString) {
        List<String> dateParts = dateString.split('/');
        if (dateParts.size() != 3) {
            return null;
        }
        try {
            Integer month = Integer.valueOf(dateParts[0]);
            if (month < 1 || month > 12) {
                return null;
            }
            Integer day = Integer.valueOf(dateParts[1]);
            if (day < 1 || day > 31) {
                return null;
            }
            Integer year = Integer.valueOf(dateParts[2]);
            if (year < 1) {
                return null;
            }
            return Date.newInstance(year, month, day);
        } catch (Exception exp) {
            log.error(exp.getStackTraceString(), exp.getMessage());
        }
        return null;
    }

    public static Date valueOf(String dateAsString) {
        if (dateAsString == null) {
            return null;
        }
        return Date.valueOf(dateAsString);
    }

    public static Boolean isDatesInSameMonth(Date firstDate, Date secondDate) {
        if (firstDate == null || secondDate == null) {
            return false;
        }
        return firstDate.year() == secondDate.year() && firstDate.month() == secondDate.month();
    }

    public static Date getPacificLocalDate() {
        final Datetime now = Datetime.now();
        final Timezone tz = Timezone.getTimeZone(PACIFIC_TIMEZONE);
        final Long newDateMilliseconds = now.getTime() + tz.getOffset(now);
        return Datetime.newInstance(newDateMilliseconds).dateGmt();
    }
}
public class StringUtils {

    public static String format(String pattern, Object arg0) {
        String argAsString = toFormattedString(arg0);
        return String.format(pattern, new List<String>{argAsString});
    }

    public static String format(String pattern, Object arg0, Object arg1) {
        String arg0AsString = toFormattedString(arg0);
        String arg1AsString = toFormattedString(arg1);
        return String.format(pattern, new List<String>{arg0AsString, arg1AsString});
    }

    public static String format(String pattern, Object arg0, Object arg1, Object arg2) {
        String arg0AsString = toFormattedString(arg0);
        String arg1AsString = toFormattedString(arg1);
        String arg2AsString = toFormattedString(arg2);
        return String.format(pattern, new List<String>{arg0AsString, arg1AsString, arg2AsString});
    }

    public static String format(String pattern, Object arg0, Object arg1, Object arg2, Object arg3) {
        String arg0AsString = toFormattedString(arg0);
        String arg1AsString = toFormattedString(arg1);
        String arg2AsString = toFormattedString(arg2);
        String arg3AsString = toFormattedString(arg3);
        return String.format(pattern, new List<String>{arg0AsString, arg1AsString, arg2AsString, arg3AsString});
    }

    public static String format(String pattern, Object arg0, Object arg1, Object arg2, Object arg3, Object arg4) {
        String arg0AsString = toFormattedString(arg0);
        String arg1AsString = toFormattedString(arg1);
        String arg2AsString = toFormattedString(arg2);
        String arg3AsString = toFormattedString(arg3);
        String arg4AsString = toFormattedString(arg4);
        return String.format(pattern, new List<String>{arg0AsString, arg1AsString, arg2AsString, arg3AsString, arg4AsString});
    }

    public static String format(String pattern, Object arg0, Object arg1, Object arg2, Object arg3, Object arg4, Object arg5) {
        String arg0AsString = toFormattedString(arg0);
        String arg1AsString = toFormattedString(arg1);
        String arg2AsString = toFormattedString(arg2);
        String arg3AsString = toFormattedString(arg3);
        String arg4AsString = toFormattedString(arg4);
        String arg5AsString = toFormattedString(arg5);
        return String.format(pattern, new List<String>{arg0AsString, arg1AsString, arg2AsString, arg3AsString,
            arg4AsString, arg5AsString});
    }

    public static String format(String pattern, Object arg0, Object arg1, Object arg2, Object arg3, Object arg4,
            Object arg5, Object arg6, Object arg7) {
        String arg0AsString = toFormattedString(arg0);
        String arg1AsString = toFormattedString(arg1);
        String arg2AsString = toFormattedString(arg2);
        String arg3AsString = toFormattedString(arg3);
        String arg4AsString = toFormattedString(arg4);
        String arg5AsString = toFormattedString(arg5);
        String arg6AsString = toFormattedString(arg6);
        String arg7AsString = toFormattedString(arg7);
        return String.format(pattern, new List<String>{arg0AsString, arg1AsString, arg2AsString, arg3AsString,
            arg4AsString, arg5AsString, arg6AsString, arg7AsString});
    }

    public static String getEmptyIfNull(String strToCheck) {
        if (strToCheck == null) {
            return '';
        }
        return strToCheck;
    }

    public static Boolean isIdOfType(final String idAsString, final SObjectType sObjType) {
        try {
            Id theId = Id.valueOf(idAsString);
            return sObjType == theId.getSObjectType();
        } catch (Exception exp) {
            return false;
        }
    }

    private static String toFormattedString(Object arg) {
        if (arg instanceof Date) {
            return DateUtils.format((Date)arg);
        }
        return String.valueOf(arg);
    }

    public static String generateRandomString(Integer length) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randomString = '';
        while (randomString.length() < length) {
            Integer chanIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomString += chars.substring(chanIndex, chanIndex+1);
        }
        return randomString;
    }

    public static String defaultIfBlank(final String str, final String defaultStr) {
        return String.isNotBlank(str) ? str : defaultStr;
    }
}
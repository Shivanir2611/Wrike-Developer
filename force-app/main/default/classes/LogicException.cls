public class LogicException extends Exception {

    public LogicException(String pattern, Object arg1) {
        this(StringUtils.format(pattern, arg1));
    }
}
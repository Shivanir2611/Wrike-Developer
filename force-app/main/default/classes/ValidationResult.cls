public class ValidationResult {

    private static Map<ApexPages.Severity, Integer> SEVERITY_ORDER = new Map<ApexPages.Severity, Integer> {
        ApexPages.Severity.INFO => 0,
        ApexPages.Severity.WARNING => 1,
        ApexPages.Severity.ERROR => 2,
        ApexPages.Severity.FATAL => 3
    };

    private List<String> messages = new List<String>();
    private ApexPages.Severity severity;

    public ValidationResult() {}

    public ValidationResult(String message) {
        this(message, ApexPages.Severity.ERROR);
    }

    public ValidationResult(String message, ApexPages.Severity severity) {
        addError(message);
        this.severity = severity;
    }

    public void addFatal(String message) {
        add(message, ApexPages.Severity.FATAL);
    }

    public void addError(String message) {
        add(message, ApexPages.Severity.ERROR);
    }

    public void addInfo(String message) {
        add(message, ApexPages.Severity.INFO);
    }

    public void addWarn(String message) {
        add(message, ApexPages.Severity.WARNING);
    }

    public void add(String message, ApexPages.Severity severity) {
        if (String.isNotBlank(message)) {
            this.messages.add(message);
            if (SEVERITY_ORDER.get(severity) > SEVERITY_ORDER.get(this.severity) || this.severity == null) {
                this.severity = severity;
            }
        }
    }

    public Boolean getHasFatalErrors() {
        return !this.messages.isEmpty() && this.severity == ApexPages.Severity.FATAL;
    }

    public Boolean getHasNotFatalErrors() {
        return this.messages.isEmpty()
            || !this.messages.isEmpty() && this.severity != ApexPages.Severity.FATAL;
    }

    public Boolean getIsValid() {
        return this.messages.isEmpty();
    }

    public Boolean getIsNotValid() {
        return !getIsValid();
    }

    public Boolean getHasOnlyInfo() {
        return !this.messages.isEmpty() && this.severity == ApexPages.Severity.INFO;
    }

    public Boolean getIsWarn() {
        return !this.messages.isEmpty() && this.severity == ApexPages.Severity.WARNING;
    }

    public void clear() {
        this.messages.clear();
        this.severity = null;
    }

    public String getResult() {
        return String.join(this.messages, '<br>');
    }
}
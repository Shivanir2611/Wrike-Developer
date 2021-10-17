public with sharing class ApexPageMessageUtils {

    public static void addMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new Apexpages.Message(severity, message));
    }

    public static void addError(String message) {
        addMessage(ApexPages.Severity.ERROR, message);
    }

    public static void addWarn(String message) {
        addMessage(ApexPages.Severity.WARNING, message);
    }
}
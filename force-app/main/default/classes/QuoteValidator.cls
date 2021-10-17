public interface QuoteValidator {

    List<String> getErrorMessages();

    List<String> getMissingDeploymentNames();

    Decimal getMaxDiscount();

    Decimal getAdditionalCollaboratorDiscount();

    Boolean getHasUnlimitedCollaborators();

    Boolean getHasAddedWrikeIntegrate();

    Boolean getHasWrikeIntegratePS();

    Boolean getHasCustomDeployment();

    Boolean getHasFTE();

    Boolean getHasWrikePerformancePackage();
    
    Boolean getHasOldWrikeIntegrateAddon();
    
    Decimal getSelfStartDiscount();

    Decimal getSmartStartDiscount();

    Decimal getWrikeIntegrateEnhancedDiscount();
}
public class OpportunityDataService {

    private static final DatabaseService databaseSrv = DatabaseService.getInstance();

    public static OpportunityDataService getInstance() {
        return (OpportunityDataService)ServiceLocator.getInstance(OpportunityDataService.class);
    }

    public Boolean setDeploymentPrice(final String opportunityDataId, final WrikeQuoteProduct quoteProduct) {
        if (String.isBlank(opportunityDataId) || quoteProduct == null) {
            return false;
        }
        return databaseSrv.updateSObject(new OpportunityData__c(
            Id = opportunityDataId,
            DeploymentEffectivePrice__c = quoteProduct.effectivePrice,
            DeploymentListPrice__c = quoteProduct.getListPrice()
        ));
    }

    public void createOpportunityData(final List<Opportunity> opportunities) {
        final Map<String, OpportunityData__c> opportunityIdToData = new Map<String, OpportunityData__c>();
        for (Opportunity currentOpportunity : opportunities) {
            opportunityIdToData.put(currentOpportunity.Id, new OpportunityData__c());
        }
        databaseSrv.insertSObject(opportunityIdToData.values());
        final List<Opportunity> opportunity4Update = new List<Opportunity>();
        for (Opportunity currentOpportunity : opportunities) {
            opportunity4Update.add(new Opportunity(
                Id = currentOpportunity.Id,
                OpportunityData__c = opportunityIdToData.get(currentOpportunity.Id).Id
            ));
        }
        databaseSrv.updateSObject(opportunity4Update);
    }
}
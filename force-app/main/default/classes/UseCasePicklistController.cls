public with sharing class UseCasePicklistController {
    @AuraEnabled 
    public static VBPSForm getVBPSPicklist() {
        final Set<String> verticalValuesSet = new Set<String>();
        final Map<String, Set<String>> keyToLOVMap = new Map<String, Set<String>>();
        for(Use_Case_Picklist_Mapping__mdt m : [SELECT Id, Vertical__c,Business_Area__c,
                                                       Primary_Use_Case__c,Secondary_Use_Case__c
                                                FROM Use_Case_Picklist_Mapping__mdt]) {
            verticalValuesSet.add(m.Vertical__c);
            String key1 = m.Vertical__c;
            if(!keyToLOVMap.containsKey(key1)) {
                keyToLOVMap.put(key1,new Set<String>());
            }
            keyToLOVMap.get(key1).add(m.Business_Area__c);
            String key2 = m.Vertical__c + '~' + m.Business_Area__c;
            if(!keyToLOVMap.containsKey(key2)) {
                keyToLOVMap.put(key2,new Set<String>());
            }
            keyToLOVMap.get(key2).add(m.Primary_Use_Case__c);
            String key3 = m.Vertical__c + '~' + m.Business_Area__c + '~' + m.Primary_Use_Case__c;
            if(!keyToLOVMap.containsKey(key3)) {
                keyToLOVMap.put(key3,new Set<String>());
            }
            keyToLOVMap.get(key3).add(m.Secondary_Use_Case__c);
        }
        final VBPSForm vbpsForm = new VBPSForm();
        vbpsForm.verticalValuesList = new List<String>(verticalValuesSet);
        vbpsForm.keyToLOVMap = new map<String,List<String>>();
        for(String key : keyToLOVMap.keySet()) {
            final Set<String> valueSet = keyToLOVMap.get(key);
            vbpsForm.keyToLOVMap.put(key,new List<String>(valueSet));
        }
        return vbpsForm;
    }
    
    @AuraEnabled 
    public static void saveUseCaseRecord(Id recordId, String vertical, String businessArea, String primaryUseCase, String secondaryUseCase) {
        try{
            Use_Case__c obj = new Use_Case__c(Id=recordId);
            obj.Vertical2__c = vertical;
            obj.Business_Area__c = businessArea;
            obj.Primary_Use_Case__c = primaryUseCase;
            obj.Secondary_Use_Case__c = secondaryUseCase;
            update obj;
        }catch(Exception e){
            if (e.getTypeName() == 'System.DmlException') {
                throw new AuraHandledException(e.getDmlMessage(0));
            } else {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
}
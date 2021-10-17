public class VBPSForm {
    
    @AuraEnabled
    public Map<String, List<String>> keyToLOVMap {get; set;}
    @AuraEnabled
    public List<String> verticalValuesList {get; set;}
}
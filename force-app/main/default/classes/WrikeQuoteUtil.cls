public class WrikeQuoteUtil {

    private static List<Quote_Item_Type__mdt> types = 
        [SELECT DeveloperName, Label, New_Product__c, Renewal__c, Type__c, Update_On_Renewal__c, Description__c, index__c
         FROM Quote_Item_Type__mdt 
         ORDER BY Index__c];
    
    public static Quote_Item_Type__mdt getType(final String value) {
        for(Quote_Item_Type__mdt type : types) {
            if(type.DeveloperName == value) {
                return type;
            }
        }
        return null;
    }
    
    public static List<Quote_Item_Type__mdt> getAmendmentTypes() {
        final List<Quote_Item_Type__mdt> amendmentTypes = new List<Quote_Item_Type__mdt>();
        for(Quote_Item_Type__mdt type : types) {
            if(type.Type__c == 'Amendment') {
                amendmentTypes.add(type);
            }
        }
        return amendmentTypes;
    }
}
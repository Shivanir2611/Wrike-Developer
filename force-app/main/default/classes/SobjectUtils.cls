public class SobjectUtils {

    public static List<String> extractNotNullByFieldName(SObject[] sObjectList, String fieldName) {
        List<String> values = new List<String>();
        for(SObject sObj : sObjectList) {
            String value = (String) sObj.get(fieldName);
            if(String.isNotBlank(value)) {
                values.add(value);
            }
        }
        return values;
    }

    public static Map<String, String> createMapBetweenTwoField(SObject[] sObjectList, String keyfieldName, String valuefieldName) {
        Map<String, String> fieldNamesMap = new Map<String, String>();
        for(SObject sObj : sObjectList) {
            String value = (String) sObj.get(keyfieldName);
            if(!fieldNamesMap.containsKey(value)) {
                fieldNamesMap.put(value, (String)sObj.get(valuefieldName));
            }
        }
        return fieldNamesMap;
    }

    public static Object getValueIfExist(final sObject obj,
                                         final Schema.SObjectField field) {
        if (obj == null || field == null) {
            return null;
        }
        final String fieldName = field.getDescribe().getName();
        final Map<String, Object> fieldNameToValue = obj.getPopulatedFieldsAsMap();
        if (fieldNameToValue.containsKey(fieldName)) {
            return fieldNameToValue.get(fieldName);
        }
        return null;
    }

    public static Object getValueOrDefault(final sObject obj,
                                           final Schema.SObjectField field,
                                           final Object defaultValue) {
        final Object value = getValueIfExist(obj, field);
        return value != null ? value : defaultValue;
    }

    public static Object getSobjectIfExist(sObject obj, Schema.SObjectField field) {
        if (obj == null || field == null) {
            return null;
        }
        String fieldName = field.getDescribe().getRelationshipName();
        Map<String, Object> fieldNameToValue = obj.getPopulatedFieldsAsMap();
        if (fieldNameToValue.containsKey(fieldName)) {
            return fieldNameToValue.get(fieldName);
        }
        return null;
    }

    public static Object getValueIfExist(sObject obj, Schema.SObjectField relationshipField, Schema.SObjectField field) {
        if (obj == null || field == null) {
            return null;
        }
        String relationShipName = relationshipField.getDescribe().getRelationshipName();
        Map<String, Object> fieldNameToValue = obj.getPopulatedFieldsAsMap();
        if (fieldNameToValue.containsKey(relationShipName)) {
            sObject relationShipObject = (sObject)fieldNameToValue.get(relationShipName);
            return getValueIfExist(relationShipObject, field);
        }
        return null;
    }

    public static Object getValueIfExist(sObject obj, Schema.SObjectField parentRelationshipField,
            Schema.SObjectField relationshipField, Schema.SObjectField field) {
        if (obj == null || field == null) {
            return null;
        }
        String parentRelationShipName = relationshipField.getDescribe().getRelationshipName();
        Map<String, Object> fieldNameToValue = obj.getPopulatedFieldsAsMap();
        if (fieldNameToValue.containsKey(parentRelationShipName)) {
            sObject relationShipObject = (sObject)fieldNameToValue.get(parentRelationShipName);
            return getValueIfExist(relationShipObject, relationshipField, field);
        }
        return null;
    }
}
public class SchemaUtils {

    public static Id getRecordTypeIdByName(final Schema.SObjectType sObjectType, final String recordTypeName) {
        return sObjectType.getDescribe()
                .getRecordTypeInfosByName()
                .get(recordTypeName)
                .getRecordTypeId();
    }
}
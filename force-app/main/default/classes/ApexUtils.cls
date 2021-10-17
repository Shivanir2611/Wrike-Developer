public class ApexUtils {

    public static List<SObject> getSublist(final List<SObject> originalList, final Integer sublistSize) {
        if(originalList.isEmpty() || originalList.size() <= sublistSize) {
            return originalList;
        } else {
            final List<SObject> sublist = new List<SObject>();
            for(Integer i = 0; i < sublistSize; i++) {
                sublist.add(originalList[i]);
            }
            return sublist;
        }
    }

    public static boolean isUser(final Id ownerId) {
        return (ownerId != null && ownerId.getSObjectType() == User.SObjectType);
    }

    public static List<Id> toList(final Set<Id> setToConvert) {
        return new List<Id>(setToConvert);
    }
}
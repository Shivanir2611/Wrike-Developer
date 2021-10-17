public class RecordTypeQueryService {

    public static final String OPPORTUNITY_RENEWAL = 'Renewal';
    public static final String ACCOUNT_CUSTOMER = 'Customer';
    public static final String CONTACT_CUSTOMER = 'Customer_Contact';
    public static final List<String> OpportunityRecordTypes = new List<String> {'Fast_Track', 'Enterprise', 'Deployment_Only'};
        
    public static RecordTypeQueryService getInstance() {
        return (RecordTypeQueryService)ServiceLocator.getInstance(RecordTypeQueryService.class);
    }

    public String getOpportunityRecordTypeIdByDevName(final String recTypeDevName) {
        return getSObjectRecordTypeIdByDevName(recTypeDevName, Opportunity.SObjectType);
    }

    public String getAccountRecordTypeIdByDevName(final String recTypeDevName) {
        return getSObjectRecordTypeIdByDevName(recTypeDevName, Account.SObjectType);
    }

    public String getContactRecordTypeIdByDevName(final String recTypeDevName) {
        return getSObjectRecordTypeIdByDevName(recTypeDevName, Contact.SObjectType);
    }

    private String getSObjectRecordTypeIdByDevName(final String recTypeDevName, final SObjectType sObjectType) {
        final List<RecordType> recTypes = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = :sObjectType.getDescribe().getName()
                AND DeveloperName = :recTypeDevName
        ];
        if (recTypes.isEmpty()) {
            return null;
        }
        return recTypes.get(0).Id;
    }
}
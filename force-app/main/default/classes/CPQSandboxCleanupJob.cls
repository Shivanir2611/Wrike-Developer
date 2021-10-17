public class CPQSandboxCleanupJob implements Database.Batchable<SObject>, Schedulable {

    private final Integer batchSize;
    private final Integer alertThresholdInPercent;

    public CPQSandboxCleanupJob(final Integer batchSize) {
        this.batchSize = batchSize;
        this.alertThresholdInPercent = 50;
    }

    public CPQSandboxCleanupJob(final Integer batchSize, final Integer alertThresholdInPercent) {
        this.batchSize = batchSize;
        this.alertThresholdInPercent = alertThresholdInPercent == null ? 50 : alertThresholdInPercent;
    }

    public void execute(final SchedulableContext sc) {
        Database.executeBatch(this, batchSize);
    }

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator(
                [
                        SELECT Id
                        FROM Account
                        WHERE (CreatedById = :getApiUserId()
                                AND CreatedDate < :getEcommerceRefreshTime())
                            OR (CreatedDate < :getStandardRefreshTime()
                                AND TestAccount__c = FALSE)
                        ORDER BY CreatedDate ASC
                ]
        );
    }

    public void execute(Database.BatchableContext context, List<Account> accounts) {
        System.assert(Test.isRunningTest() || OrganizationService.getInstance().isSandbox());

        final Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        deleteContracts(accountIds);

        deleteOrders(accountIds);

        deleteCPQQuotes(accountIds);

        deleteSubscriptions(accountIds);

        deleteBillToShipTo(accountIds);

        deleteWrikeDeployments(accountIds);

        deleteOpportunities(accountIds);

        deleteOppData();

        deleteWrikeSubscriptions(accountIds);

        delete accounts;

        deleteCPQRecordJobs();
    }

    public void finish(final Database.BatchableContext context) {
        System.assert(Test.isRunningTest() || OrganizationService.getInstance().isSandbox());

        final Map<String,System.OrgLimit> limitsMap = OrgLimits.getMap();
        final System.OrgLimit orgLimit = limitsMap.get('DataStorageMB');
        final String alert = orgLimit == null ? 'Org limit not found!' : getLimitAlertMessage(orgLimit.getName(), orgLimit.getValue(), orgLimit.getLimit());
        if(String.isNotBlank(alert)) {
            sendAlert(getAlertEmail(alert));
        }
    }

    @TestVisible
    private String getLimitAlertMessage(final String limitName, final Decimal currentValue, final Decimal limitValue) {
        if(currentValue >= limitValue*alertThresholdInPercent/100) {
            return StringUtils.format('{0}: {1} used out of {2}', limitName, currentValue, limitValue);
        }
        return null;
    }

    @TestVisible
    private Messaging.SingleEmailMessage getAlertEmail(final String alert) {
        final Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(getAlertsEmails());
        email.setSubject(URL.getSalesforceBaseUrl().getHost().substringBeforeLast('.my.salesforce.com') + ' is close to limits');
        final String emailBody = URL.getSalesforceBaseUrl().toExternalForm() + '/setup/org/orgstorageusage.jsp?id=' + UserInfo.getOrganizationId()
                + '\n' + alert;
        email.setPlainTextBody(emailBody);
        return email;
    }

    @TestVisible
    private void sendAlert(final Messaging.SingleEmailMessage email) {
        final Messaging.SendEmailResult[] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        System.assert(!result.isEmpty());
        System.assertEquals(true, result.get(0).isSuccess());
    }

    private String getApiUserId() {
        final String APIUserId = CPQSettings__c.getInstance().ECommerceAPIUserId__c;
        System.assertNotEquals(null, APIUserId);
        return APIUserId;
    }

    private List<String> getAlertsEmails() {
        final String emails = CPQSettings__c.getInstance().StorageAlertsEmails__c;
        System.assertNotEquals(null, emails);
        return emails.replaceAll(' ', '').split(',');
    }

    private Datetime getEcommerceRefreshTime() {
        return Datetime.now().addHours(-2);
    }

    private Datetime getStandardRefreshTime() {
        return Datetime.now().addDays(-14);
    }

    private void deleteOpportunities(final Set<Id> accountIds) {
        delete [
                SELECT Id
                FROM Opportunity
                WHERE AccountId IN :accountIds
        ];
    }

    private void deleteOppData() {
        delete [
                SELECT Id
                FROM OpportunityData__c
                WHERE CreatedDate < :getEcommerceRefreshTime()
        ];
    }

    private void deleteBillToShipTo(final Set<Id> accountIds) {
        delete [
                SELECT Id
                FROM QS_Bill_To_Ship_To__c
                WHERE QS_Account__c IN :accountIds
        ];
    }

    private void deleteCPQQuotes(final Set<Id> accountIds) {
        final List<SBQQ__Quote__c> quotes = [
                SELECT Id
                FROM SBQQ__Quote__c
                WHERE SBQQ__Account__c IN :accountIds
        ];
        final Set<Id> quoteIds = new Map<Id, SBQQ__Quote__c>(quotes).keySet();
        delete [
                SELECT Id
                FROM Billing_Schedule__c
                WHERE Quote__c IN :quoteIds
        ];
        delete quotes;
    }

    private void deleteOrders(final Set<Id> accountIds) {
        final List<Order> orders = [
                SELECT Id
                FROM Order
                WHERE AccountId IN :accountIds
        ];
        final Set<Id> orderIds = new Map<Id, Order>(orders).keySet();

        delete [
                SELECT Id
                FROM OfacCheck__c
                WHERE Id IN (SELECT OwnerCheck__c FROM Order WHERE Id IN :orderIds)
        ];
        delete [
                SELECT Id
                FROM OfacCheck__c
                WHERE Id IN (SELECT BillToCheck__c FROM Order WHERE Id IN :orderIds)
        ];
        delete [
                SELECT Id
                FROM OfacCheck__c
                WHERE Id IN (SELECT ShipToCheck__c FROM Order WHERE Id IN :orderIds)
        ];

        delete [
                SELECT Id
                FROM Line_Item_Billing_Schedule__c
                WHERE Order__c IN :orderIds
        ];

        final List<OrderItem> orderProducts = [
                SELECT Id
                FROM OrderItem
                WHERE OrderId IN :orderIds
        ];
        for(OrderItem op : orderProducts) {
            op.SBQQ__Contracted__c = false;
        }
        update orderProducts;

        for(Order o : orders) {
            o.SBQQ__Contracted__c = false;
        }
        update orders;
        for(Order o : orders) {
            o.Status = 'Draft';
        }
        update orders;

        delete orders;
    }

    private void deleteContracts(final Set<Id> accountIds) {
        delete [
                SELECT Id
                FROM Contract
                WHERE AccountId IN :accountIds
        ];
    }

    private void deleteSubscriptions(final Set<Id> accountIds) {
        delete [
                SELECT Id
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Account__c IN :accountIds
        ];
    }

    private void deleteWrikeSubscriptions(final Set<Id> accountIds) {
        delete [
                SELECT Id
                FROM Subscription__c
                WHERE Account__c IN :accountIds
        ];
    }

    private void deleteWrikeDeployments(final Set<Id> accountIds) {
        delete [
                SELECT Id
                FROM Deployment__c
                WHERE Account__c IN :accountIds
        ];
    }

    private void deleteCPQRecordJobs() {
        delete [
                SELECT Id
                FROM SBQQ__RecordJob__c
                WHERE (CreatedById = :getApiUserId()
                        AND CreatedDate < :getEcommerceRefreshTime())
                    OR CreatedDate < :getStandardRefreshTime()
        ];
    }
}
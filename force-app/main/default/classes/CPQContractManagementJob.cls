public class CPQContractManagementJob extends AbstractBatchable implements Schedulable, Database.AllowsCallouts {
    private final CPQRenewalService renewalService = CPQRenewalService.getInstance();

    public void execute(final SchedulableContext context) {
        Database.executeBatch(this, 1);
    }

    public Database.QueryLocator start(final Database.BatchableContext context) {
        return Database.getQueryLocator([
                SELECT Id
                FROM Contract
                WHERE EndDate < TODAY
                  AND Status = 'Activated'
                  AND StartDate <= TODAY
                  AND Wrike_Account_ID__c > 0
                  AND RecordType.DeveloperName = 'CPQ_Contracts'
                ORDER BY EndDate, Wrike_Account_ID__c, Contract.AccountId
        ]);
    }

    public void execute(final Database.BatchableContext context, final List<Contract> records) {
        System.assertEquals(1, records.size(), 'Please run the job with batch size = 1');
        final Id contractId = records[0].Id;
        final CPQRenewalService.CPQRenewalData renewalData = renewalService.findRenewalData(contractId);
        final String renewalStatus = renewalData.getRenewalStatus();
        final Logger logger = Logger.create(CPQContractManagementJob.class);
        if(renewalStatus == CPQRenewalService.CPQRenewalStatus.Expire.name()) {
            renewalService.expireContract(contractId);
            logger.logContractAction(contractId, 'Contract Management Job: Contract Expired', 'Contract expired', renewalData);
        } else if(renewalStatus == CPQRenewalService.CPQRenewalStatus.GracePeriod.name()
                    && renewalData.getGracePeriodStartDate() == null) {
            renewalService.setGracePeriod(contractId);
            logger.logContractAction(contractId, 'Contract Management Job: Grace Period', 'Grace Period set', renewalData);
        } else if(renewalStatus == CPQRenewalService.CPQRenewalStatus.Renew.name()
                    && renewalData.getContract().AutoRenewalQuote__r == null) {
            final HttpResponse response = createAutoRenewalQuote(contractId);
            System.assertEquals(200, response.getStatusCode(), 'Failed to create auto renewal quote.');
            logger.logContractAction(contractId, 'Contract Management Job: Quote Creation REST Handler', 'Rest handler executed.', renewalData);
        }
        update new Contract(
            Id = contractId,
            LastRenewalCheckDate__c = DateUtils.getPacificLocalDate()
        );
    }

    private HttpResponse createAutoRenewalQuote(final Id contractId) { // REST call is used to bypass queueable transaction limit
        final HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/cpq/autorenew/quote');
        request.setBody(JSON.serialize(new Map<String, String> {'contractId' => contractId}));
        request.setTimeout(120000);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        return new Http().send(request);
    }

    public void finish(final Database.BatchableContext context) {
        sendFailedRecordsNotifications(
                context.getJobId(),
                SettingsProvider.getCPQRenewalNotificationEmails()
        );
        Database.executeBatch(new CPQQuoteManagementJob(), 1);
    }
}
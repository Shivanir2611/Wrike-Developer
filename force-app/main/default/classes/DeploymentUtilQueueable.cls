public class DeploymentUtilQueueable implements Queueable, Database.AllowsCallouts {
    
    private final List<Id> deploymentIds;
    
    public DeploymentUtilQueueable(final List<Id> deploymentIds) {     
        this.deploymentIds = deploymentIds;
    } 
    
    public void execute(QueueableContext context) {
        final Map<Id, Deployment__c> deploymentMap = new Map<Id, Deployment__c> (
            DeploymentQueryService.getInstance().listWithOpportunityByIds(deploymentIds)
        );
        final Map<Id, BillingInfo> deploymentBillingInfoMap = new Map<Id, BillingInfo>();
        final List<String> billingInfoEmails = new List<String>();
        final ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();
        final ZuoraService zuoraSrv = ZuoraService.getInstance();
        if(!Test.isRunningTest()) {
            for(Deployment__c deployment : deploymentMap.values()) {
                final String zuoraAccountId = zuoraRestQuerySrv.findZuoraAccountIdByWrikeAccountId(deployment.Opportunity__r.Wrike_Account_Id__c);
                if(zuoraAccountId != null) {
                    final BillingInfo billingInfo = zuoraSrv.findBillingInfo(zuoraAccountId);
                    if(String.isNotBlank(billingInfo.firstName) && String.isNotBlank(billingInfo.email)) {
                        billingInfoEmails.add(billingInfo.email);
                        deploymentBillingInfoMap.put(deployment.Id, billingInfo);
                    }
                }
            }
            final Map<String, Id> emailContactIdMap = ContactQueryService.getInstance().findEmailContactIdMap(billingInfoEmails);
            final Map<String, Contact> contactsToCreate = new Map<String, Contact>();
            final List<Contact> contactsToUpdate = new List<Contact>();
            for(Id deploymentId : deploymentBillingInfoMap.keySet()) {
                final BillingInfo billingInfo = deploymentBillingInfoMap.get(deploymentId);
                final Id existingContactId = emailContactIdMap.get(billingInfo.email);
                final Deployment__c deployment = deploymentMap.get(deploymentId);
                final Contact contact = new Contact(
                    MailingCountryCode = billingInfo.country,
                    MailingStateCode = billingInfo.state,
                    MailingCity = billingInfo.city,
                    MailingStreet = String.join(new List<String> {billingInfo.address1, billingInfo.address2}, ' '),
                    MailingPostalCode = billingInfo.zip,
                    VAT__c = billingInfo.vatNumber
                );
                if(existingContactId != null) {
                    contact.Id = existingContactId ;
                    contactsToUpdate.add(contact);
                } else {
                    contactsToCreate.put(billingInfo.email, contact);
                    contact.AccountId = deployment.Account__c;
                    contact.FirstName = billingInfo.firstName;
                    contact.LastName = billingInfo.lastName;
                    contact.Email = billingInfo.email;
                }
            }
            if(!contactsToUpdate.isEmpty()) {
                update contactsToUpdate;
            }
            if(!contactsToCreate.isEmpty()) {
                insert contactsToCreate.values();
            }
            final List<Deployment__c> deploymentsToUpdate = new List<Deployment__c>();
            for(Id deploymentId : deploymentBillingInfoMap.keySet()) {
                final BillingInfo billingInfo = deploymentBillingInfoMap.get(deploymentId);
                final Id existingContactId = emailContactIdMap.get(billingInfo.email);
                if(existingContactId != null) {
                    deploymentsToUpdate.add(new Deployment__c(
                        Id = deploymentId,
                        Billing_Contact__c = existingContactId
                    ));
                } else if(contactsToCreate.containsKey(billingInfo.email)) {
                    deploymentsToUpdate.add(new Deployment__c(
                        Id = deploymentId,
                        Billing_Contact__c = contactsToCreate.get(billingInfo.email).Id
                    ));
                }
            }
            if(!deploymentsToUpdate.isEmpty()) {
                update deploymentsToUpdate;
            }
        }
    }
}
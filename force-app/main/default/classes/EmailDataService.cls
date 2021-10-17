/**
 * @author Andrey Kuleshov
 */
public class EmailDataService {

    public static EmailDataService getInstance() {
        return (EmailDataService)ServiceLocator.getInstance(EmailDataService.class);
    }

    private final EmailDataQueryService emailDataQuerySrv = EmailDataQueryService.getInstance();
    private final LeadQueryService leadQuerySrv = LeadQueryService.getInstance();
    private final ContactQueryService contactQuerySrv = ContactQueryService.getInstance();

    public Map<String, EmailData__c> findEmailDataMapByEmails(final Set<String> emails) {
        final Map<String, EmailData__c> emailDataMap = new Map<String, EmailData__c>();
        if(!emails.isEmpty()) {
            final List<EmailData__c> emailDataList = emailDataQuerySrv.listByEmails(emails);
            for(EmailData__c emailData : emailDataList) {
                emailDataMap.put(emailData.Email__c, emailData);
            }
        }
        return emailDataMap;
    }


    public void updateRelatedLeadsAndContacts(final Map<Id, EmailData__c> oldEmailDataMap, final Map<Id, EmailData__c> newEmailDataMap) {
        final Map<String, EmailData__c> updatedEmailDataMap = new Map<String, EmailData__c>();
        for (Id emailDataId : newEmailDataMap.keySet()) {
            final EmailData__c oldRecord = oldEmailDataMap.get(emailDataId);
            final EmailData__c newRecord = newEmailDataMap.get(emailDataId);
            if(oldRecord.Industry__c != newRecord.Industry__c
                    || oldRecord.CompanyName__c != newRecord.CompanyName__c
                    || oldRecord.CompanySize__c != newRecord.CompanySize__c
                    || oldRecord.JobTitle__c != newRecord.JobTitle__c
                    || oldRecord.Phone__c != newRecord.Phone__c
                    || oldRecord.CountryCode__c != newRecord.CountryCode__c
                    || oldRecord.StateCode__c != newRecord.StateCode__c
                    || oldRecord.City__c != newRecord.City__c
                    || oldRecord.ReferralCode__c != newRecord.ReferralCode__c
                    || oldRecord.UnsubscribedDate__c != newRecord.UnsubscribedDate__c) {
                updatedEmailDataMap.put(newRecord.Email__c, newRecord);
            }
        }
        final List<Lead> leadsToUpdate = new List<Lead>();
        final List<Contact> contactsToUpdate = new List<Contact>();
        if(!updatedEmailDataMap.isEmpty()) {
            final List<Lead> leads = leadQuerySrv.findByEmails(updatedEmailDataMap.keySet());
            final List<Contact> contacts = contactQuerySrv.findByEmails(updatedEmailDataMap.keySet());
            for(Lead lead : leads) {
                final EmailData__c emailData = updatedEmailDataMap.get(lead.Email);
                final boolean needPhoneUpdate = String.isNotBlank(emailData.Phone__c) && String.isBlank(lead.Phone);
                final boolean needTitleUpdate = String.isNotBlank(emailData.JobTitle__c) && String.isBlank(lead.Title);
                final boolean needIndustryUpdate = emailData.Industry__c != lead.Industry;
                final boolean needCompanyUpdate = String.isNotBlank(emailData.CompanyName__c) && lead.Company.startsWith('Unknown <');
                final boolean needCompanySizeUpdate = emailData.CompanySize__c > 0
                        && (lead.NumberOfEmployees == null || emailData.CompanySize__c > lead.NumberOfEmployees);
                final boolean needReferralCodeUpdate = emailData.ReferralCode__c != lead.Referral_Code__c;
                final boolean needEmailOptOutUpdate = emailData.UnsubscribedDate__c != null && lead.HasOptedOutOfEmail != true;
                final boolean needAddressUpdate = (emailData.CountryCode__c != null && lead.CountryCode == null)
                        || (emailData.CountryCode__c == lead.CountryCode && emailData.StateCode__c != null && lead.StateCode == null)
                        || (emailData.CountryCode__c == lead.CountryCode
                                && emailData.StateCode__c == lead.StateCode
                                && String.isNotBlank(emailData.City__c)
                                && String.isBlank(lead.City));
                if(needPhoneUpdate || needTitleUpdate || needIndustryUpdate || needCompanyUpdate
                        || needCompanySizeUpdate || needReferralCodeUpdate || needAddressUpdate || needEmailOptOutUpdate) {
                    final Lead leadToUpdate = new Lead(
                        Id = lead.Id,
                        EmailData__c = emailData.Id
                    );
                    if(needPhoneUpdate) {
                        leadToUpdate.Phone = emailData.Phone__c;
                    }
                    if(needTitleUpdate) {
                        leadToUpdate.Title = emailData.JobTitle__c;
                    }
                    if(needIndustryUpdate) {
                        leadToUpdate.Industry = emailData.Industry__c;
                    }
                    if(needCompanyUpdate) {
                        leadToUpdate.Company = emailData.CompanyName__c;
                    }
                    if(needCompanySizeUpdate) {
                        leadToUpdate.NumberOfEmployees = emailData.CompanySize__c.intValue();
                    }
                    if(needReferralCodeUpdate) {
                        leadToUpdate.Referral_Code__c = emailData.ReferralCode__c;
                    }
                    if(needEmailOptOutUpdate) {
                        leadToUpdate.HasOptedOutOfEmail = true;
                    }
                    if(needAddressUpdate) {
                        leadToUpdate.CountryCode = emailData.CountryCode__c;
                        if(CountryUtil.isValidCanadaUsState(emailData.CountryCode__c, emailData.StateCode__c)) {
                            leadToUpdate.StateCode = emailData.StateCode__c;
                        } else {
                            leadToUpdate.StateCode = null;
                        }
                        leadToUpdate.City = emailData.City__c;
                    }
                    leadsToUpdate.add(leadToUpdate);
                }
            }
            for(Contact contact : contacts) {
                final EmailData__c emailData = updatedEmailDataMap.get(contact.Email);
                if(emailData.UnsubscribedDate__c != null && contact.HasOptedOutOfEmail != true) {
                    contactsToUpdate.add(new Contact(
                        Id = contact.Id,
                        HasOptedOutOfEmail = true
                    ));
                }
            }
        }
        if(!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}
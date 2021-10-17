public with sharing class ContactService {

    public static final String WRIKE_ADMIN_USER_TYPE = 'Admin';

    private final DatabaseService databaseSrv = DatabaseService.getInstance();
    private final AccountQueryService accountQuerySrv = AccountQueryService.getInstance();
    private final UserQueryService userQuerySrv = UserQueryService.getInstance();

    public static ContactService getInstance() {
        return (ContactService)ServiceLocator.getInstance(ContactService.class);
    }

    public void updateEmailDomainInAccount(final List<Contact> contacts) {
        Map<String, String> accountIdToEmailDomain = new Map<String, String>();
        for (Contact currentContact : contacts) {
            final String contactEmailDomain = currentContact.AccountId != null ? EmailUtil.getEmailDomain(currentContact.Email) : null;
            if (contactEmailDomain != null) {
                accountIdToEmailDomain.put(currentContact.AccountId, contactEmailDomain);
            }
        }
        if (accountIdToEmailDomain.isEmpty()) {
            return;
        }
        List<Account> accountsWithEmptyEmailDomain = accountQuerySrv.listAccountsWithEmptyEmailDomainByIds(accountIdToEmailDomain.keySet());
        for (Account currentAccount : accountsWithEmptyEmailDomain) {
            currentAccount.Email_Domain__c = accountIdToEmailDomain.get(currentAccount.Id);
        }
        databaseSrv.updateSObject(accountsWithEmptyEmailDomain);
    }

    public void createNotificationAboutNewAdmins(final Set<Id> contactsIds) {
        if (contactsIds.isEmpty()) {
            return;
        }
        final List<Contact> contacts = [
            SELECT Id, Account.Id, Account.Owner.Id, Account.Owner.IsActive
            FROM Contact
            WHERE Id IN :contactsIds
              AND AccountId != null
              AND Account.T2T_Account__c = false
        ];
        final List<Task> tasks = new List<Task>();
        for (Contact contact : contacts) {
            final Account account = contact.Account;
            tasks.add(new Task(
                    WhoId = contact.Id,
                    WhatId = account.Id,
                    OwnerId = account.Owner.isActive
                              ? account.Owner.Id
                              : SettingsProvider.getWrikeIntegrationUserId(),
                    Status = 'Open',
                    Subject = 'Onboard New Admin',
                    call_disposition__c = 'Follow Up',
                    ActivityDate = Date.today(),
                    IsReminderSet = true,
                    ReminderDateTime = Datetime.now()
            ));
        }
        databaseSrv.insertSObject(tasks);
    }
}
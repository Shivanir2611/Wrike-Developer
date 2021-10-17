@IsTest
private class DatabaseServiceTest {

    @IsTest
    static void testInsertSObject() {
        DatabaseService databaseSrv = DatabaseService.getInstance();

        Account account1 = TestDataFactory.createAccount(StringUtils.generateRandomString(10));
        System.assert(databaseSrv.insertSObject(account1));

        Account account2 = TestDataFactory.createAccount(StringUtils.generateRandomString(11));
        System.assert(databaseSrv.insertSObject(new List<Account>{account2}));

        Account account3 = TestDataFactory.createAccount(StringUtils.generateRandomString(12));
        account3.put('Id', '1');
        System.assert(!databaseSrv.insertSObject(account3));

        Account account4 = TestDataFactory.createAccount(StringUtils.generateRandomString(13));
        account4.put('Id', '1');
        System.assert(!databaseSrv.insertSObject(new List<Account>{account4}));
    }

    @IsTest
    static void testUpdateSObject() {
        DatabaseService databaseSrv = DatabaseService.getInstance();

        Account account1 = TestDataFactory.createAccount(StringUtils.generateRandomString(10));
        System.assert(databaseSrv.insertSObject(account1));
        System.assert(databaseSrv.updateSObject(account1));
        System.assert(databaseSrv.updateSObject(new List<Account>{account1}));

        account1.put('Id', '1');
        System.assert(!databaseSrv.updateSObject(account1));
        System.assert(!databaseSrv.updateSObject(new List<Account>{account1}));
    }

    @IsTest
    static void testUpsertSObject() {
        DatabaseService databaseSrv = DatabaseService.getInstance();

        Account account1 = TestDataFactory.createAccount(StringUtils.generateRandomString(10));
        System.assert(databaseSrv.upsertSObject(account1));

        Account account2 = TestDataFactory.createAccount(StringUtils.generateRandomString(11));
        System.assert(databaseSrv.upsertSObject(new List<Account>{account2}));

        Account account3 = TestDataFactory.createAccount(StringUtils.generateRandomString(12));
        account3.put('Id', '1');
        System.assert(!databaseSrv.upsertSObject(account3));

        Account account4 = TestDataFactory.createAccount(StringUtils.generateRandomString(13));
        account4.put('Id', '1');
        System.assert(!databaseSrv.upsertSObject(new List<Account>{account4}));
    }

    @IsTest
    static void testDeleteSObject() {
        DatabaseService databaseSrv = DatabaseService.getInstance();

        Account account1 = TestDataFactory.createAccount(StringUtils.generateRandomString(10));
        System.assert(databaseSrv.insertSObject(account1));

        System.assert(databaseSrv.deleteSObject(new List<String>{account1.Id}));
        System.assert(!databaseSrv.deleteSObject(new List<String>{'001000000000000'}));
    }

//    System.LimitException: Apex CPU time limit exceeded
//    @IsTest
//    static void testMaxRecordsNumber() {
//        DatabaseService databaseSrv = DatabaseService.getInstance();
//
//        List<Account> accounts = new List<Account>();
//        for (Integer i = 0; i < 10000; i++) {
//            accounts.add(TestDataFactory.createAccount());
//        }
//        System.assert(databaseSrv.insertSObject(accounts));
//
//        Account account2 = TestDataFactory.createAccount();
//        System.assert(!databaseSrv.insertSObject(account2));
//        System.assert(!databaseSrv.insertSObject(new List<Account>{account2}));
//        System.assert(!databaseSrv.updateSObject(account2));
//        System.assert(!databaseSrv.updateSObject(new List<Account>{account2}));
//        System.assert(!databaseSrv.upsertSObject(account2));
//        System.assert(!databaseSrv.upsertSObject(new List<Account>{account2}));
//        System.assert(!databaseSrv.deleteSObject(new List<String>{accounts[0].Id}));
//    }
}
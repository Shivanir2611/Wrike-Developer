@IsTest
public class TaskCleanUpJobTest {
    
    @testSetup
    public static void setup() {
        TestUtils.insertAndAssert(TestDataFactory.createAccount());
        TestUtils.insertAndAssert(TestDataFactory.createContact());
    }
    
    @IsTest
    static void testContactTasksDeleted() {
        final Contact testContact = TestUtils.findContact();
        Task contactTask = TestDataFactory.createTask(testContact.Id, null, 'Call', 'Outbound Call', 60, 'Outbound');
        TestUtils.insertAndAssert(contactTask); 
        Test.setCreatedDate(contactTask.Id, DateTime.newInstance(2012,12,12));
        TestUtils.updateAndAssert(contactTask);
        
        Test.startTest();
        Database.executeBatch(new TaskCleanUpJob());
        Test.stopTest();
        
        final List<Task> contactTaskList = [
            SELECT Id
            FROM Task
            WHERE Id =: contactTask.Id
        ];
        System.assertEquals(0, contactTaskList.size()); 
    }
    
    @IsTest
    static void testAccountTasksDeleted() {
        final Account testAccount = TestUtils.findAccount();
        Task accountTask = TestDataFactory.createTask(null, testAccount.Id, 'Call', 'Quarterly check in', 60, 'Outbound');
        TestUtils.insertAndAssert(accountTask); 
        Test.setCreatedDate(accountTask.Id, DateTime.newInstance(2012,12,12));
        TestUtils.updateAndAssert(accountTask);
        
        Test.startTest();
        Database.executeBatch(new TaskCleanUpJob());
        Test.stopTest();
        
        final List<Task> accountTaskList = [
            SELECT Id
            FROM Task
            WHERE Id =: accountTask.Id
        ];
        System.assertEquals(0, accountTaskList.size()); 
    }
    
    @IsTest
    static void testAccountTasksNotDeleted() {
        final Account testAccount = TestUtils.findAccount();
        Task accountTask = TestDataFactory.createTask(null, testAccount.Id, 'Call', 'Yearly check in', 60, 'Outbound');
        TestUtils.insertAndAssert(accountTask); 
        
        Test.startTest();
        Database.executeBatch(new TaskCleanUpJob());
        Test.stopTest();
        
        final List<Task> accountTaskList = [
            SELECT Id
            FROM Task
            WHERE Id =: accountTask.Id
        ];
        System.assertNotEquals(0, accountTaskList.size()); 
    }
    
    @IsTest
    static void testContactTasksNotDeleted() {
        final Contact testContact = TestUtils.findContact();
        Task contactTask = TestDataFactory.createTask(testContact.Id, null, 'Call', 'Outbound Call', 60, 'Outbound');
        TestUtils.insertAndAssert(contactTask); 
        Test.setCreatedDate(contactTask.Id, DateTime.now().addDays(-365));
        TestUtils.updateAndAssert(contactTask);
        
        Test.startTest();
        Database.executeBatch(new TaskCleanUpJob());
        Test.stopTest();
        
        final List<Task> contactTaskList = [
            SELECT Id
            FROM Task
            WHERE Id =: contactTask.Id
        ];
        System.assertNotEquals(0, contactTaskList.size()); 
    }
}
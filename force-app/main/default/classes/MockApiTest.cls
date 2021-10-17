@IsTest
public class MockApiTest {

    @IsTest
    static void testMockStrict() {

        GroupService groupSrv = (GroupService)MockApi.mock(GroupService.class);
        MockApi.setup()
                .mockStrict(groupSrv.getQueueIdByDevNameOrNull('123'), '123')
                .mockStrict(groupSrv.getQueueIdByDevNameOrNull('456'), '456')
                .build();

        Test.startTest();

        System.assertEquals('123', groupSrv.getQueueIdByDevNameOrNull('123'));
        System.assertEquals('456', groupSrv.getQueueIdByDevNameOrNull('456'));

        try {
            groupSrv.getQueueIdByDevNameOrNull('789');
        } catch (MockApi.MockingException e) {
            System.assert(e.getMessage().contains('Parameter mismatch for method'));
        }

        Test.stopTest();
    }

    @IsTest
    static void testMockTypeAndParametersStrategies() {

        GroupService groupSrv = (GroupService)MockApi.mock(GroupService.class);
        MockApi.setup()
                .mockStrict(groupSrv.getQueueIdByDevNameOrNull('123'), '123')
                .mockStrict(groupSrv.getQueueIdByDevNameOrNull('456'), '456')
                .mock(groupSrv.getQueueIdByDevNameOrNull(''), 'default')
                .build();

        Test.startTest();

        System.assertEquals('123', groupSrv.getQueueIdByDevNameOrNull('123'));
        System.assertEquals('456', groupSrv.getQueueIdByDevNameOrNull('456'));
        System.assertEquals('default', groupSrv.getQueueIdByDevNameOrNull('789'));

        Test.stopTest();
    }

    @IsTest
    static void testSetupMockFault() {

        GroupService groupSrv = (GroupService)MockApi.mock(GroupService.class);
        try {
            MockApi.setup()
                    .mock(groupSrv.getQueueIdByDevNameOrNull('123'), '123')
                    .mock(groupSrv.getQueueIdByDevNameOrNull('456'), '456')
                    .build();
        } catch (MockApi.MockingException e) {
            System.assert(e.getMessage().contains('Mocking method already has ParameterTypeMatch strategy'));
        }
    }

    @IsTest
    static void testNoMockMapping() {

        GroupService groupSrv = (GroupService)MockApi.mock(GroupService.class);

        Test.startTest();
        System.assertEquals(null, groupSrv.getQueueIdByDevNameOrNull('123'));
        Test.stopTest();
    }
}
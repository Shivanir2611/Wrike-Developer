@IsTest
public class OrganizationServiceTest {

    @IsTest
    public static void testIsSandbox() {
        final String instanceName = [SELECT InstanceName FROM Organization].InstanceName;
        System.assertEquals(instanceName.startsWith('CS'), OrganizationService.getInstance().isSandbox());
    }
}
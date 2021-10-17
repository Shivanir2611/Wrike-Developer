@IsTest
public class NamedCredentialServiceTest {

    @IsTest
    public static void testValidSandboxZuoraInstance() {
        final OrganizationService organizationSrv = (OrganizationService)MockApi.mock(OrganizationService.class);
        final NamedCredentialQueryService namedCredentialQuerySrv =
                (NamedCredentialQueryService)MockApi.mock(NamedCredentialQueryService.class);
        MockApi.setup().mock(organizationSrv.isSandbox(), true)
                .mockStrict(namedCredentialQuerySrv.findEndpointByName('ZuoraRest'), 'https://rest.apisandbox.zuora.com/v1')
                .build();
        NamedCredentialService.getInstance().checkZuoraInstance();
    }

    @IsTest
    public static void testValidProductionZuoraInstance() {
        final OrganizationService organizationSrv = (OrganizationService)MockApi.mock(OrganizationService.class);
        final NamedCredentialQueryService namedCredentialQuerySrv =
                (NamedCredentialQueryService)MockApi.mock(NamedCredentialQueryService.class);
        MockApi.setup().mock(organizationSrv.isSandbox(), false)
                .mockStrict(namedCredentialQuerySrv.findEndpointByName('ZuoraRest'), 'https://rest.zuora.com/v1')
                .build();
        NamedCredentialService.getInstance().checkZuoraInstance();
    }

    @IsTest
    public static void testInvalidSandboxZuoraInstance() {
        final OrganizationService organizationSrv = (OrganizationService)MockApi.mock(OrganizationService.class);
        final NamedCredentialQueryService namedCredentialQuerySrv =
                (NamedCredentialQueryService)MockApi.mock(NamedCredentialQueryService.class);
        MockApi.setup().mock(organizationSrv.isSandbox(), true)
                .mockStrict(namedCredentialQuerySrv.findEndpointByName('ZuoraRest'), 'https://rest.zuora.com/v1')
                .build();
        try {
            NamedCredentialService.getInstance().checkZuoraInstance();
        } catch (NamedCredentialService.NamedCredentialException e) {
            return;
        }
        System.assert(false, 'No exception for production Zuora properties.');
    }

}
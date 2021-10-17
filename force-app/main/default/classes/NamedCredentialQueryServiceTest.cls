@IsTest
public class NamedCredentialQueryServiceTest {

    @IsTest
    public static void testFindEndpointByName() {
        final NamedCredentialQueryService service = NamedCredentialQueryService.getInstance();
        System.assert(service.findEndpointByName('ZuoraRest') != null, 'Zuora named credential not found.');
    }

}
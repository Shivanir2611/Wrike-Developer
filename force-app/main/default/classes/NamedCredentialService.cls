public class NamedCredentialService {

    private OrganizationService organizationSrv = OrganizationService.getInstance();
    private NamedCredentialQueryService namedCredentialQuerySrv = NamedCredentialQueryService.getInstance();

    public static NamedCredentialService getInstance() {
        return (NamedCredentialService)ServiceLocator.getInstance(NamedCredentialService.class);
    }

    public void checkZuoraInstance() {
        final String zuoraEndpoint = namedCredentialQuerySrv.findEndpointByName('ZuoraRest');
        if(String.isBlank(zuoraEndpoint) ) {
            throw new NamedCredentialException('No Zuora connections properties.');
        }
        if(organizationSrv.isSandbox() && zuoraEndpoint.containsIgnoreCase('rest.zuora.com')) {
            throw new NamedCredentialException('This sandbox is connected to production Zuora instance. Please change connection properties.');
        }
    }

    public class NamedCredentialException extends Exception {
    }
}
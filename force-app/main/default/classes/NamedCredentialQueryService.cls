public class NamedCredentialQueryService {

    public static NamedCredentialQueryService getInstance() {
        return (NamedCredentialQueryService)ServiceLocator.getInstance(NamedCredentialQueryService.class);
    }

    public String findEndpointByName(final String name) {
        final List<NamedCredential> credentials = [
            SELECT Endpoint
            FROM NamedCredential
            WHERE DeveloperName = :name
        ];
        return credentials.isEmpty() ? null : credentials[0].Endpoint;
    }
}
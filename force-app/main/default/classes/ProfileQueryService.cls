public with sharing class ProfileQueryService {

    public static ProfileQueryService getInstance() {
        return (ProfileQueryService)ServiceLocator.getInstance(ProfileQueryService.class);
    }

    public List<Profile> getById(final Id profileId) {
        return [
            SELECT Id, Name
            FROM Profile
            WHERE Id = :profileId
        ];
    }

    public Boolean isAdminOrBillingProfile(final Id profileId) {
        return ![
            SELECT Id
            FROM Profile
            WHERE Id = :profileId
              AND (Name LIKE '%System Administrator%' OR Name LIKE 'Billing%')

        ].isEmpty();
    }
}
public class OrganizationService {

    public static OrganizationService getInstance() {
        return (OrganizationService)ServiceLocator.getInstance(OrganizationService.class);
    }

    public Boolean isSandbox() {
        return [SELECT IsSandbox FROM Organization].IsSandbox;
    }
}
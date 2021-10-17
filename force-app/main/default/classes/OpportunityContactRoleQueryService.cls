public class OpportunityContactRoleQueryService {

    public static OpportunityContactRoleQueryService getInstance() {
        return (OpportunityContactRoleQueryService)ServiceLocator.getInstance(OpportunityContactRoleQueryService.class);
    }

    public List<OpportunityContactRole> findByOpportunityId(final String opportunityId) {
        return [
            SELECT Contact.Id, Contact.Name, Contact.Email, IsPrimary, Contact.FirstName, Contact.LastName
            FROM OpportunityContactRole
            WHERE Contact.Email != NULL AND OpportunityId = :opportunityId
            ORDER BY Contact.Name
        ];
    }
}
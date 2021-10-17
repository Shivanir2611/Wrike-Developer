public class EmailTemplateQueryService {
    
    public static EmailTemplateQueryService getInstance() {
        return (EmailTemplateQueryService)ServiceLocator.getInstance(EmailTemplateQueryService.class);
    }

    public Id findTemplateIdByName(final String name) {
        final List<EmailTemplate> templates = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = :name
        ];
        return templates.isEmpty() ? null : templates[0].Id;
    }
}
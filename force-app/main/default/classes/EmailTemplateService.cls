public class EmailTemplateService {
    private final EmailTemplateQueryService emailTemplateQuerySrv = EmailTemplateQueryService.getInstance();

    public static EmailTemplateService getInstance() {
        return (EmailTemplateService)ServiceLocator.getInstance(EmailTemplateService.class);
    }
    
    public Id findTemplateIdByName(final String name) {
        return emailTemplateQuerySrv.findTemplateIdByName(name);
    }
}
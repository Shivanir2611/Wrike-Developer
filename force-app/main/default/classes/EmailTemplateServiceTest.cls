@IsTest
public class EmailTemplateServiceTest {

    @IsTest
    public static void testFindTemplateIdByName() {
        final EmailTemplate template = new EmailTemplate();  
        template.isActive = true;  
        template.Name = 'EmailTemplateServiceTest';  
        template.DeveloperName = 'Email_Template_Service_Test';  
        template.TemplateType = 'Text';  
        template.FolderId = UserInfo.getUserId();  
        template.Body = 'Test email template';
        insert template; 
        final EmailTemplateService service = EmailTemplateService.getInstance();
        System.assertEquals(template.Id, service.findTemplateIdByName('Email_Template_Service_Test'));
    }
}
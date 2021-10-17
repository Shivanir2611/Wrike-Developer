public with sharing class AttachmentService {

    public static AttachmentService getInstance() {
        return (AttachmentService)ServiceLocator.getInstance(AttachmentService.class);
    }

    private AttachmentQueryService attachmentQuerySrv;

    public AttachmentService() {
        this.attachmentQuerySrv = AttachmentQueryService.getInstance();
    }

    public Attachment findById(final String attachmentId) {
        if (String.isBlank(attachmentId)) {
            return null;
        }
        List<Attachment> attachemnts = attachmentQuerySrv.findById(attachmentId);
        if (attachemnts.isEmpty()) {
            return null;
        }
        return attachemnts[0];
    }
}
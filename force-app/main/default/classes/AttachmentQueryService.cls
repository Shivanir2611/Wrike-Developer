public with sharing class AttachmentQueryService {

    public static AttachmentQueryService getInstance() {
        return (AttachmentQueryService)ServiceLocator.getInstance(AttachmentQueryService.class);
    }

    public List<Attachment> findById(final String attachmentId) {
        return [
            SELECT Id, Name
            FROM Attachment
            WHERE Id = :attachmentId
        ];
    }

    public List<Attachment> findByParentIds(final List<Id> parentIds) {
        return [
            SELECT Id, Name, ParentId
            FROM Attachment
            WHERE ParentId IN :parentIds
            ORDER BY ParentId ASC, CreatedDate ASC
        ];
    }
}
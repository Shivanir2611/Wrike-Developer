public class ContentDocumentLinkTriggerHandler {

    public static ContentDocumentLinkTriggerHandler getInstance() {
        return (ContentDocumentLinkTriggerHandler)ServiceLocator.getInstance(ContentDocumentLinkTriggerHandler.class);
    }

    public void afterInsert(final List<ContentDocumentLink> links) {
        final Map<Id, Id> docuSignStatusIdByFileIdMap = new Map<Id, Id>();
        for (ContentDocumentLink link : links) {
            if (dsfs__DocuSign_Status__c.sObjectType == link.LinkedEntityId.getSobjectType()) {
                docuSignStatusIdByFileIdMap.put(link.ContentDocumentId, link.LinkedEntityId);
            }
        }
        final Map<Id, ContentDocument> fileMap = new Map<Id, ContentDocument>([
                SELECT Id, Title
                FROM ContentDocument
                WHERE Id IN :docuSignStatusIdByFileIdMap.keySet()
        ]);
        final Map<Id, dsfs__DocuSign_Status__c> statusMap = new Map<Id, dsfs__DocuSign_Status__c>([
                SELECT Id, Quote__c, dsfs__Envelope_Status__c
                FROM dsfs__DocuSign_Status__c
                WHERE Id IN :docuSignStatusIdByFileIdMap.values()
                AND Quote__c != null
                AND dsfs__Envelope_Status__c = 'Completed'
        ]);
        final List<WrikeQuoteDocument__c> documentsToCreate = new List<WrikeQuoteDocument__c>();
        final List<ContentDocumentLink> accessLinks = new List<ContentDocumentLink>();
        for (Id fileId : docuSignStatusIdByFileIdMap.keySet()) {
            final dsfs__DocuSign_Status__c status = statusMap.get(docuSignStatusIdByFileIdMap.get(fileId));
            if (status != null) {
                final ContentDocument file = fileMap.get(fileId);
                documentsToCreate.add(new WrikeQuoteDocument__c(
                        Name = file.Title,
                        Type__c = 'Quote-Docusigned',
                        Quote__c = status.Quote__c,
                        ContentDocumentId__c = file.Id
                ));
                accessLinks.add(new ContentDocumentLink(
                        LinkedEntityId = status.Quote__c,
                        Visibility = 'InternalUsers',
                        ShareType = 'V',
                        ContentDocumentId = file.Id
                ));
            }
        }
        if (!documentsToCreate.isEmpty()) {
            insert documentsToCreate;
        }
        if (!accessLinks.isEmpty()) {
            insert accessLinks;
        }
    }
}
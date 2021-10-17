public with sharing class AccountRelatedListController {
    
    @AuraEnabled
    public static List<WrappedFile> getRelatedNotes(Id recordId){
        List<WrappedFile> wrappedFileList = new List<WrappedFile>();
        List<Id> relatedIds = getRelatedRecordIds(recordId);
        for(Note note: [
            SELECT Id, Parent.Name, ParentId, Title, Body, CreatedDate, Owner.Name
            FROM Note 
            WHERE ParentId IN : relatedIds
            ORDER BY CreatedDate DESC
        ]){
            wrappedFileList.add(new WrappedFile(note.Title,
                                                note.Owner.Name,
                                                note.Id,
                                                note.ParentId,
                                                note.Parent.Name,
                                                note.CreatedDate.date(),
                                                null,
                                                note.Body,
                                                relatedSObjectType(note.ParentId)
                                               ));
        }
        for(ContentDocumentLink contentDocumentLink : getContentDocumentLinks(relatedIds)){
            ContentVersion contentVersion = contentDocumentLink.ContentDocument.LatestPublishedVersion;
            if(contentVersion.FileType == 'SNOTE'){
                wrappedFileList.add(new WrappedFile(contentVersion.Title,
                                                    contentVersion.Owner.Name,
                                                    contentDocumentLink.ContentDocumentId,
                                                    contentDocumentLink.LinkedEntityId,
                                                    contentDocumentLink.LinkedEntity.Name,
                                                    contentVersion.CreatedDate.date(),
                                                    contentVersion.FileType,
                                                    contentVersion.TextPreview,
                                                    relatedSObjectType(contentDocumentLink.LinkedEntityId)
                                                   ));
            }
        }
        return wrappedFileList;
    }
    
    @AuraEnabled
    public static List<WrappedFile> getRelatedFiles(Id recordId){
        List<WrappedFile> wrappedFileList = new List<WrappedFile>();
        List<Id> relatedIds = getRelatedRecordIds(recordId);
        for(ContentDocumentLink contentDocumentLink : getContentDocumentLinks(relatedIds)){
            ContentVersion contentVersion = contentDocumentLink.ContentDocument.LatestPublishedVersion;
            if(contentVersion.FileType != 'SNOTE'){    
                wrappedFileList.add(new WrappedFile(contentVersion.Title,
                                                    contentVersion.Owner.Name,
                                                    contentDocumentLink.ContentDocumentId,
                                                    contentDocumentLink.LinkedEntityId,
                                                    contentDocumentLink.LinkedEntity.Name,
                                                    contentVersion.CreatedDate.date(),
                                                    contentVersion.FileType,
                                                    contentVersion.TextPreview,
                                                    relatedSObjectType(contentDocumentLink.LinkedEntityId)
                                                   ));
            }
        }
        for(Attachment attachment : getAttachments(relatedIds)){
            wrappedFileList.add(new WrappedFile(attachment.Name,
                                                attachment.Owner.Name,
                                                attachment.Id,
                                                attachment.ParentId,
                                                attachment.Parent.Name,
                                                attachment.CreatedDate.date(),
                                                attachment.ContentType,
                                                attachment.Description,
                                                relatedSObjectType(attachment.ParentId)
                                               ));
        }
        return wrappedFileList;
    }
    
    public class WrappedFile{
        @AuraEnabled public String title {get; set;}
        @AuraEnabled public String ownerName {get; set;}
        @AuraEnabled public Id titleId {get; set;}
        @AuraEnabled public Id relatedToId {get; set;}
        @AuraEnabled public String relatedTo {get; set;}
        @AuraEnabled public Date createdDate {get; set;}
        @AuraEnabled public String fileType {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public String relatedType {get; set;}
        public WrappedFile(String title, String ownerName, Id titleId, Id relatedToId, String relatedTo, 
                           Date createdDate, String fileType, String description, String relatedType){
                               this.title = title;
                               this.ownerName = ownerName;
                               this.titleId = titleId;
                               this.relatedToId = relatedToId;
                               this.relatedTo = relatedTo;
                               this.createdDate = createdDate;
                               this.fileType = fileType;
                               this.description = description;
                               this.relatedType = relatedType;
                           }
    }
    
    private static List<Id> getRelatedRecordIds(Id accountId){
        List<Opportunity> opportunityList = [SELECT Id FROM Opportunity WHERE AccountId =:accountId];
        List<Contact> contactList = [SELECT Id FROM Contact WHERE AccountId =: accountId];
        List<Contract> contractList = [SELECT Id FROM Contract WHERE AccountId =: accountId];
        List<Id> relatedIds = new List<Id>();
        for(Opportunity opp : opportunityList){
            relatedIds.add(opp.Id);
        }
        for(Contact contact : contactList){
            relatedIds.add(contact.Id);
        }
        for(Contract contract : contractList){
            relatedIds.add(contract.Id);
        }
        return relatedIds;
    }
    
    private static List<ContentDocumentLink> getContentDocumentLinks(List<Id> relatedIds){
        return [
            SELECT LinkedEntityId, LinkedEntity.Name, ContentDocumentId,
                   ContentDocument.LatestPublishedVersion.CreatedDate,
                   ContentDocument.LatestPublishedVersion.FileType,
                   ContentDocument.LatestPublishedVersion.TextPreview,
                   ContentDocument.LatestPublishedVersion.Owner.Name,
                   ContentDocument.LatestPublishedVersion.Title
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN : relatedIds
            AND ContentDocument.LatestPublishedVersion.IsLatest = true
            ORDER BY ContentDocument.LatestPublishedVersion.CreatedDate DESC
        ];
    }
    
    private static List<Attachment> getAttachments(List<Id> relatedIds){
        return [
            SELECT Id, Name, ContentType, ParentId, Owner.Name, CreatedDate, Parent.Name, Description
            FROM Attachment 
            WHERE ParentId IN : relatedIds
            ORDER BY CreatedDate DESC
        ];
    }
    
    private static String relatedSObjectType(Id relatedToId){
        return String.valueOf(relatedToId.getSobjectType());
    }
}
public class WrikeDeploymentEmailHandler implements Messaging.InboundEmailHandler{
    public Messaging.InboundEmailResult  handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env){
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        final List<Task> emailTaskList = new List<Task>();
        final List<String> emailAddressList = new List<String>();
        final Map<String,String> emailDomainMap = new Map<String,String>();
        for(String toEmailAddress : email.toAddresses){
            emailAddressList.add(toEmailAddress);
            emailDomainMap.put(toEmailAddress, toEmailAddress.split('@').get(1));
        }
        contactTaskCreation(emailAddressList, emailDomainMap, email);
        result.success = true;
        return result; 
    }
    
    private static void contactTaskCreation(List<String> emailAddressList, Map<String,String> emailDomainMap, Messaging.InboundEmail email){
        final List<Task> contactEmailTaskList = new List<Task>();
        final Map<String,String> noContactFoundMap = new Map<String,String>();
        final Map<String,Id> emailContactMap = new Map<String,Id>();
        for(Contact newContact : [
            SELECT Id, Email 
            FROM Contact 
            WHERE Email IN : emailAddressList
            ORDER BY CreatedDate DESC
        ]){
            if(!emailContactMap.containsKey(newContact.Email)){
            	emailContactMap.put(newContact.Email, newContact.Id);    
            }
        }
        if(!emailContactMap.isEmpty()){
            for(String contactToEmailAddress : emailDomainMap.keyset()){
                if(emailContactMap.containsKey(contactToEmailAddress)){
                    contactEmailTaskList.add(taskCreation(email.subject, email.plainTextBody, email.fromAddress, emailContactMap.get(contactToEmailAddress)));
                } else{
                    noContactFoundMap.put(contactToEmailAddress, emailDomainMap.get(contactToEmailAddress));
                }
            }
        } else{
            accountTaskCreation(emailDomainMap, email);	    
        }    
        if(!contactEmailTaskList.isEmpty()){
            insert contactEmailTaskList; 
        }
        if(!noContactFoundMap.isEmpty()){	
            accountTaskCreation(noContactFoundMap, email);
        }
    }
    
    private static void accountTaskCreation(Map<String,String> emailDomainMap, Messaging.InboundEmail email){
        final List<Task> accountEmailTaskList = new List<Task>();
        final Map<String,String> noAccountFoundMap = new Map<String,String>();
        Map<String, Id> domainAccountMap = new Map<String, Id>();
        for(Account newAccount : [
            SELECT Id, Email_Domain__c 
            FROM Account 
            WHERE Email_Domain__c IN : emailDomainMap.values()
            AND Email_Domain__c != null
        ]){
            domainAccountMap.put(newAccount.Email_Domain__c, newAccount.id);	  
        }
        if(!emailDomainMap.isEmpty()){
            for(String toEmailAddressDomain : emailDomainMap.keyset()){
                if(domainAccountMap.containsKey(emailDomainMap.get(toEmailAddressDomain))){
                    accountEmailTaskList.add(taskCreation(email.subject, email.plainTextBody, email.fromAddress, domainAccountMap.get(emailDomainMap.get(toEmailAddressDomain))));
                } else{
                    noAccountFoundMap.put(toEmailAddressDomain, emailDomainMap.get(toEmailAddressDomain));
                }
            }    
        } else{
            noRelationTaskCreation(emailDomainMap, email);    
        }
        if(!accountEmailTaskList.isEmpty()){
            insert accountEmailTaskList;  
        }
        if(!noAccountFoundMap.isEmpty()){
            noRelationTaskCreation(noAccountFoundMap, email);
        }
    }
    
    private static void noRelationTaskCreation(Map<String,String> emailDomainMap, Messaging.InboundEmail email){
        final List<Task> noRelationTaskList = new List<Task>();
        if(!emailDomainMap.isEmpty()){
            for(String toEmailAddress : emailDomainMap.keyset()){
                noRelationTaskList.add(taskCreation(email.subject, email.plainTextBody, email.fromAddress, null));
            }
        }
        if(!noRelationTaskList.isEmpty()){
            insert noRelationTaskList;
        }    
    }
    
    private static Task taskCreation(String emailSubject, String textBody, String fromAddress, Id recordId){
        Task task = new Task(
            CallDisposition = 'Follow Up',
            Status = 'Completed',
            Type = 'Email',
            TaskSubtype = 'Email',
            ActivityDate = System.Today(),
            Subject = emailSubject,
            Description = textBody.abbreviate(32000),
            OwnerId = WrikeConstants.SF_ADMIN_ID,
            Priority = 'Normal',
            Sender__c = fromAddress,
            WhatId = recordId != null && recordId.getSobjectType() == Schema.Account.SObjectType ? recordId : null,
            WhoId = recordId != null && recordId.getSobjectType() == Schema.Contact.SObjectType ? recordId : null
        );
        return task;
    }
}
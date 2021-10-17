/**********************************************************
* @Author       Heidi Tang 
* @Date         2016-04-25
* @Description  Test class for KeyPlayersTriggerHandler
* @Requirement  REQ-0482 Auto-populate Contact Roles with Key Players/Influencers value.
**********************************************************/
/**********************************************************
* @Author       Heidi Tang
* @Date         2016-04-25
* @Description  Test class for KeyPlayersTriggerHandler
* @Requirement  REQ-0482 Auto-populate Contact Roles with Key Players/Influencers value.
**********************************************************/
@isTest
public with sharing class KeyPlayersTriggerHandlerTest {
    @testSetup static void testDataBuilder() {

        User internalUser = VistaTestDataFactory.createInternalSysAdminUser('usertest@companytest.com','Testing','usertest@companytest.com','test123');
        insert internalUser;


        System.runAs(internalUser){

            List<Account> acctList = VistaTestDataFactory.createAcctList(4,'Test Account');
            insert acctList;

            List<Contact> conList = VistaTestDataFactory.createConList(4,'testCon');
            conList[0].AccountId = acctList[0].Id;
            conList[1].AccountId = acctList[1].Id;
            conList[0].AccountId = acctList[2].Id;
            conList[1].AccountId = acctList[3].Id;
            insert conList;

            Opportunity newOpp = new Opportunity(AccountId = acctList[0].Id,Name='Test Opportunity',StageName= '1 - Plan', CloseDate=Date.today());
            insert newOpp;
        }
    }

    public static testMethod void testInsert(){
        User loginUser = [SELECT Id FROM User WHERE UserName='usertest@companytest.com' LIMIT 1 ];
        Opportunity newOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Contact> contactList = new List<Contact>([SELECT Id FROM Contact LIMIT 5]);

        System.runAs(loginUser){

            OpportunityContactRole contactRole = new OpportunityContactRole(ContactId = contactList[1].Id,OpportunityId=newOpp.Id,Role='Legal');
            insert contactRole;

            List<Key_Players_Influencers__c> keyPlayerList = new List<Key_Players_Influencers__c>();
            keyPlayerList.addAll(VistaTestDataFactory.createKeyInfluencer(4,'Legal',newOpp.Id));
            keyPlayerList[0].Name__c = contactList[0].Id;
            keyPlayerList[1].Name__c = contactList[1].Id;
            keyPlayerList[2].Name__c = contactList[2].Id;
            keyPlayerList[3].Name__c = contactList[3].Id;

            Test.startTest();
                insert keyPlayerList;

                List<OpportunityContactRole> contactRoleList = new List<OpportunityContactRole>([SELECT Id FROM OpportunityContactRole WHERE Role = 'Legal']);
                System.assert(contactRoleList.size()>0);

                Boolean isError = false;

                keyPlayerList.addAll(VistaTestDataFactory.createKeyInfluencer(4,'Legal',newOpp.Id));
                keyPlayerList[4].Name__c = contactList[0].Id;

                try{
                    insert keyPlayerList;
                } catch(DmlException dmle){
                    isError = true;
                }

                System.assert(isError);
            Test.stopTest();
        }
    }

    public static testMethod void testUpdate(){
        User loginUser = [SELECT Id FROM User WHERE UserName='usertest@companytest.com' LIMIT 1 ];
        Opportunity newOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Contact> contactList = new List<Contact>([SELECT Id FROM Contact LIMIT 5]);

        System.runAs(loginUser){

            OpportunityContactRole contactRole = new OpportunityContactRole(ContactId = contactList[1].Id,OpportunityId=newOpp.Id,Role='Legal');
            insert contactRole;

            List<Key_Players_Influencers__c> keyPlayerList = VistaTestDataFactory.createKeyInfluencer(4,'Legal',newOpp.Id);
            keyPlayerList[0].Name__c = contactList[0].Id;
            keyPlayerList[1].Name__c = contactList[1].Id;
            keyPlayerList[2].Name__c = contactList[2].Id;
            keyPlayerList[3].Name__c = contactList[3].Id;
            insert keyPlayerList;

            Test.startTest();
                keyPlayerList[0].Formal_Role__c = 'Finance';
                keyPlayerList[1].Formal_Role__c = 'Product';
                keyPlayerList[2].Formal_Role__c = 'Marketing';
                keyPlayerList[3].Formal_Role__c = 'Product';

                update keyPlayerList;

                List<OpportunityContactRole> contactRoleList = new List<OpportunityContactRole>([SELECT Id FROM OpportunityContactRole WHERE Role = 'Department']);

                System.assert(contactRoleList.size()==0);

                keyPlayerList[1].Formal_Role__c = 'Product';
                update keyPlayerList;


                Boolean isError = false;

                try{
                    keyPlayerList[2].Name__c = contactList[0].Id;
                    update keyPlayerList;
                } catch(DmlException dmle){
                    isError = true;
                }

                System.assert(isError);
            Test.stopTest();
        }
    }

    public static testMethod void testDelete(){
        User loginUser = [SELECT Id FROM User WHERE UserName='usertest@companytest.com' LIMIT 1 ];
        Opportunity newOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Contact> contactList = new List<Contact>([SELECT Id FROM Contact LIMIT 5]);

        System.runAs(loginUser){

            OpportunityContactRole contactRole = new OpportunityContactRole(ContactId = contactList[1].Id,OpportunityId=newOpp.Id,Role=null);
            insert contactRole;

            List<Key_Players_Influencers__c> keyPlayerList = VistaTestDataFactory.createKeyInfluencer(4,'Legal',newOpp.Id);
            keyPlayerList[0].Name__c = contactList[0].Id;
            keyPlayerList[1].Name__c = contactList[1].Id;
            keyPlayerList[2].Name__c = contactList[2].Id;
            keyPlayerList[3].Name__c = contactList[3].Id;
            insert keyPlayerList;

            Test.startTest();
                delete keyPlayerList;

                List<OpportunityContactRole> contactRoleList = new List<OpportunityContactRole>([SELECT Id FROM OpportunityContactRole WHERE Role = 'Legal']);

                System.assert(contactRoleList.size()==0);

            Test.stopTest();
        }
    }

    @IsTest
    static void testNumberOfUniqueDepartments() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contact productContact = TestDataFactory.createContact(account.Id, 'Contact1', 'testcontact1@address.com');
        insert productContact;
        final Contact salesContact = TestDataFactory.createContact(account.Id, 'Contact2', 'testcontact2@address.com');
        insert salesContact;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 1);
        insert opportunity;
        final Key_Players_Influencers__c firstRecord = new Key_Players_Influencers__c(
                Opportunity__c = opportunity.Id,
                Formal_Role__c = 'Product',
                Name__c = productContact.Id
        );
        insert firstRecord;
        final Key_Players_Influencers__c secondRecord = new Key_Players_Influencers__c(
                Opportunity__c = opportunity.Id,
                Formal_Role__c = 'Sales',
                Name__c = salesContact.Id
        );
        insert secondRecord;
        System.assertEquals(2, findNumberOfUniqueDepartments(opportunity.Id));
        secondRecord.Formal_Role__c = 'Product';
        update secondRecord;
        System.assertEquals(1, findNumberOfUniqueDepartments(opportunity.Id));
        delete firstRecord;
        System.assertEquals(1, findNumberOfUniqueDepartments(opportunity.Id));
        delete secondRecord;
        System.assertEquals(0, findNumberOfUniqueDepartments(opportunity.Id));
    }

    @IsTest
    static void testMasterOpportunityDeletion() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final Contact contact = TestDataFactory.createContact(account.Id);
        insert contact;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 1);
        insert opportunity;
        insert new Key_Players_Influencers__c(
                Opportunity__c = opportunity.Id,
                Formal_Role__c = 'Product',
                Name__c = contact.Id
        );
        delete opportunity;
    }

    private static Decimal findNumberOfUniqueDepartments(final Id opportunityId) {
        return [
                SELECT Unique_Departments_in_Buyer_Map__c
                FROM Opportunity
                WHERE Id = :opportunityId
        ].Unique_Departments_in_Buyer_Map__c;
    }
}
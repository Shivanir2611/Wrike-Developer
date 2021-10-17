/*
 * Created by andrey.kuleshov on 18/06/2019.
 */
@IsTest
public class VistaTestDataFactory {

	/* -----------------------------Test Data for Users--------------------------*/

	public static User createInternalSysAdminUser(String email, String lastName, String userName, String nickName){

		Profile sysAdminProf = [SELECT Id FROM Profile WHERE Name='System Administrator'];

		User internalUser = new User(Alias = nickName, Email=email,
				EmailEncodingKey='UTF-8', LastName=lastName, LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = sysAdminProf.Id,isActive=true,
				TimeZoneSidKey='America/Los_Angeles', UserName=userName);

		return internalUser;
	}

	/* -----------------------------Set Record Types and Business Hours--------------------------*/

	public static Id getRecordTypeId(String recordTypeDevName, String objectName){

		RecordType recType = [SELECT Id FROM RecordType WHERE sObjectType =:objectName AND DeveloperName = :recordtypeDevName];

		return recType.Id;
	}

	/* -----------------------------Test Data for Custom Settings--------------------------*/
	public static void caseFieldsSetting(){
		/*List<Case_Fields__c> caseFields = new List<Case_Fields__c>();

		caseFields.add(new Case_Fields__c(Name = 'Account',Field_Api_Name__c = 'AccountId'));
		caseFields.add(new Case_Fields__c(Name = 'Origin',Field_Api_Name__c = 'Origin'));
		caseFields.add(new Case_Fields__c(Name = 'Customer Escalation',Field_Api_Name__c = 'Customer_Escalated__c'));
		caseFields.add(new Case_Fields__c(Name = 'Priority',Field_Api_Name__c = 'Priority'));
		caseFields.add(new Case_Fields__c(Name = 'Severity',Field_Api_Name__c = 'Severity__c'));

		insert caseFields;*/
	}

	/* -----------------------------Test Data for Multiple Records--------------------------*/

	public static List<Account> createAcctList(Integer noOfAccts, String acctName){

		List<Account> acctList = new List<Account>();

		for(Integer i=1;i<=noOfAccts;i++){
			acctList.add(new Account(Name = acctName +'i', BillingCountry = 'United States',
					ShippingCountry = 'United States'));
		}

		return acctList;

	}

	public static List<Contact> createConList(Integer noOfCons, String lastName){
		List<Contact> conList = new List<Contact>();

		for(Integer i=1;i<=noOfCons;i++){
			conList.add(new Contact(LastName = lastName +'i'));
		}

		return conList;
	}

	public static List<Key_Players_Influencers__c> createKeyInfluencer(Integer noOfKeys,String formalRole, Id opportunityId){
		List<Key_Players_Influencers__c> keyList = new List<Key_Players_Influencers__c>();

		for(Integer i=1;i<=noOfKeys;i++){
			keyList.add(new Key_Players_Influencers__c(Formal_Role__c=formalRole,Opportunity__c=opportunityId));
		}

		return keyList;
	}
}
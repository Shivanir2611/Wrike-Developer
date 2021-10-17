@IsTest
public class CAPdbServiceTest {

	@IsTest
	static void testCreateNewContact() {
		final Account testAccount = TestDataFactory.createAccount();
		TestUtils.insertAndAssert(testAccount);
		final String testEmail = 'pipeline@test.com';

		setRequest('{' +
			'"data": [' +
				'{' +
					'"title": "Test Manager",' +
					'"firstName": "John",' +
					'"lastName": "Doe",' +
					'"phone": "00000001",' +
					'"email": "' +  testEmail + '",' +
					'"accountId": "' + testAccount.Id + '"' +
				'}' +
			']' +
		'}');
		CAPdbService.CreateResponse response = CAPdbService.createContacts();
		System.assertEquals(null, response.error);
		Map<String, CAPdbService.CreateResult> results = response.results;
		System.assertNotEquals(null, results);
		System.assertEquals(1, results.size());
		System.assertEquals(testEmail, results.get(testEmail).email);
		System.assertEquals('success', results.get(testEmail).status);
		System.assertEquals(null, results.get(testEmail).duplicateType);
		System.assertNotEquals(null, results.get(testEmail).Id);
	}

	@IsTest
	static void testCreateWithDuplicateContact() {
		final Account testAccount = TestDataFactory.createAccount();
		TestUtils.insertAndAssert(testAccount);
		final String testEmail = 'pipeline@test.com';
		final Contact testContact = TestDataFactory.createContact(testAccount.Id, 'Test', testEmail);
		TestUtils.insertAndAssert(testContact);

		setRequest('{' +
			'"data": [' +
				'{' +
					'"title": "Test Manager",' +
					'"firstName": "John",' +
					'"lastName": "Doe",' +
					'"phone": "00000001",' +
					'"email": "' +  testEmail + '",' +
					'"accountId": "' + testAccount.Id + '"' +
				'}' +
			']' +
		'}');
		CAPdbService.CreateResponse response = CAPdbService.createContacts();
		System.assertEquals(null, response.error);
		Map<String, CAPdbService.CreateResult> results = response.results;
		System.assertNotEquals(null, results);
		System.assertEquals(1, results.size());
		System.assertEquals(testEmail, results.get(testEmail).email);
		System.assertEquals('duplicate', results.get(testEmail).status);
		System.assertEquals('contact', results.get(testEmail).duplicateType);
		System.assertEquals(testContact.Id, results.get(testEmail).Id);
	}

	@IsTest
	static void testCreateWithDuplicateLead() {
		final Account testAccount = TestDataFactory.createAccount();
		TestUtils.insertAndAssert(testAccount);
		final String testEmail = 'pipeline@test.com';
		final Lead testLead = TestDataFactory.createLead(null, testEmail);
		TestUtils.insertAndAssert(testLead);

		setRequest('{' +
			'"data": [' +
				'{' +
					'"title": "Test Manager",' +
					'"firstName": "John",' +
					'"lastName": "Doe",' +
					'"phone": "00000001",' +
					'"email": "' +  testEmail + '",' +
					'"accountId": "' + testAccount.Id + '"' +
				'}' +
			']' +
		'}');
		CAPdbService.CreateResponse response = CAPdbService.createContacts();
		System.assertEquals(null, response.error);
		Map<String, CAPdbService.CreateResult> results = response.results;
		System.assertNotEquals(null, results);
		System.assertEquals(1, results.size());
		System.assertEquals(testEmail, results.get(testEmail).email);
		System.assertEquals('duplicate', results.get(testEmail).status);
		System.assertEquals('lead', results.get(testEmail).duplicateType);
		System.assertEquals(testLead.Id, results.get(testEmail).Id);
	}


	@IsTest
	static void testCreateInvalidContacts() {
		final Account testAccount = TestDataFactory.createAccount();
		TestUtils.insertAndAssert(testAccount);

		setRequest('{' +
			'"data": [' +
				'{' +
					'"title": "Empty last name (mandatory)",' +
					'"email": "pipeline@test.com",' +
					'"accountId": "' + testAccount.Id + '"' +
				'},' +
				'{' +
					'"title": "Field too long",' +
					'"lastName": "Test",' +
					'"phone": "01234567890123456789012345678901234567890123456789",' +
					'"email": "pipeline2@test.com",' +
					'"accountId": "' + testAccount.Id + '"' +
				'},' +
				'{' +
					'"title": "Empty account Id",' +
					'"lastName": "Test",' +
					'"email": "pipeline3@test.com"' +
				'},' +
				'{' +
					'"title": "Empty Email",' +
					'"lastName": "Test",' +
					'"email": "",' +
					'"accountId": "' + testAccount.Id + '"' +
				'},' +
				'{' +
					'"title": "Invalid email",' +
					'"lastName": "Test",' +
					'"email": "pipeline5@test@.com",' +
					'"accountId": "' + testAccount.Id + '"' +
				'}' +
			']' +
		'}');
		CAPdbService.CreateResponse response = CAPdbService.createContacts();
		System.assertEquals(null, response.error);
		Map<String, CAPdbService.CreateResult> results = response.results;
		System.assertNotEquals(null, results);
		System.assertEquals(5, results.size());
		System.assertEquals('success', results.get('pipeline@test.com').status);
		System.assertEquals('success', results.get('pipeline2@test.com').status);
		System.assertEquals('error', results.get('pipeline3@test.com').status);
		System.assertEquals('error', results.get('').status);
		System.assertEquals('error', results.get('pipeline5@test@.com').status);
	}

	@IsTest
	static void testCreateWithError() {
		setRequest('{' +
			'"data": [' +
				'{' +
					'"title": "Test Manager",' +
					'"firstName": "John",' +
					'"lastName": "Doe",' +
					'"phone": "00000001",' +
					'"email": "pipeline@test.com",' +
					'"accountId": "qwerty"' +
				'}' +
			']' +
		'}');
		CAPdbService.CreateResponse response = CAPdbService.createContacts();
		System.assertNotEquals(null, response.error);
		System.assertEquals(null, response.results);
	}

	private static void setRequest(final String body) {
		final RestRequest request = new RestRequest();
		request.requestUri ='/services/apexrest/capdb/createContacts';
		request.httpMethod = 'POST';
		request.requestBody = Blob.valueOf(body);
		RestContext.request = request;
	}
}
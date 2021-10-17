@RestResource(urlMapping='/capdb/*')
global with sharing class CAPdbService {

	private static final Logger log = Logger.create(CAPdbService.class);

	@HttpPost
	global static CreateResponse createContacts() {
		try {
			if(RestContext.request.requestBody == null) {
				return new CreateResponse();
			}
			CreateRequest request = (CreateRequest)
					JSON.deserialize(RestContext.request.requestBody.toString(), CreateRequest.class);
			if (request.data == null) {
				return new CreateResponse();
			}
			if(request.data.size() > 100) {
				return new CreateResponse('Too many records. A maximum of 100 records per request is allowed.');
			}
			return findOrCreateContacts(request.data);
		} catch (Exception e) {
			log.error(e.getMessage(), e.getStackTraceString());
			return new CreateResponse(e.getTypeName());
		}
	}

	private static CreateResponse findOrCreateContacts(final List<CAPdbContact> records) {
		final Map<String, CreateResult> results = new Map<String, CreateResult>();
		final List<String> emails = new List<String>();
		for(CAPdbContact record : records) {
			if(String.isNotBlank(record.email) && String.isNotBlank(record.accountId)) {
				emails.add(record.email.trim());
			}
		}
		final Map<String, String> existingContactsMap = getExistingContactsMap(emails);
		final Map<String, String> existingLeadsMap = getExistingLeadsMap(emails);
		final List<Contact> newContacts = new List<Contact>();
		for(CAPdbContact record : records) {
			if(String.isNotBlank(record.email) && String.isNotBlank(record.accountId)) {
				final String existingContactId = existingContactsMap.get(record.email.toLowerCase());
				final String existingLeadId = existingLeadsMap.get(record.email.toLowerCase());
				if (existingContactId != null) {
					results.put(record.email, getDuplicateResult(record.email, existingContactId, 'contact'));
				} else if (existingLeadId != null) {
					results.put(record.email, getDuplicateResult(record.email, existingLeadId, 'lead'));
				} else {
					newContacts.add(createContact(record));
				}
			} else {
				results.put(record.email, getErrorResult(record.email, 'Invalid record'));
			}
		}
		final List<Database.SaveResult> saveResults = Database.insert(newContacts, false);
		for(Integer i = 0; i < saveResults.size(); i++) {
			final Database.SaveResult saveResult = saveResults.get(i);
			final Contact newContact = newContacts.get(i);
			if (saveResult.isSuccess()) {
				results.put(newContact.Email, getSuccessfulResult(newContact.Email, saveResult.getId()));
			} else {
				results.put(newContact.Email, getErrorResult(newContact.Email, stringifyErrors(saveResult.getErrors())));
			}
		}
		return new CreateResponse(results);
	}

	private static Map<String, String> getExistingContactsMap(final List<String> emails) {
		final Map<String, String> existingContactsMap = new Map<String, String>();
		final List<Contact> existingContacts = [
				SELECT Id, Email
				FROM Contact
				WHERE Email IN :emails
				ORDER BY CreatedDate DESC
		];
		for(Contact c : existingContacts) {
			existingContactsMap.put(c.Email.toLowerCase(), c.Id);
		}
		return existingContactsMap;
	}

	private static Map<String, String> getExistingLeadsMap(final List<String> emails) {
		final Map<String, String> existingLeadsMap = new Map<String, String>();
		final List<Lead> existingLeads = [
				SELECT Id, Email
				FROM Lead
				WHERE Email IN :emails
				AND IsConverted = FALSE
				ORDER BY CreatedDate DESC
		];
		for(Lead l : existingLeads) {
			existingLeadsMap.put(l.Email.toLowerCase(), l.Id);
		}
		return existingLeadsMap;
	}

	private static Contact createContact(final CAPdbContact record) {
		return new Contact(
				FirstName = StringUtils.getEmptyIfNull(record.firstName).left(40),
				LastName = StringUtils.defaultIfBlank(record.lastName, '-').left(80),
				Title = StringUtils.getEmptyIfNull(record.title).left(128),
				Email = record.email.left(80),
				Phone = StringUtils.getEmptyIfNull(record.phone).left(40),
				AccountId = record.accountId,
				Sync_to_Marketo__c = false
		);
	}

	private static CreateResult getSuccessfulResult(final String email, final String contactId) {
		final CreateResult createResult = new CreateResult();
		createResult.email = email;
		createResult.status = 'success';
		createResult.Id = contactId;
		return createResult;
	}

	private static CreateResult getDuplicateResult(final String email, final String duplicateId, final String duplicateType) {
		final CreateResult createResult = new CreateResult();
		createResult.email = email;
		createResult.status = 'duplicate';
		createResult.Id = duplicateId;
		createResult.duplicateType = duplicateType;
		return createResult;
	}

	private static CreateResult getErrorResult(final String email, final String error) {
		final CreateResult createResult = new CreateResult();
		createResult.email = email;
		createResult.status = 'error';
		createResult.error = error;
		return createResult;
	}

	private static String stringifyErrors(List<Database.Error> errors) {
		if(errors == null) {
			return '';
		}
		final List<String> messages = new List<String>();
		for(Database.Error error : errors) {
			messages.add(error.getMessage());
		}
		return String.join(messages, ', ');
	}

	public class CreateRequest {
		public List<CAPdbContact> data { get; set;}
	}

	public class CAPdbContact {
		public String title { get; set; }
		public String firstName { get; set; }
		public String lastName { get; set; }
		public String email { get; set; }
		public String phone { get; set; }
		public String accountId { get; set; }
	}

	global class CreateResponse {
		public String error { get; set; }
		public Map<String, CreateResult> results;

		public CreateResponse() {}

		public CreateResponse(final String error) {
			this.error = error;
		}

		public CreateResponse(final Map<String, CreateResult> results) {
			this.results = results;
		}
	}

	public class CreateResult {
		public String email { get; set; }
		public String error { get; set; }
		public String status { get; set; }
		public String duplicateType { get; set; }
		public String Id { get; set; }
	}
}
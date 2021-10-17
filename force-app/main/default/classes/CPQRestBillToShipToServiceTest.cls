@IsTest
public class CPQRestBillToShipToServiceTest {

    @IsTest
    static void testUnknownAction() {
        setRequest('unknownAction', '{}');
        CPQRestService.processRequest();
        final RestHandlerService.RestResponseData response = getResponse();
        System.assertEquals(false, response.getSuccess());
        System.assertNotEquals(null, response.getError());
        System.assert(response.getError().startsWith('Unknown handler action'));
    }

    @IsTest
    static void testInvalidListBillToRequest() {
        setRequest('listBillingInfo', '{}');
        CPQRestService.processRequest();
        final RestHandlerService.RestResponseData response = getResponse();
        System.assertEquals(false, response.getSuccess());
        System.assertEquals('Invalid Wrike Account ID.', response.getError());
    }

    @IsTest
    static void testListBillToRequest() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
                QS_Bill_To__c = true,
                QS_Email__c = 'test@email.com',
                Wrike_Account_ID__c = 12345,
                QS_Account__c = account.Id
        );
        insert billTo;
        final Contract contract = new Contract(
                Status = 'Draft',
                QS_Bill_To__c = billTo.Id,
                Wrike_Account_ID__c = 12345,
                AccountId = account.Id
        );
        insert contract;
        contract.Status = 'Activated';
        update contract;
        setRequest('listBillingInfo', '{"wrikeAccountId": 12345}');
        CPQRestService.processRequest();
        final String response = RestContext.response.responseBody.toString();
        System.assert(response.contains('"email":"test@email.com"'));
    }

    @IsTest
    static void testUpdateBillToRequest() {
        final Account account = TestDataFactory.createAccount();
        insert account;
        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
            QS_Account__c = account.Id,
            QS_Bill_To__c = true,
            QS_Email__c = 'test@email.com',
            Wrike_Account_ID__c = 12345
        );
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = new QS_Bill_To_Ship_To__c(
            QS_Account__c = account.Id,
            QS_Ship_To__c = true,
            QS_Email__c = 'test@email.com',
            Wrike_Account_ID__c = 12345
        );
        insert shipTo;
        final Contract contract = new Contract(
            Status = 'Draft',
            QS_Bill_To__c = billTo.Id,
            QS_Ship_To__c = shipTo.Id,
            Wrike_Account_ID__c = 12345,
            AccountId = account.Id
        );
        insert contract;
        contract.Status = 'Activated';
        update contract;
        setRequest('updateBillingInfo', '{' +
                '"wrikeAccountId": 12345,' +
                '"billingInfo" : {' +
                '"countryCode": "US", ' +
                '"stateCode": "CA", ' +
                '"userName": "Test User", ' +
                '"email": "updated.test@email.com" ' +
                '}}');
        CPQRestService.processRequest();
        //final CPQHandlersBillToShipToService.CPQHandlerResponse response = getResponse();
        //System.assertEquals(true, response.getSuccess(), response.getError());
        final QS_Bill_To_Ship_To__c updatedBillTo = findBillToById(billTo.Id);
        System.assertEquals('updated.test@email.com', updatedBillTo.QS_Email__c);
    }

    private static void setRequest(final String action, final String body) {
        final RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/cpq/billToShipTo/' + action;
        request.httpMethod = 'POST';
        if(String.isNotBlank(body)) {
            request.requestBody = Blob.valueOf(body);
        }
        RestContext.request = request;
        RestContext.response = new RestResponse();
    }

    private static RestHandlerService.RestResponseData getResponse() {
        return (RestHandlerService.RestResponseData)JSON.deserialize(
                RestContext.response.responseBody.toString(),
                        RestHandlerService.RestResponseData.class);
    }

    private static QS_Bill_To_Ship_To__c findBillToById(final Id billToId) {
        return [
                SELECT Id, QS_Email__c
                FROM QS_Bill_To_Ship_To__c
                WHERE Id = :billToId
        ];
    }
}
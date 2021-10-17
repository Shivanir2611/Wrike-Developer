public class WrikeHttpMock implements HttpCalloutMock {

    private static final Map<String, Integer> actionNameToCount = new Map<String, Integer>();

    public HttpResponse respond(System.HttpRequest request) {

        String responseBody = '';

        String decodedBody = EncodingUtil.urlDecode(request.getBody().substring(5), 'UTF-8');
        String decryptedBody = WrikeUtil.decrypt(decodedBody);
        List<String> bodyParts = decryptedBody.split(',');
        String requestBodySerialized = EncodingUtil.base64Decode(bodyParts.get(2)).toString();
        Map<String, String> requestBodyParams = (Map<String, String>)JSON.deserialize(requestBodySerialized, Map<String, String>.class);

        String actionName = requestBodyParams.get('action');
        trackAction(actionName);
        if (actionName == 'check_account_id') {
            responseBody = '{"success":true,"async":false,"data":{"account":{"name":"Test Team",' +
                '"trial":false,"deleted":false,"confirmed":true,"owner":"Test","license":"Ent.2014/  50 users",' +
                '"free":false,"paid":false,"ableToMigrate":false}}}';

            responseBody = '{"success":true,"async":false,"data":{"name":"Test Team","trial":false,' +
                '"deleted":false,"confirmed":true,"owner":"Test","license":"Zuora Base License","free":false,"paid":true}}';
        } else if (actionName == 'new_quote') {
            responseBody = '{"success":true,"async":false,"data":{"zuoraAccountId":"zuoraAccountId1","dataCenter":"US"}}';
        } else if (actionName == 'delete_quotes') {
            responseBody = '{"success":true,"async":false,"data":{}}';
        } else if (actionName == 'accepted_quote') {
            responseBody = '{"success":true,"async":false,"data":{"success":true}}';
        } else if (actionName == 'generated_quote') {
            responseBody = '{"success":true,"async":false,"data":{}}';
        } else if (actionName == 'register_new_account') {
            responseBody = '{"success":true,"async":false,"data":{"wrikeAccountId":123}}';
        } else if (actionName == 'find_accounts') {
            responseBody = '{"success":true,"async":false,"data":{"userAccountInfoList":[{"accountId":123}]}}';
        }

        HttpResponse response = new HttpResponse();
        response.setBody(responseBody);
        return response;
    }

    public static void assertNumberOfActionInvocation(final String actionName, final Integer count) {
        System.assertEquals(count, actionNameToCount.get(actionName), 'Number of action invocation mismatch');
    }

    private void trackAction(final String actionName) {
        if (String.isBlank(actionName)) {
            return;
        }
        Integer count = actionNameToCount.get(actionName);
        if (count == null) {
            actionNameToCount.put(actionName, 1);
        } else {
            actionNameToCount.put(actionName, count++);
        }
    }
}
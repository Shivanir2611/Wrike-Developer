public class ZuoraRestApi {

    public static ZuoraRestApi getInstance() {
        return (ZuoraRestApi)ServiceLocator.getInstance(ZuoraRestApi.class);
    }

    public ZuoraRestRequest createGetRequest(final String relativePath) {
        return new ZuoraRestRequest(relativePath, HttpMethod.GET);
    }

    public ZuoraRestRequest createPostRequest(final String relativePath) {
        return new ZuoraRestRequest(relativePath, HttpMethod.POST);
    }

    public List<Object> query(final String queryString, final Type recordsListType) {

        final String listTypeName = recordsListType.getName();
        final Type objectType = Type.forName(listTypeName.substringBetween('List<', '>'));
        final ZuoraObject objectInstance = (ZuoraObject)objectType.newInstance();
        final Map<String, String> fieldReplaceMap = objectInstance.getFieldReplaceMap();

        final JsonApi.Parser responseParser = JsonApi.parseFields()
                .field('records', recordsListType).required()
                .field('done', Boolean.class).required()
                .field('queryLocator', String.class)
                .parser();

        Map<String, Object> queryResult = (Map<String, Object>)createPostRequest('/v1/action/query')
                .setRequestBody(JSON.serialize(new Map<String, String> {
        'queryString' => queryString
        }))
                .setResponseParser(responseParser)
                .setFieldReplaceMap(fieldReplaceMap)
                .execute();

        final List<Object> records = (List<Object>)queryResult.get('records');
        while (queryResult.get('done') != true) {
            final String queryLocator = (String)queryResult.get('queryLocator');
            queryResult = (Map<String, Object>)(Map<String, Object>)createPostRequest('/v1/action/queryMore')
                    .setRequestBody(JSON.serialize(new Map<String, String> {
            'queryLocator' => queryLocator
            }))
                    .setResponseParser(responseParser)
                    .execute();
            records.addAll((List<Object>)queryResult.get('records'));
        }
        return records;
    }

    private List<Map<String, Object>> sendObjects(final List<Map<String, Object>> objectList, final String type, final String relativePath) {
        final JsonApi.Parser responseParser = JsonApi.parseList()
                .field('Success', Boolean.class).requiredValue(true)
                .field('Id', String.class).required()
                .parser();
        List<Map<String, Object>> res = (List<Map<String, Object>>)createPostRequest(relativePath)
                .setRequestBody(JSON.serialize(new Map<String, Object> {
        'objects' => objectList,
        'type' => type
        }, true))
                .setResponseParser(responseParser)
                .execute();

        return res;
    }

    public String createObject(final ZuoraObject objectToCreate, final String type) {
        final Map<String, Object> fieldValueMap = objectToCreate.getFieldValueMap();
        return (String)createObjects(new List<Map<String, Object>>{fieldValueMap}, type).get(0).get('Id');
    }

    private List<Map<String, Object>> createObjects(final List<Map<String, Object>> objectList, final String type) {
        return sendObjects(objectList, type, '/v1/action/create');
    }

    public String updateObject(final ZuoraObject objectToUpdate, final String type) {
        final Map<String, Object> fieldValueMap = objectToUpdate.getFieldValueMap();
        return (String)updateObjects(new List<Map<String, Object>>{fieldValueMap}, type).get(0).get('Id');
    }

    private List<Map<String, Object>> updateObjects(final List<Map<String, Object>> objectList, final String type) {
        return sendObjects(objectList, type, '/v1/action/update');
    }

    public Map<String, Object> generate(final ZuoraObject objectToGenerate) {
        final JsonApi.Parser responseParser = JsonApi.parseList()
                .field('Success', Boolean.class).required()
                .field('Id', String.class).required()
                .parser();

        final Map<String, Object> fieldValueMap = objectToGenerate.getFieldValueMap();

        List<Map<String, Object>> res = (List<Map<String, Object>>)createPostRequest('/v1/action/generate')
                .setRequestBody(JSON.serialize(new Map<String, Object> {
            'objects' => new List<Map<String, Object>>{fieldValueMap},
            'type' => 'Invoice'
        }, true))
                .setResponseParser(responseParser)
                .execute();

        return res.get(0);
    }


    public class ZuoraApiException extends Exception { }

    public class ZuoraRestRequest {
        private final String relativePath;
        private final String httpMethod;
        private Map<String, String> parameters;
        private String requestBody;
        private JsonApi.Parser responseParser;
        private Map<String, String> fieldReplaceMap;

        public ZuoraRestRequest(final String relativePath, final String httpMethod) {
            this.relativePath = relativePath;
            this.httpMethod = httpMethod;
        }

        public ZuoraRestRequest setParameters(final Map<String, String> parameters) {
            this.parameters = parameters;
            return this;
        }

        public ZuoraRestRequest setRequestBody(final String requestBody) {
            this.requestBody = requestBody;
            return this;
        }

        public ZuoraRestRequest setResponseParser(final JsonApi.Parser responseParser) {
            this.responseParser = responseParser;
            return this;
        }

        public ZuoraRestRequest setFieldReplaceMap(final Map<String, String> fieldReplaceMap) {
            this.fieldReplaceMap = fieldReplaceMap;
            return this;
        }

        public Object execute() {
            final String existingToken = CacheService.getInstance().getZuoraToken();

            HttpResponse response = executeRequest(existingToken);

            if (response.getStatusCode() == 401) {
                response = executeRequest(null);
            }
            if (response.getStatusCode() == 200) {
                String responseBody = response.getBody();

                if (responseBody != null && fieldReplaceMap != null) {
                    for (String replacement : fieldReplaceMap.keySet()) {
                        final String valueToReplace = '"' + fieldReplaceMap.get(replacement) + '":';
                        replacement = '"' + replacement + '":';
                        responseBody = responseBody.replaceAll(valueToReplace, replacement);
                    }
                }
                return responseParser.parse(responseBody);
            }
            throw new ZuoraApiException(response.getStatusCode() + ':\n' + response.getBody());
        }

        private HttpResponse executeRequest(final String existingToken) {
            final String token = existingToken == null ? getOAuthToken() : existingToken;

            final PageReference reference = new PageReference('callout:ZuoraRestOAuth' + relativePath);
            if (parameters != null) {
                reference.getParameters().putAll(parameters);
            }

            final HttpRequest request = new HttpRequest();
            request.setEndpoint(reference.getUrl());
            if (requestBody != null) {
                request.setBody(requestBody);
            }
            request.setTimeout(120000);
            request.setMethod(httpMethod);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + token);

            return new Http().send(request);
        }

        private String getOAuthToken() {
            final HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:ZuoraRestOAuth/oauth/token');
            request.setBody('client_id={!$Credential.Username}&client_secret={!$Credential.Password}&grant_type=client_credentials');
            request.setMethod(httpMethod);
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            final HttpResponse response = new Http().send(request);

            final String token = (String)JsonApi.parseField('access_token', String.class)
                    .required()
                    .parser()
                    .parse(response.getBody());
            CacheService.getInstance().putZuoraToken(token);

            return token;
        }
    }
}
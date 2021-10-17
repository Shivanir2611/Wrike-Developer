public abstract class RestHandlerService {

    protected abstract Map<String, RestHandler> getHandlerMap();

    public RestResponseData handleRequest(final String action, final RestRequest request) {
        final RestHandler handler = getHandlerMap().get(action);
        if(handler == null) {
            return failed('Unknown handler action: ' + action);
        }
        try {
            final Object requestData = JSON.deserialize(
                    request.requestBody.toString(),
                    handler.getRequestType()
            );
            if(requestData == null) {
                return failed('Failed to parse request data.');
            }
            return handler.processRequest(requestData);
        } catch (JSONException e) {
            return failed('Failed to parse request data: ' + e.getMessage());
        }
    }

    public interface RestHandler {

        Type getRequestType();

        RestResponseData processRequest(final Object requestData);
    }

    public class RestResponseData {
        private final Boolean success;
        private final String error;
        private final Object data;

        public RestResponseData(final Boolean success, final String error, final Object data) {
            this.success = success;
            this.error = error;
            this.data = data;
        }

        public Boolean getSuccess() {
            return success;
        }

        public String getError() {
            return error;
        }

        public Object getData() {
            return data;
        }
    }

    public static RestResponseData failed(final String message) {
        return new RestResponseData(false, message, null);
    }

    public static RestResponseData success(final Object responseData) {
        return new RestResponseData(true, null, responseData);
    }
}
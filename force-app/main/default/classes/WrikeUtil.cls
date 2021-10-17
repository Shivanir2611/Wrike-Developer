/*
    @author Andrey Kuleshov
*/
public class WrikeUtil {

    private static final Logger log = Logger.create(WrikeUtil.class);

    public static String encrypt(final String data) {
        final Blob key = EncodingUtil.base64Decode(Settings__c.getInstance().Wrike_Key__c);
        final Blob cipherText = Crypto.encryptWithManagedIV('AES128', key, Blob.valueOf(data));
        return EncodingUtil.base64Encode(cipherText);
    }
    
    public static String encryptAndEncode(final String data) {
        return EncodingUtil.urlEncode(encrypt(data), 'UTF-8');
    }
    
    public static String getEncryptedData(final Decimal wrikeAccountId, final Map<String, String> params) {
        return encryptAndEncode(UserInfo.getUserEmail() + ',' + wrikeAccountId + ',' + 
            EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(params != null ? params : new Map<String, String>()))));
    }
    
    public static String decrypt(final String data) {
        if(data == null) {
            return null;
        }
        final Blob key = EncodingUtil.base64Decode(Settings__c.getInstance().Wrike_Key__c);
        try {
            return Crypto.decryptWithManagedIV('AES128', key, EncodingUtil.base64Decode(data)).toString();
        } catch (Exception e) {
            return null;
        }
    }
    
    public static Id getDecryptedId(final String encryptedId) {
        final String idValue = decrypt(encryptedId);
        if(String.isBlank(idValue)) {
            return null;
        }
        try {
            return Id.valueOf(idValue);
        } catch(Exception e) {
            return null;
        }
    }

    public static void acceptQuote(final Decimal wrikeAccountId, final Id quoteId) {
        sendWrikeRequest(wrikeAccountId, new Map<String, String> {'action' => 'accepted_quote', 'quoteId' => quoteId});    
    }

    public static WrikeResponse acceptQuoteById(final Decimal wrikeAccountId, final Id quoteId) {
        return sendRequestToWrike(wrikeAccountId, new Map<String, String> {
            'action' => 'accepted_quote',
            'quoteId' => quoteId
        });
    }

    public static Boolean sendQuoteToWrike(final QuoteUtil.QuoteWrapper quote) {
        try {
            final Map<String, Object> response = sendWrikeRequest(quote.wrikeAccountId, new Map<String, String> {
                'action' => 'generated_quote',
                'json' => EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(quote)))
            });
            return isSuccessResponse(response);
        } catch (Exception e) {
            return false;
        }
    }
    
    @future(callout=true)
    public static void deleteQuotes(final List<String> quoteIds) {
        if(!quoteIds.isEmpty()) {
            sendWrikeRequest(0, new Map<String, String> {'action' => 'delete_quotes', 'quoteIds' => String.join(quoteIds, ',')});
        }
    }

    public static WrikeResponse deleteQuotesByIds(final List<String> quoteIds) {
        if (!quoteIds.isEmpty()) {
            return sendRequestToWrike(0, new Map<String, String> {
                'action' => 'delete_quotes',
                'quoteIds' => String.join(quoteIds, ',')
            });
        }
        return new WrikeResponse(true);
    }

    public static Map<String, Object> getQuoteStatuses(final Set<String> quoteIds) {
        final Map<String, Object> response = sendWrikeRequest(0, new Map<String, String> {
            'action' => 'list_quote_statuses', 
            'quoteIds' => String.join(new List<String> (quoteIds), ',')});
        final Map<String, String> statusMap = new Map<String, String>();
        for(String quoteId : quoteIds) {
            final String quoteStatus = (String)(response.get(quoteId));
            statusMap.put(quoteId, quoteStatus != null ? quoteStatus : '');
        }
        return statusMap;
    }
    
    public static Map<String, Object> findAccountInfo(final Decimal wrikeAccountId) {
        final Map<String, Object> response = sendWrikeRequest(wrikeAccountId, new Map<String, String> {'action' => 'check_account_id'});
        return response.containsKey('account') ? (Map<String, Object>)response.get('account') : response;
    }
    
    public static Map<String, Object> checkDemoAccount() {
        final Map<String, Object> response = sendWrikeRequest(0, new Map<String, String> {'action' => 'check_demo_account'});
        return response.containsKey('account') ? (Map<String, Object>)response.get('account') : response;
    }
    
    public static void resetDemoAccount() {
        sendWrikeRequest(0, new Map<String, String> {'action' => 'reset_demo_account'});
    }
    
    public static Map<String, Object> sendWrikeRequest(final Decimal wrikeAccountId, final Map<String, String> params) {
        final HttpRequest req = new HttpRequest();
        req.setEndpoint(SettingsProvider.getWrikeUrl() + 'gw/salesforce/webhook');
        req.setMethod('POST');
        req.setBody('data=' + getEncryptedData(wrikeAccountId, params));  
        try {
            final String response = new Http().send(req).getBody();
            final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
            return (Map<String,Object>)responseMap.get('data');
        } catch (Exception e) {
            ExceptionUtil.sendErrorNotification(e);
            return new Map<String, String>();
        }
    }

    public static WrikeResponse sendRequestToWrike(final Decimal wrikeAccountId, final Map<String, String> params) {
        final HttpRequest request = new HttpRequest();
        request.setEndpoint(SettingsProvider.getWrikeUrl() + 'gw/salesforce/webhook');
        request.setMethod('POST');
        request.setBody('data=' + getEncryptedData(wrikeAccountId, params));
        try {
            final HttpResponse response = new Http().send(request);
            log.infoToLog('Wrike WebHook Invocation', JSON.serialize(new Map<String, Object>{
                'wrikeAccountId' => wrikeAccountId,
                'params' => params,
                'status' => response.getStatus(),
                'body' => response.getBody()
            }));
            return new WrikeResponse(response);
        } catch (Exception e) {
            ExceptionUtil.sendErrorNotification(e);
            log.infoToLog('Wrike WebHook Invocation', JSON.serialize(new Map<String, Object>{
                'wrikeAccountId' => wrikeAccountId,
                'params' => params,
                'errorMessage' => e.getMessage(),
                'stackTrace' => e.getStackTraceString()
            }));
            return new WrikeResponse(e.getMessage());
        }
    }
    
    private static Boolean isSuccessResponse(final Map<String, Object> response) {
        return response.get('success') != null && ((Boolean)response.get('success') == true);
    }

    public class WrikeResponse {

        private Boolean isSuccess;
        private String message;

        public WrikeResponse(final HttpResponse httpResponse) {
            this.isSuccess = httpResponse.getStatusCode() == 200;
            this.message = httpResponse.getBody();
        }

        public WrikeResponse(final String errorMessage) {
            this.isSuccess = false;
            this.message = errorMessage;
        }

        public WrikeResponse(final Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }

        public Boolean getIsSuccess() {
            return isSuccess;
        }

        public String getMessage() {
            return message;
        }
    }
}
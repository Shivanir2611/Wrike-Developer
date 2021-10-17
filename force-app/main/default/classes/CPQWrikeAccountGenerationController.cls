public class CPQWrikeAccountGenerationController {

    private final static CPQQuoteService quoteSrv = CPQQuoteService.getInstance();

    @AuraEnabled
    public static RegistrationResponse registerNewAccount(final Id quoteId, final String email) {
        if (String.isBlank(email)) {
            return new RegistrationResponse(false, 'Please populate all fields.');
        } else if (!EmailUtil.isValidEmail(email)) {
            return new RegistrationResponse(false, 'Please populate a valid email address.');
        }
        try {
            final CPQQuoteService.WrikeAccountRegistrationResult registrationResult = quoteSrv.registerNewWrikeAccount(email);
            if (registrationResult.getWrikeAccountId() == null) {
                return new RegistrationResponse(false, registrationResult.getMessage());
            }
            quoteSrv.setOutboundWrikeAccount(quoteId, registrationResult.getWrikeAccountId());
            return new RegistrationResponse(true, '');
        } catch (final LogicException e) {
            return new RegistrationResponse(false, e.getMessage());
        }
    }

    @AuraEnabled
    public static FindAccountsResponse findAccounts(final String email) {
        if (String.isBlank(email)) {
            return new FindAccountsResponse('Please populate an email.');
        } else if (!EmailUtil.isValidEmail(email)) {
            return new FindAccountsResponse('Please populate a valid email address.');
        }
        try {
            return new FindAccountsResponse(quoteSrv.findWrikeAccountsByEmail(email));
        } catch (final LogicException e) {
            return new FindAccountsResponse(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateQuoteWrikeAccountId(final Id quoteId, final Integer wrikeAccountId) {
        quoteSrv.setOutboundWrikeAccount(quoteId, wrikeAccountId);
    }

    public class RegistrationResponse {
        @AuraEnabled
        public Boolean success {get; set;}
        @AuraEnabled
        public String message {get; set;}

        RegistrationResponse(final Boolean success, final String message) {
            this.success = success;
            this.message = message;
        }
    }

    public class FindAccountsResponse {
        @AuraEnabled
        public Boolean success {get; set;}
        @AuraEnabled
        public String message {get; set;}
        @AuraEnabled
        public List<CPQQuoteService.WrikeAccountInfo> wrikeAccounts {get; set;}

        FindAccountsResponse(final String message) {
            this.success = false;
            this.message = message;
        }

        FindAccountsResponse(final List<CPQQuoteService.WrikeAccountInfo> wrikeAccounts) {
            this.success = true;
            this.wrikeAccounts = wrikeAccounts;
        }
    }
}
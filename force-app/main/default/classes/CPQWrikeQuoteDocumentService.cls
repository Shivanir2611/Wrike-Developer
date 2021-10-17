public class CPQWrikeQuoteDocumentService {

    public static CPQWrikeQuoteDocumentService getInstance() {
        return (CPQWrikeQuoteDocumentService)ServiceLocator.getInstance(CPQWrikeQuoteDocumentService.class);
    }

    public Boolean checkDocumentDeletionAllowed(final String documentType, final Id uploaderId) {
        return ProfileQueryService.getInstance().isAdminOrBillingProfile(UserInfo.getProfileId())
                || 'Quote-Manual'.equals(documentType)
                        && UserInfo.getUserId() == uploaderId;
    }
}
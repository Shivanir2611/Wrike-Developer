public class WrikeQuotePdfService {

    private final QuoteService quoteSrv = QuoteService.getInstance();
    private final WrikeQuoteZuoraService wrikeQuoteZuoraSrv = WrikeQuoteZuoraService.getInstance();
    private final DatabaseService databaseSrv = DatabaseService.getInstance();
    
    public static WrikeQuotePdfService getInstance() {
        return (WrikeQuotePdfService)ServiceLocator.getInstance(WrikeQuotePdfService.class);
    }
    
    public Id generateQuotePdf(final Id quoteId, final Boolean noListPrice) {
        final QuoteService.StatusLock statusLock = quoteSrv.getStatusLock(quoteId);
        System.assertEquals(WrikeQuote.Status.APPROVED.name(), statusLock.getStatus());

        final WrikeQuoteZuoraService.SubscriptionPreview preview = quoteSrv.getSavedSubscriptionPreview(quoteId);
        System.assert(preview != null, 'Invalid quote state, no preview found.');
        System.assert(preview.isSuccess(), 'The quote preview is not valid.');
        System.assert(preview.getInvoicePreview().totalChargeAmount >= 0, 'The quote charge amount is negative.');

        final WrikeQuote quote = quoteSrv.findWithItemsById(quoteId);

        final PageReference template = Page.wrikeQuotePdfTemplate;
        template.getParameters().put('quoteId', WrikeUtil.encrypt(quoteId));
        template.getParameters().put('noListPrice', String.valueOf(noListPrice));
        final Attachment pdf = new Attachment();
        final Blob body = template.getContent(); 
        pdf.Body = body;
        pdf.ContentType = 'application/pdf';
        pdf.Name = quote.name + '.pdf';
        pdf.IsPrivate = false;
        pdf.ParentId = quote.id;
        final Boolean result = databaseSrv.insertSObject(pdf);
        System.assert(result, 'Failed to save quote pdf.');

        quoteSrv.setProposal(statusLock, preview.getInvoicePreview(), pdf.Id);

        return pdf.Id;
    }
    
    public void deleteQuotePdf(final Id quoteId) {
        final QuoteService.StatusLock statusLock = quoteSrv.getStatusLock(quoteId);
        System.assertEquals(WrikeQuote.Status.PROPOSAL.name(), statusLock.getStatus());
        final WrikeQuote quote = quoteSrv.findById(quoteId);
        quoteSrv.removeInvoicePreview(statusLock);
        delete new Attachment(Id = quote.pdfId);
        WrikeUtil.deleteQuotes(new List<String> { quoteId });
    }
}
public class WrikeQuotePaymentController {
    private ZuoraSignatureUtil.Response signature;
	private WrikeQuote quote;
    public String paymentErrorMessage {get; set;}
    public BillingInfo existingCreditCard {get; set;}
    public BillingInfo newCreditCard {get; set;}
    private final ZuoraRestQueryService zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();
    private final ZuoraService zuoraSrv = ZuoraService.getInstance();

    public WrikeQuotePaymentController() {
		final QuoteService quoteSrv = QuoteService.getInstance();
		final String encryptedQuoteId = ApexPages.currentPage().getParameters().get('q');
		final Id quoteId = WrikeUtil.getDecryptedId(encryptedQuoteId);
		if (quoteId != null) {
			try {
				this.quote = quoteSrv.findById(quoteId);
			} catch (LogicException e) {
				System.debug(Logginglevel.ERROR, e.getMessage());
			}
		}
        if (this.quote != null) {
            this.existingCreditCard = findExistingBillingInfo();
            this.signature = ZuoraSignatureUtil.requestSignature();
        }
    }

    private BillingInfo findExistingBillingInfo() {
        if(this.quote.zuoraCreditCardId != null) {
            return zuoraRestQuerySrv.findCreditCardInfoById(this.quote.zuoraCreditCardId, false);
        }
        if(this.quote.zuoraAccountId != null) {
           return zuoraRestQuerySrv.findCreditCardInfoByAccountId(this.quote.zuoraAccountId);
        }
        return null;
    }
    
    public ZuoraSignatureUtil.Response getSignature() {
        return this.signature;
    }
    
    public PageReference savePaymentMethod() {
        final String paymentMethodId = ApexPages.currentPage().getParameters().get('paymentMethodId');
        try {
			this.newCreditCard = zuoraRestQuerySrv.findCreditCardInfoById(paymentMethodId, false);
			if(this.newCreditCard != null) {
				if(this.quote.zuoraAccountId != null) {
                    zuoraSrv.updatePaymentInfo(this.quote.zuoraAccountId,
							false,
							this.newCreditCard,
							paymentMethodId,
							null,
							null,
							null);
				} else {
					QuoteService.getInstance().savePaymentMethod(this.quote.Id, paymentMethodId);
				}
			}
        } catch (Exception e) {
            ExceptionUtil.sendNotification(
                'ATTENTION! Exception during Credit Card submit: ' + this.quote.Id, 
                e.getMessage() + '\n' + e.getStackTraceString());
        }
        return null;
    }

    
    public PageReference displayPaymentError() { 
        final String errorMessage = ApexPages.currentPage().getParameters().get('message');
        if(errorMessage != null) {
             this.paymentErrorMessage = errorMessage.unescapeHtml4();
        }
        return null;
    }

	public WrikeQuote getQuote() {
		return quote;
	}
}
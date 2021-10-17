public class QuoteUtil {

    public class QuoteWrapper {
        public Id quoteId {get; set;}
        public String name {get; set;}
        public Decimal wrikeAccountId {get; set;}
        public Date validUntil {get; set;}
        public Object details {get; set;}
        public List<Object> products {get; set;}
        
        public QuoteWrapper(final WrikeQuote quote) {
            this.quoteId = quote.id;
            this.name = quote.name;
            this.wrikeAccountId = quote.wrikeAccountId;
            this.validUntil = quote.validUntil;
            this.products = quote.items;
            this.details = new Map<String, Object> {
                'version' => 2,
                'effectiveDate' => quote.effectiveDate,
                'encryptedId' => WrikeUtil.encryptAndEncode(String.valueOf(quoteId)),
                'ownerName' => quote.ownerName,
                'ownerEmail' => quote.ownerEmail,
                'ownerPhone' => quote.ownerPhone
            };
        } 
    }
}
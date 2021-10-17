public class QuoteService {

    public static QuoteService getInstance() {
        return (QuoteService)ServiceLocator.getInstance(QuoteService.class);
    }

    public static final Integer QUOTE_NUMBER_LENGTH = 9;
    public static final Integer QUOTE_NAME_LENGTH = WrikeConstants.NAME_LENGTH - QUOTE_NUMBER_LENGTH - 3;

    private QuoteQueryService quoteQuerySrv;
    private QuoteValidationService quoteValidationSrv;
    private DatabaseService databaseSrv;
    private ZuoraRestQueryService zuoraRestQuerySrv;

    public QuoteService() {
        this.quoteQuerySrv = QuoteQueryService.getInstance();
        this.quoteValidationSrv = QuoteValidationService.getInstance();
        this.databaseSrv = DatabaseService.getInstance();
        this.zuoraRestQuerySrv = ZuoraRestQueryService.getInstance();
    }

    public WrikeQuote findWithItemsById(String quoteId) {
        return findAndValidate(quoteId, false).wQuote;
    }

    public WrikeQuoteWithValidation findAndValidate(String quoteId, Boolean isNeedValidate) {
        final List<Quote__c> quotes = quoteQuerySrv.findWithItemsById(quoteId);
        if (quotes.isEmpty()) {
            throw new LogicException('Quote with id = {0} not found.', quoteId);
        }
        final WrikeQuote wrikeQuote = QuoteMapper.mapToWrikeQuoteWithLineItems(quotes[0]);
        if(!isNeedValidate) {
            return new WrikeQuoteWithValidation(wrikeQuote, null, null);
        }
        final QuoteValidationService.Result validationResult = quoteValidationSrv.validateQuote(quotes[0]);
        return new WrikeQuoteWithValidation(wrikeQuote, validationResult.getCode(), validationResult.getMessage());
    }

    public WrikeQuoteWithValidation findWithItemsAndOpportunityAndContactById(String quoteId, Boolean isNeedValidate) {
        final List<Quote__c> quotes = quoteQuerySrv.findWithItemsAndOpportunityAndContactById(quoteId);
        if (quotes.isEmpty()) {
            throw new LogicException('Quote with id = {0} not found.', quoteId);
        }
        final WrikeQuote wrikeQuote = QuoteMapper.mapToWrikeQuoteWithLineItems(quotes[0]);
        if(!isNeedValidate) {
            return new WrikeQuoteWithValidation(wrikeQuote, null, null);
        }
        final QuoteValidationService.Result validationResult = quoteValidationSrv.validateQuote(quotes[0]);
        return new WrikeQuoteWithValidation(wrikeQuote, validationResult.getCode(), validationResult.getMessage());
    }

    public WrikeQuote findById(String quoteId) {
        final List<Quote__c> quotes = quoteQuerySrv.findById(quoteId);
        if (quotes.isEmpty()) {
            throw new LogicException('Quote with id = {0} not found.', quoteId);
        }
        return QuoteMapper.mapToWrikeQuoteWithLineItems(quotes[0]);
    }

    public WrikeQuote findInZuora(String zuoraAccountId) {
        final List<ZuoraObject.ZuoraSubscription> subscriptions = zuoraRestQuerySrv.findSubscriptionsByZuoraAccountId(zuoraAccountId);

        String validationResult = quoteValidationSrv.validateRelatedSubscription(zuoraAccountId, null, subscriptions);
        if (String.isNotBlank(validationResult)) {
            throw new LogicException(validationResult);
        }
        final List<ZuoraObject.ZuoraSubscriptionProduct> products = zuoraRestQuerySrv.listSubscriptionProducts(subscriptions[0].id);
        for (ZuoraObject.ZuoraSubscriptionProduct subscriptionProduct : products) {
            if (subscriptionProduct.price == null) {
                throw new LogicException('Unable to define effective price for current products. Please create Sales and Biz Ops request through Request Form.');
            }
        }
        WrikeQuote wQuote = QuoteMapper.mapToWrikeQuote(subscriptions[0], products);
        wQuote.zuoraAccountId = zuoraAccountId;
        wQuote.zuoraAccountName = zuoraRestQuerySrv.getAccountNameById(zuoraAccountId);
        wQuote.zuoraSubscriptionId = subscriptions[0].id;
        return wQuote;
    }
    
    public List<Id> listNonSentQuoteIds(final List<String> quoteIds) {
        final List<Quote__c> quotes = quoteQuerySrv.findWithStatusByIds(quoteIds);
        final List<Id> nonSentIds = new List<Id>();
        for(Quote__c quote : quoteQuerySrv.findWithStatusByIds(quoteIds)) {
            if(quote.Status__c != WrikeQuote.Status.SENT.name()) {
                nonSentIds.add(quote.Id);
            }
        }
        return nonSentIds;
    }

    public WrikeQuote upsertQuote(WrikeQuote wQuote) {
        wQuote.total = null;
        wQuote.deltaMrr = null;
        Quote__c quote = QuoteMapper.mapToQuote(wQuote);
        Boolean upsertResult = databaseSrv.upsertSObject(quote);
        if (!upsertResult) {
            throw new LogicException('Error has occurred during create the Quote.');
        }
        wQuote.id = quote.Id;
        wQuote.primary = quote.Primary__c;
        return wQuote;
    }

    public ZuoraAccountResult sendNewQuoteToWrike(final WrikeQuote wQuote) {
        final Map<String, Object> response = WrikeUtil.sendWrikeRequest(wQuote.wrikeAccountId,
            new Map<String, String> {
                'action' => 'new_quote',
                'salesForceAccountId' => wQuote.accountId,
                'paymentMethod' => wQuote.paymentTerm == 'Due Upon Receipt' ? 'Credit Card' : 'Check',
                'currency' => wQuote.getCurrencyCode(),
                'validUntil' => String.valueOf(wQuote.validUntil)
            }
        );
        final String zuoraAccountId = (String)response.get('zuoraAccountId');
        if (zuoraAccountId == null) {
            throw new LogicException('Failed send the quote to Wrike.');
        }
        return new ZuoraAccountResult(zuoraAccountId, (String)response.get('dataCenter'));
    }

    public WrikeAccountRegistrationResult registerNewWrikeAccount(final WrikeQuote wrikeQuote,
                                                                  final String firstName,
                                                                  final String lastName,
                                                                  final String email) {
        final Map<String, Object> response = WrikeUtil.sendWrikeRequest(0,
                new Map<String, String> {
                    'action' => 'register_new_account',
                    'salesForceAccountId' => wrikeQuote.accountId,
                    'paymentMethod' => wrikeQuote.paymentTerm == 'Due Upon Receipt' ? 'Credit Card' : 'Check',
                    'validUntil' => String.valueOf(wrikeQuote.validUntil),
                    'firstName' => firstName,
                    'lastName' => lastName,
                    'email' => email
                }
        );
        final Boolean emailInUse = (Boolean)response.get('emailInUse');
        final String message = (String)response.get('message');
        if(emailInUse == true) {
            return new WrikeAccountRegistrationResult(null, null, true, message);
        }
        final Integer wrikeAccountId = (Integer)response.get('wrikeAccountId');
        final String zuoraAccountId = (String)response.get('zuoraAccountId');
        return new WrikeAccountRegistrationResult(wrikeAccountId, zuoraAccountId, false, message);
    }

    public void upsertQuoteItems(final List<WrikeQuoteItem> wrikeQuoteItems) {
        final List<Quote_Item__c> quoteItems = QuoteMapper.mapToQuoteItem(wrikeQuoteItems);
        if (!databaseSrv.upsertSObject(quoteItems)) {
            throw new LogicException('Error has occurred during update Quote Items.');
        }
    }

    public WrikeQuote upsertQuoteWithProducts(WrikeQuote wQuote) {
        Savepoint quoteSavePoint = Database.setSavepoint();

        wQuote = upsertQuote(wQuote);

        List<Quote_Product__c> quoteProducts = QuoteMapper.mapToQuoteProduct(wQuote.items);
        Boolean upsertResult = databaseSrv.upsertSObject(quoteProducts);
        if (!upsertResult) {
            Database.rollback(quoteSavePoint);
            throw new LogicException('Error has occurred during create the Quote Products.');
        }
        for (Integer index = 0; index < quoteProducts.size(); index++) {
            WrikeQuoteItem wQuoteItem = wQuote.items[index];
            wQuoteItem.quoteId = wQuote.id;
            wQuoteItem.productId = quoteProducts[index].id;
            wQuoteItem.product.id = quoteProducts[index].id;
        }

        List<Quote_Item__c> quoteItems = QuoteMapper.mapToQuoteItem(wQuote.items);
        upsertResult = databaseSrv.upsertSObject(quoteItems);
        if (!upsertResult) {
            Database.rollback(quoteSavePoint);
            throw new LogicException('Error has occurred during create the Quote Items.');
        }
        for (Integer index = 0; index < quoteItems.size(); index++) {
            WrikeQuoteItem wQuoteItem = wQuote.items[index];
            wQuoteItem.id = quoteItems[index].Id;
        }
        return wQuote;
    }

    public WrikeQuoteZuoraService.SubscriptionPreview getSavedSubscriptionPreview(final String quoteId) {
        final Quote__c quote = quoteQuerySrv.findSubscriptionPreviewById(quoteId);
        if (quote != null && quote.SubscriptionPreview__c != null) {
            final WrikeQuoteZuoraService.SubscriptionPreview preview =
                    (WrikeQuoteZuoraService.SubscriptionPreview)JSON.deserialize(quote.SubscriptionPreview__c,
                                    WrikeQuoteZuoraService.SubscriptionPreview.class);
            if (preview.getInvoicePreview() != null
                    && preview.getInvoicePreview().getInvoices() == null
                    && quote.SubscriptionPreviewInvoices__c != null) {
                preview.getInvoicePreview().setInvoices((List<Invoice>)JSON.deserialize(
                        quote.SubscriptionPreviewInvoices__c, List<Invoice>.class));
            }
            return preview;
        }
        return null;
    }
    
    public Boolean setDraftPreview(final StatusLock lock, final InvoicePreview invoicePreview) {
        System.assertEquals(WrikeQuote.Status.DRAFT.name(), lock.getStatus());
        return databaseSrv.updateSObject(new Quote__c(
            Id = lock.getQuoteId(),
            Total__c = invoicePreview.totalChargeAmount,
            DeltaMrr__c = invoicePreview.deltaMrr
        ));
    }

    public DatabaseService.Result saveSubscriptionPreview(final StatusLock lock,
                                        final WrikeQuoteZuoraService.SubscriptionPreview preview) {
        System.assert(WrikeQuote.Status.DRAFT.name() == lock.getStatus() || WrikeQuote.Status.CANCEL.name() == lock.getStatus());
        final InvoicePreview invoicePreview = preview.getInvoicePreview();
        final List<Invoice> previewInvoices = invoicePreview != null
                                              ? invoicePreview.getInvoices()
                                              : null;
        if(invoicePreview != null) {
            invoicePreview.setInvoices(null);
        }
        return databaseSrv.updateAndGetResult(new Quote__c(
            Id = lock.getQuoteId(),
            SubscriptionPreview__c = JSON.serialize(preview),
            SubscriptionPreviewInvoices__c = previewInvoices != null
                                             ? JSON.serialize(previewInvoices)
                                             : null,
            Status__c = preview.isSuccess() ? WrikeQuote.Status.TRIAL.name() : WrikeQuote.Status.DRAFT.name()
        ), true);
    }
    
    public void setProposal(final StatusLock lock,
                            final InvoicePreview invoicePreview,
                            final Id pdfAttachmentId) {
        System.assertEquals(WrikeQuote.Status.APPROVED.name(), lock.getStatus());
        System.assert(invoicePreview != null, 'Invoce preview is required.');
        System.assert(invoicePreview.deltaMrr != null, 'Delta MRR is required.');
        System.assert(invoicePreview.totalChargeAmount != null, 'Total charge amount is required.');
        System.assert(pdfAttachmentId != null, 'Pdf attachment id is required.');
        final Boolean result = databaseSrv.updateSObject(new Quote__c(
            Id = lock.getQuoteId(),
            Pdf_Id__c = pdfAttachmentId,
            Total__c = invoicePreview.totalChargeAmount,
            DeltaMrr__c = invoicePreview.deltaMrr,
            TargetInvoiceDate__c = invoicePreview.getTargetInvoiceDate(),
            Status__c = WrikeQuote.Status.PROPOSAL.name()
        ));
        System.assert(result, 'Failed to save quote preview.');
    }

    public void removeInvoicePreview(final StatusLock lock) {
        System.assertEquals(WrikeQuote.Status.PROPOSAL.name(), lock.getStatus());
        databaseSrv.updateSObject(new Quote__c(
            Id = lock.getQuoteId(),
            Pdf_Id__c = null,
            Total__c = null,
            DeltaMrr__c = null,
            TargetInvoiceDate__c = null,
            Status__c = WrikeQuote.Status.APPROVED.name()
        ));
    }
    
    public void markQuoteSentToZuora(final StatusLock lock) {
        System.assertEquals(WrikeQuote.Status.PROPOSAL.name(), lock.getStatus());
        databaseSrv.updateSObject(new Quote__c(
            Id = lock.getQuoteId(),
            Status__c = WrikeQuote.Status.SENT.name()
        ));
    }

    public void setOutboundWrikeAccount(final Id quoteId,
                                        final Id opportunityId,
                                        final Integer wrikeAccountId,
                                        final String zuoraAccountId) {
        final DatabaseService.Result quoteUpdateResult = databaseSrv.updateAndGetResult(new Quote__c(
                Id = quoteId,
                WrikeAccountId__c = wrikeAccountId,
                Zuora_Account_Id__c = zuoraAccountId
        ), false);
		if(!quoteUpdateResult.isSuccess()) {
			throw new LogicException('Failed to update the quote: ' + quoteUpdateResult.getErrorMessage());
		}
		final DatabaseService.Result opportunityUpdateResult = databaseSrv.updateAndGetResult(new Opportunity(
            Id = opportunityId,
            Wrike_Account_Id__c = wrikeAccountId
        ), false);
		if(!opportunityUpdateResult.isSuccess()) {
			throw new LogicException('Failed to update the opportunity: ' + opportunityUpdateResult.getErrorMessage());
		}
    }

    public Id findExistingPrimaryQuoteId(final Id quoteId, final Id opportunityId) {
        if(quoteId != null && opportunityId != null) {
            final List<Quote__c> existingPrimaryQuotes = quoteQuerySrv.listPrimaryQuotesByOpportunityId(opportunityId);
            for(Quote__c quote : existingPrimaryQuotes) {
                if(quote.Id != quoteId) {
                    return quote.Id;
                }
            }
        }
        return null;
    }

    public void markPrimary(final Id quoteId) {
        final Id opportunityId = quoteQuerySrv.findOpportunityIdByQuoteId(quoteId);
        if(opportunityId != null) {
            final List<Quote__c> quotesForUpdate = new List<Quote__c> {
                new Quote__c(Id = quoteId, Primary__c = true)
            };
            final List<Quote__c> existingPrimaryQuotes = quoteQuerySrv.listPrimaryQuotesByOpportunityId(opportunityId);
            for(Quote__c quote : existingPrimaryQuotes) {
                if(quote.Id != quoteId) {
                    quotesForUpdate.add(new Quote__c(
                        Id = quote.Id,
                        Primary__c = false,
                        Status__c = WrikeQuote.Status.CANCEL.name()
                    ));
                }
            }
            databaseSrv.updateSObject(quotesForUpdate);
        }
    }

    public void updateQuoteName(List<Quote__c> quotes, Boolean isBefore) {
        List<Quote__c> quotesForUpdate = new List<Quote__c>();
        for (Quote__c currentQuote : quotes) {
            if (currentQuote.Name.startsWith(currentQuote.Number__c)) {
                continue;
            }
            String quoteName = StringUtils.format('{0} - {1}',currentQuote.Number__c, currentQuote.Name)
                .left(QuoteService.QUOTE_NAME_LENGTH);
            if (isBefore) {
                currentQuote.Name = quoteName;
            } else {
                Quote__c quoteForUpdate = new Quote__c();
                quoteForUpdate.Id = currentQuote.Id;
                quoteForUpdate.Name = quoteName;
                quotesForUpdate.add(quoteForUpdate);
            }
        }
        if (!isBefore) {
            databaseSrv.updateSObject(quotesForUpdate);
        }
    }

    public void deleteQuoteItemByIds(List<String> quoteItemIds) {
        if (quoteItemIds.isEmpty()) {
            return;
        }
        Boolean deleteResult = databaseSrv.deleteSObject(quoteItemIds);
        if (!deleteResult) {
            throw new LogicException('Error has occurred during delete the Quote Items.');
        }
    }

    public void savePaymentMethod(final Id quoteId, final String paymentMethodId) {
        databaseSrv.updateSObject(new Quote__c(
            Id = quoteId,
            ZuoraCreditCardid__c = paymentMethodId
        ));
    }

    public void updateAttachmentId(String quoteId, String attachmentId) {
        databaseSrv.updateSObject(new Quote__c(Id = quoteId, PurchaseOrderAttachmentId__c = attachmentId));
    }

    public StatusLock getStatusLock(final Id quoteId) {
        final List<Quote__c> quotes =  quoteQuerySrv.findWithStatusForUpdateById(quoteId);
        return quotes.isEmpty() ? null : new StatusLock(quotes[0].Id, quotes[0].Status__c);
    }

    public void addSendQuoteOperation(final Id quoteId) {
        databaseSrv.insertSObject(new Quote_Operation__c(
            Key__c = getSendOperationKey(quoteId),
            Quote__c = quoteId
        ));
    }

    public void removeSendQuoteOperation(final Id quoteId) {
        final String key = getSendOperationKey(quoteId);
        final Id operationId = quoteQuerySrv.findQuoteOperationId(key);
        if(operationId != null) {
            databaseSrv.deleteSObject(new List<String> { operationId });
        }
    }

    public Boolean deleteQuote(final WrikeQuote wQuote) {
        if (wQuote == null) {
            return false;
        }
        final List<Id> wQuoteProductIds = new List<Id>();
        for (WrikeQuoteItem item : wQuote.items) {
            wQuoteProductIds.add(item.productId);
        }
        final Savepoint deleteQuotePoint = databaseSrv.setSavePoint();
        Boolean isSuccess = databaseSrv.deleteSObject(wQuote.id);
        if (!isSuccess) {
            return false;
        }
        isSuccess = databaseSrv.deleteSObject(wQuoteProductIds);
        if (!isSuccess) {
            databaseSrv.rollbackTo(deleteQuotePoint);
            return false;
        }
        return true;
    }

    public void deleteQuotesInWrikeByIds(final Set<Id> quoteIds) {
        if (!quoteIds.isEmpty()) {
            System.enqueueJob(new DeleteQuoteInWrikeQueueable(ApexUtils.toList(quoteIds)));
        }
    }

    public void deleteQuoteProductsAndDeleteQuotesInWrike(Set<Id> opportunityIds) {
        if (!opportunityIds.isEmpty()) {
            List<Quote__c> quotes = quoteQuerySrv.findWithItemsByOpportunityIds(opportunityIds);
            List<String> quoteIds = SobjectUtils.extractNotNullByFieldName(quotes, 'Id');
            final List<String> quoteProductIds = new List<String>();
            for (Quote__c currentQuote : quotes) {
                for (Quote_Item__c currentQuoteItem : currentQuote.Quote_Items__r) {
                    quoteProductIds.add(currentQuoteItem.Product__c);
                }
            }
            databaseSrv.deleteSObject(quoteProductIds);
            if (!quoteIds.isEmpty()) {
                System.enqueueJob(new DeleteQuoteInWrikeQueueable(quoteIds));
            }
        }
    }

    public void logWrikeSyncError(List<String> quoteIds, WrikeUtil.WrikeResponse wrikeResponse) {
        if (wrikeResponse != null && !wrikeResponse.getIsSuccess()) {
            for (String quoteId : quoteIds) {
                databaseSrv.addSobject(new Quote__c(
                    Id = quoteId,
                    WrikeSyncError__c = wrikeResponse.getMessage()
                ));
            }
            databaseSrv.updateSObject();
        }
    }

    public void acceptQuoteInWrike(Map<Id, String> quoteIdToZuoraAccountId) {
        if (!quoteIdToZuoraAccountId.isEmpty()) {
            System.enqueueJob(new AcceptQuoteInWrikeQueueable(ApexUtils.toList(quoteIdToZuoraAccountId.keySet())));
        }
    }

    public Boolean cancelQuote(final String quoteId) {
        return databaseSrv.updateSObject(new Quote__c(
            Id = quoteId,
            Status__c = WrikeQuote.Status.CANCEL.name(),
            Primary__c = false
        ));
    }

    public Boolean restoreQuote(final WrikeQuote wQuote) {
        String quoteStatus = '';
        if (String.isNotBlank(wQuote.pdfId)) {
            quoteStatus = WrikeQuote.Status.PROPOSAL.name();
        } else {
            quoteStatus = WrikeQuote.Status.TRIAL.name();
        }
        return databaseSrv.updateSObject(new Quote__c(
            Id = wQuote.id,
            Status__c = quoteStatus
        ));
    }

    public void mapToStandardProduct(final WrikeQuoteItem item) {
        final ProductService productSrv = ProductService.getInstance();
        final Map<String, Product2> productMap = productSrv.getExistingProductMap();
        final Map<String, Map<String, Product2>> implementationProductMap =
                productSrv.getExistingImplementationProductMap();

        final Map<String, Product2> rateplanMap = implementationProductMap.get(item.product.zuoraProductId);
        final Product2 product = rateplanMap != null
                                 ? rateplanMap.get(item.product.zuoraProductRatePlanId)
                                 : productMap.get(item.product.zuoraProductId);
        if (product != null) {
            item.product.product2Id = product.Id;
        }
    }

    private String getSendOperationKey(final Id quoteId) {
        return 'send_quote_' + quoteId;
    }

    public class StatusLock {
        private final Id quoteId;
        private final String status;
        
        private StatusLock(final Id quoteId, final String status) {
            this.quoteId = quoteId;
            this.status = status;
        }
        
        public Id getQuoteId() {
            return this.quoteId;
        }
        
        public String getStatus() {
            return this.status;
        }
    }

    public class WrikeQuoteWithValidation {

        public final WrikeQuote wQuote;
        public final String code;
        public final String message;

        public WrikeQuoteWithValidation(final WrikeQuote wQuote, final String validationCode, final String validationMessage) {
            this.wQuote = wQuote;
            this.code = validationCode;
            this.message = validationMessage;
        }

        public Boolean isNotValid() {
            return String.isNotBlank(this.message);
        }

        public Boolean isValid() {
            return String.isBlank(this.message);
        }
    }

    public class DeleteQuoteInWrikeQueueable implements Queueable, Database.AllowsCallouts {

        private final QuoteQueryService quoteQuerySrv = QuoteQueryService.getInstance();
        private final QuoteService quoteSrv = QuoteService.getInstance();
        private final Logger myLogger = Logger.create(DeleteQuoteInWrikeQueueable.class);

        private List<String> quoteIds;

        public DeleteQuoteInWrikeQueueable(final List<String> quoteIds) {
            this.quoteIds = quoteIds;
        }

        public void execute(System.QueueableContext context) {
            final List<Quote__c> quotes = quoteQuerySrv.findWithStatusByIds(this.quoteIds);
            if (quotes.isEmpty()) {
                WrikeUtil.deleteQuotesByIds(quoteIds);
            } else {
                final List<String> quoteIdsForDelete = new List<String>();
                for (Quote__c currentQuote : quotes) {
                    if (currentQuote.Status__c == WrikeQuote.Status.DRAFT.name()
                            || currentQuote.Status__c == WrikeQuote.Status.CANCEL.name()) {
                        quoteIdsForDelete.add(currentQuote.Id);
                    }
                }
                if (!quoteIdsForDelete.isEmpty()) {
                    WrikeUtil.WrikeResponse wrikeResponse = WrikeUtil.deleteQuotesByIds(quoteIdsForDelete);
                    quoteSrv.logWrikeSyncError(quoteIdsForDelete, wrikeResponse);
                }
            }
            myLogger.saveLog();
        }
    }

    public class AcceptQuoteInWrikeQueueable implements Queueable, Database.AllowsCallouts {

        private final QuoteQueryService quoteQuerySrv = QuoteQueryService.getInstance();
        private final QuoteService quoteSrv = QuoteService.getInstance();
        private final Logger myLogger = Logger.create(AcceptQuoteInWrikeQueueable.class);

        private List<String> quoteIds;

        public AcceptQuoteInWrikeQueueable(final List<String> quoteIds) {
            this.quoteIds = quoteIds;
        }

        public void execute(System.QueueableContext context) {
            final List<Quote__c> quotes = quoteQuerySrv.findWithStatusByIds(this.quoteIds);
            if (!quotes.isEmpty()) {
                Quote__c quote = quotes.get(0);
                if (quote.Status__c == WrikeQuote.Status.SENT.name()) {
                    for (String quoteId : quoteIds) {
                        if (Limits.getCallouts() < Limits.getLimitCallouts()) {
                            WrikeUtil.WrikeResponse wrikeResponse = WrikeUtil.acceptQuoteById(quote.WrikeAccountId__c, quoteId);
                            quoteSrv.logWrikeSyncError(new List<String>{quoteId}, wrikeResponse);
                        }
                    }
                }
                myLogger.saveLog();
            }
        }
    }

    public class ZuoraAccountResult {
        private final String zuoraAccountId;
        private final String dataCenter;

        public ZuoraAccountResult(String zuoraAccountId, String dataCenter) {
            this.zuoraAccountId = zuoraAccountId;
            this.dataCenter = dataCenter;
        }

        public String getZuoraAccountId() {
            return zuoraAccountId;
        }

        public String getDataCenter() {
            return dataCenter;
        }
    }

    public class WrikeAccountRegistrationResult {
        private final Integer wrikeAccountId;
        private final String zuoraAccountId;
        private final Boolean emailInUse;
        private final String message;

        public WrikeAccountRegistrationResult(final Integer wrikeAccountId,
                                              final String zuoraAccountId,
                                              final Boolean emailInUse,
                                              final String message) {
            this.wrikeAccountId = wrikeAccountId;
            this.zuoraAccountId = zuoraAccountId;
            this.emailInUse = emailInUse;
            this.message = message;
        }

        public Integer getWrikeAccountId() {
            return wrikeAccountId;
        }

        public String getZuoraAccountId() {
            return zuoraAccountId;
        }

        public Boolean getEmailInUse() {
            return emailInUse;
        }

        public String getMessage() {
            return message;
        }
    }
}
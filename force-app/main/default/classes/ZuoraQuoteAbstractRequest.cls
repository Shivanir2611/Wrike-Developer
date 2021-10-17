public abstract class ZuoraQuoteAbstractRequest {

    public class RatePlanData {
        public RatePlan RatePlan {get; set;}
        public List<RatePlanChargeData> RatePlanChargeData {get; set;}

        public RatePlanData(final WrikeQuoteItem quoteItem, final Boolean preview) {
            final WrikeQuoteProduct product = quoteItem.product;
            if(quoteItem.getIsAdded()) {
                System.assert(String.isNotBlank(product.zuoraProductRatePlanId), 'ProductRatePlanId is required for new product.');
                this.RatePlan = new RatePlan();
                this.RatePlan.ProductRatePlanId = product.zuoraProductRatePlanId;
                final RatePlanCharge ratePlanCharge = new RatePlanCharge();
                ratePlanCharge.ProductRatePlanChargeId = product.zuoraProductRatePlanChargeId;
                ratePlanCharge.Quantity = product.quantity > 0 ? product.quantity : 1;
                ratePlanCharge.Price = product.getZuoraEffectivePrice();
                if(preview) {
                    ratePlanCharge.Description = quoteItem.id;
                }
                final RatePlanChargeData ratePlanChargeData =  new RatePlanChargeData();
                ratePlanChargeData.RatePlanCharge = ratePlanCharge;
                if(product.isVolumePricing()) {
                    final RatePlanChargeTier ratePlanChargeTier = new RatePlanChargeTier();
                    ratePlanChargeTier.RatePlanChargeId = product.zuoraProductRatePlanChargeId;
                    ratePlanChargeTier.Tier = 1;
                    ratePlanChargeTier.StartingUnit = 1;
                    ratePlanChargeTier.PriceFormat = product.isPerUnitPrice() ? 'PerUnit' : 'FlatFee';
                    ratePlanChargeTier.Price = product.getZuoraEffectivePrice();
                    ratePlanChargeData.RatePlanChargeTier = new List<RatePlanChargeTier> { ratePlanChargeTier };
                }
                this.RatePlanChargeData = new List<RatePlanChargeData> { ratePlanChargeData };
            } else if(quoteItem.getIsRemoved()) {
                System.assert(String.isNotBlank(product.zuoraRatePlanId),
                        'AmendmentSubscriptionRatePlanId is required for product removal.');
                this.RatePlan = new RatePlan();
                this.RatePlan.AmendmentSubscriptionRatePlanId = product.zuoraRatePlanId;
            } else {
                System.assert(false, 'Unsupported quote item state: ' + quoteItem.state);
            }
        }
    }

    public class RatePlan{
        public String ProductRatePlanId {get; set;}
        public String AmendmentSubscriptionRatePlanId {get; set;}
    }

    public class RatePlanChargeData {
        public RatePlanCharge RatePlanCharge {get; set;}
        public List<RatePlanChargeTier> RatePlanChargeTier {get; set;}
    }

    public class RatePlanChargeTier {
        public String RatePlanChargeId {get; set;}
        public Integer Tier {get; set;}
        public Integer StartingUnit {get; set;}
        public String PriceFormat {get; set;}
        public Decimal Price {get; set;}
    }

    public class RatePlanCharge {
        public String ProductRatePlanChargeId {get; set;}
        public Integer Quantity {get; set;}
        public Decimal Price {get; set;}
        public String Description {get; set;}
    }

    public class PreviewOptions {
        private final Boolean EnablePreviewMode = true;
        private final Boolean IncludeExistingDraftInvoiceItems = false;
        private final Boolean PreviewThroughTermEnd = true;

        public Boolean getEnablePreviewMode() {
            return EnablePreviewMode;
        }

        public Boolean getPreviewThroughTermEnd() {
            return PreviewThroughTermEnd;
        }

        public Boolean getIncludeExistingDraftInvoiceItems() {
            return IncludeExistingDraftInvoiceItems;
        }
    }

    public class RequestOptions {
        private final Boolean GenerateInvoice = false;
        private final Boolean ProcessPayments = false;
        private InvoiceProcessingOptions SubscribeInvoiceProcessingOptions = null;

        public Boolean getGenerateInvoice() {
            return GenerateInvoice;
        }

        public Boolean getProcessPayments() {
            return ProcessPayments;
        }

        public InvoiceProcessingOptions getSubscribeInvoiceProcessingOptions() {
            return SubscribeInvoiceProcessingOptions;
        }

        public void setSubscribeInvoiceProcessingOptions(final InvoiceProcessingOptions subscribeInvoiceProcessingOptions) {
            this.SubscribeInvoiceProcessingOptions = subscribeInvoiceProcessingOptions;
        }
    }

    public class InvoiceProcessingOptions {
        private final String InvoiceProcessingScope  = 'Subscription';

        public String getInvoiceProcessingScope() {
            return InvoiceProcessingScope;
        }
    }
}
/*
 * Created by andrey.kuleshov on 28/08/2019.
 */
public class QuoteBundle {
	private final List<QuoteBundleLineItem> recurrentItems = new List<QuoteBundleLineItem>();
	private final List<QuoteBundleLineItem> renewalItems = new List<QuoteBundleLineItem>();
	private final List<QuoteBundleLineItem> oneTimeItems = new List<QuoteBundleLineItem>();
    private QuoteBundleLineItem partnerCommissionItem = null;
	private Integer recurrentItemsAdded = 0;
	private Integer recurrentItemsRemoved = 0;
	private Decimal recurrentTotalPriceAdded = 0;
	private Decimal recurrentTotalPriceRemoved = 0;
	private Decimal recurrentEffectiveRateAdded = 0;
	private Decimal recurrentEffectiveRateRemoved = 0;
	private Decimal recurrentListRateAdded = 0;
	private Decimal renewalTotalPrice = 0;
	private Decimal renewalEffectiveRate = 0;
	private Decimal renewalListRate = 0;
	private Decimal oneTimeListPrice = 0;
	private Decimal oneTimeEffectivePrice = 0;

	private QuoteBundle(final List<QuoteBundleLineItem> lineItems) {
		for(QuoteBundleLineItem item : lineItems) {
			if(item.getOneTime() == true) {
                if(item.getItems()[0].isPartnerCommission()) {
                    partnerCommissionItem = item;
                } else {
                    oneTimeItems.add(item);
                    oneTimeListPrice = oneTimeListPrice + (item.getOneTimeListPrice() > 0
                                                           ? item.getOneTimeListPrice()
                                                           : item.getOneTimeEffectivePrice());
                    oneTimeEffectivePrice = oneTimeEffectivePrice + item.getOneTimeEffectivePrice();
                }
			} else {
				if(item.getRenewal() == true) {
					renewalItems.add(item);
					renewalTotalPrice = renewalTotalPrice + item.getChargeAmount();
					renewalEffectiveRate = renewalEffectiveRate + item.getBillingPeriodEffectivePrice();
					renewalListRate = renewalListRate + (item.getBillingPeriodListPrice() > 0
																	   ? item.getBillingPeriodListPrice()
																	   : item.getBillingPeriodEffectivePrice());
				} else {
					recurrentItems.add(item);
					if(item.getRemoved() == true) {
						recurrentItemsRemoved = recurrentItemsRemoved + 1;
						recurrentTotalPriceRemoved = recurrentTotalPriceRemoved + item.getChargeAmount();
						recurrentEffectiveRateRemoved = recurrentEffectiveRateRemoved + item.getBillingPeriodEffectivePrice();
					} else {
						recurrentItemsAdded = recurrentItemsAdded + 1;
						recurrentTotalPriceAdded = recurrentTotalPriceAdded + item.getChargeAmount();
						recurrentEffectiveRateAdded = recurrentEffectiveRateAdded + item.getBillingPeriodEffectivePrice();
						recurrentListRateAdded = recurrentListRateAdded + (item.getBillingPeriodListPrice() > 0
																		   ? item.getBillingPeriodListPrice()
																		   : item.getBillingPeriodEffectivePrice());

					}
				}
			}
		}
	}

	public List<QuoteBundleLineItem> getRecurrentItems() {
		return recurrentItems;
	}

	public List<QuoteBundleLineItem> getRenewalItems() {
		return renewalItems;
	}

	public List<QuoteBundleLineItem> getOneTimeItems() {
		return oneTimeItems;
	}

    public QuoteBundleLineItem getPartnerCommissionItem() {
        return partnerCommissionItem;
    }

    public Integer getRecurrentItemsAdded() {
		return recurrentItemsAdded;
	}

	public Integer getRecurrentItemsRemoved() {
		return recurrentItemsRemoved;
	}

	public Decimal getRecurrentTotalPriceAdded() {
		return recurrentTotalPriceAdded;
	}

	public Decimal getRecurrentTotalPriceRemoved() {
		return recurrentTotalPriceRemoved;
	}

	public Decimal getRecurrentTotalPrice() {
		return recurrentTotalPriceAdded + recurrentTotalPriceRemoved + renewalTotalPrice;
	}

    public Decimal getRecurrentEffectiveRateAdded() {
        return recurrentEffectiveRateAdded;
    }

    public Decimal getRecurrentEffectiveRateRemoved() {
        return recurrentEffectiveRateRemoved;
    }

    public Decimal getRecurrentListRateAdded() {
        return recurrentListRateAdded;
    }

	public Decimal getRenewalTotalPrice() {
		return renewalTotalPrice;
	}

	public Decimal getRenewalEffectiveRate() {
		return renewalEffectiveRate;
	}

	public Decimal getRenewalListRate() {
		return renewalListRate;
	}

	public Decimal getOneTimeListPrice() {
		return oneTimeListPrice;
	}

	public Decimal getOneTimeEffectivePrice() {
		return oneTimeEffectivePrice;
	}

	public Decimal getInitialPaymentTotal() {
		final Decimal partnerCommission = partnerCommissionItem != null
										  ? partnerCommissionItem.getOneTimeEffectivePrice()
										  : 0;
		return recurrentEffectiveRateAdded + oneTimeEffectivePrice + partnerCommission;
	}

	public class Builder {
		private WrikeQuote quote;
		private final Map<Decimal, QuoteBundleLineItem> addedBundleMap;
		private final Map<Decimal, QuoteBundleLineItem> renewalBundleMap;
		private final Map<Decimal, QuoteBundleLineItem> removedBundleMap;
		private final List<QuoteBundleLineItem> addedIndividualItems = new List<QuoteBundleLineItem>();
		private final List<QuoteBundleLineItem> removedIndividualItems = new List<QuoteBundleLineItem>();


		public Builder(final WrikeQuote quote, final List<ProductItem> items) {
			this.quote = quote;
			Map<Id, ProductItem> addedProductItemMap = new Map<Id, ProductItem>();
			Map<Id, ProductItem> renewalProductItemMap = new Map<Id, ProductItem>();
			Map<Id, ProductItem> removedProductItemMap = new Map<Id, ProductItem>();
			for(ProductItem item : items) {
				if(item.isRemoved()) {
					mergeByQuoteProduct(removedProductItemMap, item);
				} else if(item.serviceStartDate >= quote.subscriptionEndDate && !quote.isNewBillingCycleAmendment()) {
					mergeByQuoteProduct(renewalProductItemMap, item);
				} else {
					mergeByQuoteProduct(addedProductItemMap, item);
				}
			}
			this.addedBundleMap = createQuantityBundleMap(addedProductItemMap.values());
			this.renewalBundleMap = createQuantityBundleMap(renewalProductItemMap.values());
			this.removedBundleMap = createQuantityBundleMap(removedProductItemMap.values());
		}

		private void mergeByQuoteProduct(final Map<Id, ProductItem> itemMap, final ProductItem item) {
			final Id productId = item.getQuoteProductItem().product.id;
			if(itemMap.containsKey(productId)) {
				itemMap.get(productId).mergeProductItem(item);
			} else {
				itemMap.put(productId, item);
			}
		}

		private List<QuoteBundleProductItem> sumProductQuantity(final List<ProductItem> productItems) {
			final Map<String, QuoteBundleProductItem> summarizedProductMap = new Map<String, QuoteBundleProductItem>();
			for(ProductItem productItem : productItems) {
				final WrikeQuoteProduct product = productItem.getQuoteProductItem().product;
				final String mergeUID = product.zuoraProductRatePlanChargeId
						+ '_' + productItem.isRemoved()
						+ '_' + productItem.serviceStartDate
						+ '_' + productItem.serviceEndDate;
				if(summarizedProductMap.containsKey(mergeUID)) {
					summarizedProductMap.get(mergeUID).addProduct(productItem);
				} else {
					summarizedProductMap.put(mergeUID, new QuoteBundleProductItem(productItem));
				}
			}
			return summarizedProductMap.values();
		}

		private Map<Decimal, QuoteBundleLineItem> createQuantityBundleMap(final List<ProductItem> items) {
			final List<QuoteBundleProductItem> bundleProductItems = sumProductQuantity(items);
			bundleProductItems.sort();
			final Map<Decimal, QuoteBundleLineItem> bundleMap = new Map<Decimal, QuoteBundleLineItem>();
			for(QuoteBundleProductItem bundleProductItem : bundleProductItems) {
				if(bundleProductItem.isSeatProduct() || bundleProductItem.isLicenseSeatsMatchingProduct()) {
					if(bundleMap.containsKey(bundleProductItem.getQuantity())) {
						bundleMap.get(bundleProductItem.getQuantity()).addProductItem(bundleProductItem);
					} else {
						bundleMap.put(bundleProductItem.getQuantity(), new QuoteBundleLineItem(
								bundleProductItem,
								true,
								bundleProductItem.getServiceStartDate() >= quote.subscriptionEndDate
						));
					}
				} else {
					if(bundleProductItem.isRemoved()) {
						this.removedIndividualItems.add(new QuoteBundleLineItem(bundleProductItem, false, false));
					} else {
						this.addedIndividualItems.add(new QuoteBundleLineItem(
								bundleProductItem,
								false,
								bundleProductItem.getServiceStartDate() >= quote.subscriptionEndDate
						));
					}
				}
			}
			return bundleMap;
		}

		public QuoteBundle build() {
			final List<QuoteBundleLineItem> productLineItems = new List<QuoteBundleLineItem>();
			productLineItems.addAll(this.addedBundleMap.values());
			productLineItems.addAll(this.renewalBundleMap.values());
			productLineItems.addAll(this.addedIndividualItems);
			productLineItems.addAll(this.removedBundleMap.values());
			productLineItems.addAll(this.removedIndividualItems);
			return new QuoteBundle(productLineItems);
		}
	}
}
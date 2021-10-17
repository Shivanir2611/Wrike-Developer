/*
 * Created by andrey.kuleshov on 18/10/2019.
 */
public class QuotePaymentScheduleController {
	final QuoteService quoteSrv = QuoteService.getInstance();
	private WrikeQuote quote;
	private List<InvoiceBundle> invoiceBundles = new List<InvoiceBundle>();
	private InvoicePreview preview;
	private String errorMessage;

	public QuotePaymentScheduleController() {
		final String quoteId = ApexPages.currentPage().getParameters().get(RequestParam.QUOTE_ID);
		try {
			this.quote = quoteSrv.findWithItemsById(quoteId);
			final WrikeQuoteZuoraService.SubscriptionPreview subscriptionPreview = quoteSrv.getSavedSubscriptionPreview(quoteId);
			if(subscriptionPreview != null) {
				this.preview = subscriptionPreview.getInvoicePreview();
				for(Invoice invoice : preview.getInvoices()) {
					invoiceBundles.add(bundleInvoice(invoice));
				}
			}
		} catch (final LogicException e) {
			this.errorMessage = e.getMessage();
		}
	}

	public WrikeQuote getQuote() {
		return quote;
	}

	public String getErrorMessage() {
		return errorMessage;
	}

	public InvoicePreview getPreview() {
		return preview;
	}

	public Date getFirstInvoiceDate() {
		return this.preview.getFirstInvoiceDate();
	}

	public List<InvoiceBundle> getInvoices() {
		return this.invoiceBundles;
	}

	private InvoiceBundle bundleInvoice(final Invoice invoice) {
		final InvoiceBundle bundledInvoice = new InvoiceBundle(invoice.getInvoiceDate());
		for(InvoiceItem item : invoice.getItems()) {
			bundledInvoice.addItem(item);
		}
		return bundledInvoice;
	}

	public class InvoiceBundle  {
		private final Date invoiceDate;
		private Decimal recurrentTotal = 0;
		private Decimal oneTimeTotal = 0;
		private Map<Integer, InvoiceUserBundle> addedUserBundles = new Map<Integer, InvoiceUserBundle>();
		private Map<Integer, InvoiceUserBundle> removedUserBundles = new Map<Integer, InvoiceUserBundle>();
		private List<InvoiceItem> addedRecurrentItems = new List<InvoiceItem>();
		private List<InvoiceItem> removedRecurrentItems = new List<InvoiceItem>();
		private List<InvoiceItem> recurrentItems = new List<InvoiceItem>();
		private List<InvoiceItem> oneTimeItems = new List<InvoiceItem>();
		private List<InvoiceItem> allItems = new List<InvoiceItem>();

		public InvoiceBundle(final Date invoiceDate) {
			this.invoiceDate = invoiceDate;
		}

		public void addItem(final InvoiceItem item) {
			allItems.add(item);
			final WrikeQuoteProduct product = item.getQuoteProductItem().product;
			if(product.getIsRecurrent()) {
				recurrentItems.add(item);
				recurrentTotal = recurrentTotal + item.chargeAmount;
				if(product.isSeatProduct() || product.isLicenseSeatsMatchingProduct()) {
					addUserItem(item);
				} else if(item.chargeAmount >= 0) {
					addedRecurrentItems.add(item);
				} else {
					removedRecurrentItems.add(item);
				}
			} else {
				oneTimeItems.add(item);
				oneTimeTotal = oneTimeTotal + item.chargeAmount;
			}
		}

		private void addUserItem(final InvoiceItem item) {
			final Map<Integer, InvoiceUserBundle> userBundleMap = item.chargeAmount >= 0 ? addedUserBundles : removedUserBundles;
			if(userBundleMap.containsKey(item.quantity.intValue())) {
				userBundleMap.get(item.quantity.intValue()).addItem(item);
			} else {
				userBundleMap.put(item.quantity.intValue(), new InvoiceUserBundle(item));
			}
		}

		public Date getInvoiceDate() {
			return invoiceDate;
		}

		public Decimal getRecurrentTotal() {
			return recurrentTotal;
		}

		public Decimal getOneTimeTotal() {
			return oneTimeTotal;
		}

		public List<InvoiceUserBundle> getAddedUserBundles() {
			return addedUserBundles.values();
		}

		public List<InvoiceUserBundle> getRemovedUserBundles() {
			return removedUserBundles.values();
		}

		public List<InvoiceItem> getAddedRecurrentItems() {
			return addedRecurrentItems;
		}

		public List<InvoiceItem> getRemovedRecurrentItems() {
			return removedRecurrentItems;
		}

		public List<InvoiceItem> getRecurrentItems() {
			return recurrentItems;
		}

		public List<InvoiceItem> getOneTimeItems() {
			return oneTimeItems;
		}

		public List<InvoiceItem> getAllItems() {
			return allItems;
		}
	}

	public class InvoiceUserBundle {
		private Integer quantity;
		private List<InvoiceItem> items = new List<InvoiceItem>();

		public InvoiceUserBundle(InvoiceItem item) {
			this.quantity = item.quantity.intValue();
			this.items.add(item);
		}

		public void addItem(final InvoiceItem item) {
			this.items.add(item);
		}

		public Integer getQuantity() {
			return quantity;
		}

		public List<InvoiceItem> getItems() {
			return items;
		}
	}
}
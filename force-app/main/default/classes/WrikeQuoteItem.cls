public class WrikeQuoteItem implements Comparable{

    private static Map<String, WrikeQuoteItem.State> nameToState = new Map<String, WrikeQuoteItem.State>();

    static {
        for (WrikeQuoteItem.State currentState : WrikeQuoteItem.State.values()) {
            nameToState.put(currentState.name(), currentState);
        }
    }

    public String uid = String.valueOf(this.hashCode()) + Integer.valueOf(Math.random() * 1000);

    public Id id {get; set;}
    public Id quoteId {get; set;}
    public Id productId {get; set;}
    public State state {get; set;}
    public String parentItemUID {get; set;}
    public WrikeQuoteProduct product {get; set;}

    public Boolean getIsAdded() {
        return this.state == WrikeQuoteItem.State.ADDED;
    }

    public Boolean getIsRemoved() {
        return this.state == WrikeQuoteItem.State.REMOVED;
    }

    public Boolean getIsExisting() {
        return this.state == WrikeQuoteItem.State.EXISTING;
    }

    public Boolean getRestoreAvailable() {
        return getIsRemoved() && product.getIsBillingPeriodValidForTerm();
    }

    public String getStateAsString() {
        if (this.state == null) {
            return null;
        }
        return this.state.name();
    }

    public void setStateAsString(String stateString) {
        this.state = nameToState.get(stateString);
    }

    public WrikeQuoteItem cloneItem(final Boolean resetIds) {
        WrikeQuoteItem wQuoteItem = (WrikeQuoteItem)this.clone();
        if (resetIds) {
            wQuoteItem.id = null;
        }
        if (wQuoteItem.product != null) {
            wQuoteItem.product = (WrikeQuoteProduct)this.product.clone();
            if (resetIds) {
                wQuoteItem.product.id = null;
            }
        }
        return wQuoteItem;
    }

    public String getUniqueString() {
        if (this.product == null) {
            return getStateAsString();
        }
        return getStateAsString() + this.product.getUniqueString();
    }

    public Integer compareTo(Object objectToCompareTo) {
        if (objectToCompareTo instanceof WrikeQuoteItem) {
            WrikeQuoteItem quoteItemCompareTo= (WrikeQuoteItem) objectToCompareTo;
            if (this.getUniqueString() == quoteItemCompareTo.getUniqueString()) {
                return 0;
            } else if (this.getUniqueString() > quoteItemCompareTo.getUniqueString()) {
                return 1;
            } else {
                return -1;
            }
        }
        return 0;
    }

    public String getUID() {
        return this.uid;
    }

    public enum State {
        ADDED,
        REMOVED,
        EXISTING
    }
}
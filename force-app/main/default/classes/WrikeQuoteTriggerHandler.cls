/*
 * Created by andrey.kuleshov on 05/06/2019.
 */
public class WrikeQuoteTriggerHandler {

	public static WrikeQuoteTriggerHandler getInstance() {
		return (WrikeQuoteTriggerHandler)ServiceLocator.getInstance(WrikeQuoteTriggerHandler.class);
	}

	public void afterInsert(final List<Quote__c> quotes) {
		QuoteService.getInstance().updateQuoteName(quotes, false);
	}

	public void beforeUpdate(final Map<Id, Quote__c> oldMap,
							 final Map<Id, Quote__c> newMap) {
		final QuoteService quoteSrv = QuoteService.getInstance();
		quoteSrv.updateQuoteName(newMap.values(), true);
		for(Id quoteId : newMap.keySet()) {
			final Quote__c newQuote = newMap.get(quoteId);
			final Quote__c oldQuote = oldMap.get(quoteId);
			if(newQuote.Status__c == WrikeQuote.Status.APPROVED.name()
					&& oldQuote.Status__c != WrikeQuote.Status.APPROVED.name()) {
				newQuote.CreditCardLink__c = Settings__c.getOrgDefaults().SiteUrl__c + 'payment/?q=' + WrikeUtil.encryptAndEncode(quoteId);
			}
		}
	}

	public void afterUpdate(final Map<Id, Quote__c> oldMap,
							final Map<Id, Quote__c> newMap) {
		final Set<Id> quoteIdToDeleteInWrike = new Set<Id>();
		final Map<Id, String> quoteIdToZuoraAccountId = new Map<Id, String>();
		for (Id quoteId : newMap.keySet()) {
			Quote__c newQuote = newMap.get(quoteId);
			Quote__c oldQuote = oldMap.get(quoteId);
			final Boolean isBecameDraft = oldQuote.Status__c == WrikeQuote.Status.TRIAL.name()
					&& newQuote.Status__c == WrikeQuote.Status.DRAFT.name();
			final Boolean isBecameCancel = newQuote.Status__c == WrikeQuote.Status.CANCEL.name()
					&& (oldQuote.Status__c == WrikeQuote.Status.TRIAL.name() || oldQuote.Status__c == WrikeQuote.Status.PROPOSAL.name());
			if (isBecameDraft || isBecameCancel) {
				quoteIdToDeleteInWrike.add(quoteId);
			}
			if (oldQuote.Status__c == WrikeQuote.Status.PROPOSAL.name()
					&& newQuote.Status__c == WrikeQuote.Status.SENT.name()) {
				quoteIdToZuoraAccountId.put(quoteId, newQuote.Zuora_Account_Id__c);
			}
		}
		final QuoteService quoteSrv = QuoteService.getInstance();
		quoteSrv.deleteQuotesInWrikeByIds(quoteIdToDeleteInWrike);
		quoteSrv.acceptQuoteInWrike(quoteIdToZuoraAccountId);
	}

	public void afterDelete(final Map<Id, Quote__c> oldMap) {
		QuoteService.getInstance().deleteQuotesInWrikeByIds(oldMap.keySet());
	}
}
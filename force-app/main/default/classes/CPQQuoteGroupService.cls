public class CPQQuoteGroupService {

    public static CPQQuoteGroupService getInstance() {
        return (CPQQuoteGroupService)ServiceLocator.getInstance(CPQQuoteGroupService.class);
    }

    public void restoreQuoteGroups(final SBQQ__Quote__c quote,
                                   final Date amendmentStartDate,
                                   final Boolean renewal) {
        final List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id,
                       SBQQ__EffectiveStartDate__c,
                       SBQQ__EarliestValidAmendmentStartDate__c,
                       SBQQ__EffectiveEndDate__c,
                       SubscriptionGroupId__c,
                       SBQQ__Group__c,
                       SBQQ__SubscriptionPercent__c,
                       GroupRestore__c,
                       SubscriptionNonRenewableDiscount__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quote.Id
                AND SubscriptionGroupId__c != null
                AND SBQQ__Group__c = null
                ORDER BY SBQQ__Number__c
        ];
        final Set<Id> subscriptionGroupIds = new Set<Id>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines) {
            subscriptionGroupIds.add(quoteLine.SubscriptionGroupId__c);
        }
        final Map<Id, SBQQ__QuoteLineGroup__c> subscriptionGroupsMap = new Map<Id, SBQQ__QuoteLineGroup__c> ([
                SELECT Id,
                        Name,
                        SBQQ__Number__c,
                        OriginalGroup__c,
                        SBQQ__StartDate__c,
                        SBQQ__EndDate__c,
                        SBQQ__AdditionalDiscountRate__c,
                        SBQQ__Description__c
                FROM SBQQ__QuoteLineGroup__c
                WHERE Id IN :subscriptionGroupIds
        ]);
        final Map<Id, SBQQ__QuoteLineGroup__c> clonedGroups = new Map<Id, SBQQ__QuoteLineGroup__c>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines) {
            final Id subscriptionGroupId = Id.valueOf(quoteLine.SubscriptionGroupId__c);
            if(!clonedGroups.containsKey(subscriptionGroupId) && quoteLine.GroupRestore__c) {
                final SBQQ__QuoteLineGroup__c subscriptionGroup = subscriptionGroupsMap.get(subscriptionGroupId);
                final Id originalGroupId = subscriptionGroup.OriginalGroup__c != null
                                         ? subscriptionGroup.OriginalGroup__c
                                         : subscriptionGroupId;
                final SBQQ__QuoteLineGroup__c clonedGroup = new SBQQ__QuoteLineGroup__c(
                        Name = subscriptionGroup.Name,
                        SBQQ__Quote__c = quote.Id,
                        OriginalGroup__c = originalGroupId,
                        SBQQ__Number__c = subscriptionGroup.SBQQ__Number__c,
                        SBQQ__AdditionalDiscountRate__c = subscriptionGroup.SBQQ__AdditionalDiscountRate__c,
                        SBQQ__Description__c = subscriptionGroup.SBQQ__Description__c
                );
                if(renewal) {
                    clonedGroup.SBQQ__StartDate__c = quote.SBQQ__StartDate__c;
                    clonedGroup.SBQQ__EndDate__c = quote.SBQQ__EndDate__c;
                } else {
                    final Date startDate = quoteLine.SBQQ__EarliestValidAmendmentStartDate__c > quoteLine.SBQQ__EffectiveStartDate__c
                                           ? quoteLine.SBQQ__EarliestValidAmendmentStartDate__c
                                           : quoteLine.SBQQ__EffectiveStartDate__c;
                    clonedGroup.SBQQ__StartDate__c = (amendmentStartDate > startDate) ? amendmentStartDate : startDate;
                    clonedGroup.SBQQ__EndDate__c = quoteLine.SBQQ__EffectiveEndDate__c;
                }
                clonedGroups.put(originalGroupId, clonedGroup);
            }
        }
        if(!clonedGroups.isEmpty()) {
            final List<SBQQ__QuoteLineGroup__c> groupsToCreate = new List<SBQQ__QuoteLineGroup__c>();
            groupsToCreate.addAll(clonedGroups.values());
            groupsToCreate.add(newGroup('Non-Recurring Products', quote.Id, clonedGroups.size() + 1, true));
            insert groupsToCreate;
            final List<SBQQ__QuoteLine__c> linesToUpdate = new List<SBQQ__QuoteLine__c>();
            final List<SBQQ__QuoteLine__c> linesToDelete = new List<SBQQ__QuoteLine__c>();
            for(SBQQ__QuoteLine__c quoteLine : quoteLines) {
                if(quoteLine.GroupRestore__c == true) {
                    final Id subscriptionGroupId = Id.valueOf(quoteLine.SubscriptionGroupId__c);
                    final SBQQ__QuoteLineGroup__c subscriptionGroup = subscriptionGroupsMap.get(subscriptionGroupId);
                    final Id originalGroupId = subscriptionGroup.OriginalGroup__c != null
                                             ? subscriptionGroup.OriginalGroup__c
                                             : subscriptionGroupId;
                    final SBQQ__QuoteLineGroup__c clonedGroup = clonedGroups.get(originalGroupId);
                    if(clonedGroup != null) {
                        final SBQQ__QuoteLine__c updatedQuoteLine = new SBQQ__QuoteLine__c(
                                Id = quoteLine.Id,
                                SBQQ__Group__c = clonedGroup.Id,
                                SBQQ__StartDate__c = null,
                                SBQQ__EndDate__c = null
                        );
                        if(!renewal) {
                            updatedQuoteLine.NonRenewableDiscount__c = quoteLine.SubscriptionNonRenewableDiscount__c;
                        }
                        if(quoteLine.SBQQ__SubscriptionPercent__c != null) {
                            updatedQuoteLine.SBQQ__SubscriptionScope__c = 'Group';
                        }
                        linesToUpdate.add(updatedQuoteLine);
                    }
                } else {
                    linesToDelete.add(quoteLine);
                }
            }
            if(!linesToUpdate.isEmpty()) {
                update linesToUpdate;
            }
            if(!linesToDelete.isEmpty()) {
                delete linesToDelete;
            }
        }
    }

    public SBQQ__QuoteLineGroup__c newGroup(final String name,
                                            final Id quoteId,
                                            final Decimal groupNumber,
                                            final Boolean oneTime) {
        return new SBQQ__QuoteLineGroup__c(
                Name = name,
                SBQQ__Quote__c = quoteId,
                SBQQ__Number__c = groupNumber,
                OneTime__c = oneTime
        );
    }
}
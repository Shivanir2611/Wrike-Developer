public class OFACCheckService {
    private final Logger log = Logger.create(OFACCheckService.class);

    public static OFACCheckService getInstance() {
        return (OFACCheckService)ServiceLocator.getInstance(OFACCheckService.class);
    }

    public void setOfacChecksForOrders(final List<Order> orders) {
        if (orders == null || orders.isEmpty()) {
            return;
        }
        final Set<Decimal> wrikeAccountIds =  new Set<Decimal>();
        for(Order order : orders) {
            if(order.WrikeAccountId__c != null) {
                wrikeAccountIds.add(order.WrikeAccountId__c);
            }
        }
        final Map<Decimal, Id> wrikeDataMap = getWrikeDataMap(wrikeAccountIds);
        setExistingOfacChecks(orders, wrikeAccountIds, wrikeDataMap);

        final Map<Id, OfacCheck__c> newChecks = new Map<Id, OfacCheck__c>();
        for (Order order : orders) {
            final Id wrikeDataId = wrikeDataMap.get(order.WrikeAccountId__c);
            if(order.BillToCheck__c == null && order.QS_Bill_To__c != null) {
                newChecks.put(order.QS_Bill_To__c, new OfacCheck__c(
                        BillToShipTo__c = order.QS_Bill_To__c,
                        WrikeAccountId__c = order.WrikeAccountId__c,
                        Type__c = 'BillToShipTo'
                ));
            }
            if(order.ShipToCheck__c == null && order.QS_Ship_To__c != null) {
                newChecks.put(order.QS_Ship_To__c, new OfacCheck__c(
                        BillToShipTo__c = order.QS_Ship_To__c,
                        WrikeAccountId__c = order.WrikeAccountId__c,
                        Type__c = 'BillToShipTo'
                ));
            }
            if(order.OwnerCheck__c == null && wrikeDataId != null) {
                final OfacCheck__c ownerCheck = new OfacCheck__c(
                        WrikeData__c = wrikeDataId,
                        WrikeAccountId__c = order.WrikeAccountId__c,
                        Type__c = 'Owner'
                );
                newChecks.put(wrikeDataId, ownerCheck);
            }
        }

        if (!newChecks.isEmpty()) {
            insert newChecks.values();
        }
        setOfacChecks(orders, newChecks, wrikeDataMap);
    }

    private void setExistingOfacChecks(final List<Order> orders,
                                       final Set<Decimal> wrikeAccountIds,
                                       final Map<Decimal, Id> wrikeDataMap) {
        final Map<Id, OfacCheck__c> checks = new Map<Id, OfacCheck__c>();
        for(OfacCheck__c check : [
                SELECT Id, WrikeAccountId__c, Type__c,
                       BillToShipTo__c, BillToShipTo__r.QS_Bill_To__c, WrikeData__c
                FROM OfacCheck__c
                WHERE WrikeAccountId__c IN :wrikeAccountIds
            ]) {
            if(check.Type__c == 'Owner') {
                checks.put(check.WrikeData__c, check);
            } else if(check.BillToShipTo__c != null) {
                checks.put(check.BillToShipTo__c, check);
            }
        }
        setOfacChecks(orders, checks, wrikeDataMap);
    }

    private void setOfacChecks(final List<Order> orders,
                               final Map<Id, OfacCheck__c> checkMap,
                               final Map<Decimal, Id> wrikeDataMap) {
        for(Order order : orders) {
            if(checkMap.containsKey(order.QS_Bill_To__c)) {
                order.BillToCheck__c = checkMap.get(order.QS_Bill_To__c).Id;
            }
            if(checkMap.containsKey(order.QS_Ship_To__c)) {
                order.ShipToCheck__c = checkMap.get(order.QS_Ship_To__c).Id;
            }
            final Id wrikeDataId = wrikeDataMap.get(order.WrikeAccountId__c);
            if(wrikeDataId != null) {
                if(checkMap.containsKey(wrikeDataId)) {
                    order.OwnerCheck__c = checkMap.get(wrikeDataId).Id;
                }
            }
        }
    }

    private Map<Decimal, Id> getWrikeDataMap(final Set<Decimal> wrikeAccountIds) {
        final Map<Decimal, Id> wrikeDataMap = new Map<Decimal,Id>();
        for(WrikeData__c wrikeData : [
                SELECT Id, Wrike_Account_Id__c
                FROM WrikeData__c
                WHERE Wrike_Account_Id__c IN : wrikeAccountIds
            ]) {
            wrikeDataMap.put(wrikeData.Wrike_Account_Id__c, wrikeData.Id);
        }
        return wrikeDataMap;
    }
}
public class BillToShipToQueryService {

    public static BillToShipToQueryService getInstance() {
        return (BillToShipToQueryService)ServiceLocator.getInstance(BillToShipToQueryService.class);
    }

    public QS_Bill_To_Ship_To__c findContact(final Id accountId,
                                             final Decimal wrikeAccountId,
                                             final String type) {
        final Boolean billTo = 'Bill To'.equalsIgnoreCase(type);
        final Boolean shipTo = 'Ship To'.equalsIgnoreCase(type);
        final Boolean endCustomer = 'End Customer'.equalsIgnoreCase(type);
        final List<QS_Bill_To_Ship_To__c> contacts = [
                SELECT Id, QS_Country_Code__c, QS_State_Code__c, QS_City__c, QS_Attention_To__c,
                       QS_Company_Name__c, QS_Email__c, QS_Zip_Postal_Code__c,
                       QS_Phone__c, QS_Street_1__c, QS_Street_2__c, QS_Invoice_via_Email__c, QS_Invoice_via_Portal__c,
                       Billing_Comments__c, QS_Secondary_Email__c, RegionState__c, QS_Bill_To__c, QS_Ship_To__c,
                       QS_Account__c, Wrike_Account_ID__c, VATNumber__c, EndCustomer__c
                  FROM QS_Bill_To_Ship_To__c
                 WHERE QS_Bill_To__c = :billTo
                   AND QS_Ship_To__c = :shipTo
                   AND EndCustomer__c = :endCustomer
                   AND QS_Account__c = :accountId
                   AND Wrike_Account_ID__c = :wrikeAccountId
              ORDER BY CreatedDate DESC
                 LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts.get(0);
    }

    public QS_Bill_To_Ship_To__c findLastContactByAccountId(final Id accountId,
                                                            final Boolean billTo,
                                                            final Boolean shipTo) {
        final List<QS_Bill_To_Ship_To__c> contacts = [
                SELECT Id, QS_Country_Code__c, QS_State_Code__c, QS_City__c, QS_Attention_To__c,
                        QS_Company_Name__c, QS_Email__c, QS_Zip_Postal_Code__c,
                        QS_Phone__c, QS_Street_1__c, QS_Street_2__c, QS_Invoice_via_Email__c, QS_Invoice_via_Portal__c,
                        Billing_Comments__c, QS_Secondary_Email__c, RegionState__c, QS_Bill_To__c, QS_Ship_To__c,
                        QS_Account__c, Wrike_Account_ID__c, VATNumber__c
                FROM QS_Bill_To_Ship_To__c
                WHERE QS_Account__c = :accountId
                AND QS_Bill_To__c = :billTo
                AND QS_Ship_To__c = :shipTo
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts.get(0);
    }

    public QS_Bill_To_Ship_To__c findContactByAccountIdAndPartnerAccountId(final Id accountId,
                                                                           final Id partnerAccountId,
                                                                           final Boolean billTo,
                                                                           final Boolean shipTo) {
        final List<QS_Bill_To_Ship_To__c> contacts = [
                SELECT Id, QS_Country_Code__c, QS_State_Code__c, QS_City__c, QS_Attention_To__c,
                        QS_Company_Name__c, QS_Email__c, QS_Zip_Postal_Code__c,
                        QS_Phone__c, QS_Street_1__c, QS_Street_2__c, QS_Invoice_via_Email__c, QS_Invoice_via_Portal__c,
                        Billing_Comments__c, QS_Secondary_Email__c, RegionState__c, QS_Bill_To__c, QS_Ship_To__c,
                        QS_Account__c, Wrike_Account_ID__c, VATNumber__c
                FROM QS_Bill_To_Ship_To__c
                WHERE QS_Account__c = :accountId
                AND PartnerAccount__c = :partnerAccountId
                AND QS_Bill_To__c = :billTo
                AND QS_Ship_To__c = :shipTo
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts.get(0);
    }

    public QS_Bill_To_Ship_To__c findContactById(final Id contactId) {
        final List<QS_Bill_To_Ship_To__c> contacts = [
                SELECT Id, QS_Country_Code__c, QS_State_Code__c, QS_City__c, QS_Attention_To__c,
                        QS_Company_Name__c, QS_Email__c, QS_Zip_Postal_Code__c,
                        QS_Phone__c, QS_Street_1__c, QS_Street_2__c, QS_Invoice_via_Email__c, QS_Invoice_via_Portal__c,
                        Billing_Comments__c, QS_Secondary_Email__c, RegionState__c, QS_Bill_To__c, QS_Ship_To__c,
                        QS_Account__c, Wrike_Account_ID__c
                FROM QS_Bill_To_Ship_To__c
                WHERE Id = :contactId
        ];
        return contacts.isEmpty() ? null : contacts.get(0);
    }

    public List<QS_Bill_To_Ship_To__c> findBillToFromContractsByWrikeAccountId(final Decimal wrikeAccountId) {
        final List<Contract> contracts = [
                SELECT QS_Bill_To__r.Id, QS_Bill_To__r.QS_Country_Code__c, QS_Bill_To__r.QS_State_Code__c,
                       QS_Bill_To__r.QS_City__c, QS_Bill_To__r.QS_Attention_To__c, QS_Bill_To__r.QS_Company_Name__c,
                       QS_Bill_To__r.QS_Email__c, QS_Bill_To__r.QS_Zip_Postal_Code__c, QS_Bill_To__r.QS_Phone__c,
                       QS_Bill_To__r.QS_Street_1__c, QS_Bill_To__r.QS_Street_2__c, QS_Bill_To__r.QS_Invoice_via_Email__c,
                       QS_Bill_To__r.QS_Invoice_via_Portal__c, QS_Bill_To__r.Billing_Comments__c,
                       QS_Bill_To__r.QS_Secondary_Email__c, QS_Bill_To__r.RegionState__c
                FROM Contract
                WHERE Wrike_Account_ID__c = :wrikeAccountId
                  AND Status = 'Activated'
                  AND QS_Bill_To__c != null
                ORDER BY CreatedDate DESC
        ];
        final List<QS_Bill_To_Ship_To__c> billToList = new List<QS_Bill_To_Ship_To__c>();
        for (Contract contract : contracts) {
            billToList.add(contract.QS_Bill_To__r);
        }
        return billToList;
    }

    public Set<Id> listContractBillToShipToIds(final Decimal wrikeAccountId) {
        final List<Contract> contracts = [
                SELECT Id, QS_Bill_To__c, QS_Ship_To__c
                FROM Contract
                WHERE Wrike_Account_ID__c = :wrikeAccountId
                  AND Status = 'Activated'
        ];
        final Set<Id> billToShipToIds = new Set<Id>();
        for(Contract contract : contracts) {
            if(contract.QS_Bill_To__c != null) {
                billToShipToIds.add(contract.QS_Bill_To__c);
            }
            if(contract.QS_Ship_To__c != null) {
                billToShipToIds.add(contract.QS_Ship_To__c);
            }
        }
        return billToShipToIds;
    }
}
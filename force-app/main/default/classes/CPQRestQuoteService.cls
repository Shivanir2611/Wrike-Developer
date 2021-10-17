public class CPQRestQuoteService {

    public static CPQRestQuoteService getInstance() {
        return (CPQRestQuoteService)ServiceLocator.getInstance(CPQRestQuoteService.class);
    }

    public Id findOrCreateAccountByWrikeAccountId(final Decimal wrikeAccountId, final String accountName) {
        final List<Opportunity> opportunities = [
                SELECT AccountId
                FROM Opportunity
                WHERE Wrike_Account_Id__c = :wrikeAccountId
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];
        if(!opportunities.isEmpty()) {
            return opportunities.get(0).AccountId;
        }
        final Account acc = new Account(
                Name = accountName.left(255),
                eCommerce__c = true,
                RecordTypeId = Schema.Account.getSObjectType()
                        .getDescribe()
                        .getRecordTypeInfosByName()
                        .get('Customer')
                        .getRecordTypeId()
        );
        insert acc;
        return acc.Id;
    }

    public Id createBillToShipTo(final CPQRestService.CPQRestBillToShipTo billToShipTo,
                                  final Id accountId,
                                  final Decimal wrikeAccountId,
                                  final Boolean billTo) {
        final QS_Bill_To_Ship_To__c record = mapToRecord(billToShipTo);
        record.QS_Account__c = accountId;
        record.Wrike_Account_ID__c = wrikeAccountId;
        if(billTo) {
            record.QS_Bill_To__c = true;
        } else {
            record.QS_Ship_To__c = true;
        }
        insert record;
        return record.Id;
    }

    public QS_Bill_To_Ship_To__c mapToExistingRecord(final Id recordId,
                                                     final CPQRestService.CPQRestBillToShipTo billToShipTo) {
        final QS_Bill_To_Ship_To__c record = mapToRecord(billToShipTo);
        record.Id = recordId;
        return record;
    }

    private QS_Bill_To_Ship_To__c mapToRecord(final CPQRestService.CPQRestBillToShipTo billToShipTo) {
        final QS_Bill_To_Ship_To__c record = new QS_Bill_To_Ship_To__c();
        record.QS_Attention_To__c = billToShipTo.userName;
        record.QS_Company_Name__c = billToShipTo.companyName;
        record.QS_Email__c = billToShipTo.email;
        record.QS_Phone__c = billToShipTo.phone;
        record.QS_Country_Code__c = billToShipTo.countryCode;
        record.QS_Country__c = CountryUtil.getCountryCodeMap().get(billToShipTo.countryCode);
        if (String.isNotBlank(billToShipTo.stateCode)) {
            record.QS_State_Code__c = billToShipTo.stateCode;
            if(billToShipTo.countryCode == 'US') {
                record.RegionState__c = CountryUtil.getUsIsoStates().get(billToShipTo.stateCode);
            } else if(billToShipTo.countryCode == 'CA') {
                record.RegionState__c = CountryUtil.getCanadaIsoStates().get(billToShipTo.stateCode);
            } else {
                record.RegionState__c = null;
            }
        } else if (String.isNotBlank(billToShipTo.stateName)) {
            record.RegionState__c = billToShipTo.stateName;
        } else {
            record.RegionState__c = null;
        }
        record.QS_City__c = billToShipTo.city;
        record.QS_Zip_Postal_Code__c = billToShipTo.postalCode;
        record.QS_Street_1__c = billToShipTo.address1;
        record.QS_Street_2__c = billToShipTo.address2;
        return record;
    }
}
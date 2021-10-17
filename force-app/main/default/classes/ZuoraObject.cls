public abstract class ZuoraObject {

    public static final String EVERGREEN = 'EVERGREEN';
    public static final String REMOVED_TYPE = 'Remove';

    private static final Map<Type, Map<String, String>> FieldReplaceMap = new Map<Type, Map<String, String>>{
        ZuoraContact.class => new Map<String, String>{
            'companyName' => 'Company__c'
        },
        ZuoraAccount.class => new Map<String, String>{
            'currencyCode' => 'Currency',
            'vatNumber' => 'VatNumber__c',
            'companyName' => 'Company__c'
        },
        ZuoraProduct.class => new Map<String, String>{
            'serviceType' => 'serviceType__c'
        },
        ZuoraSubscription.class => new Map<String, String>{
            'purchaseOrderNumber' => 'PurchaseOrderNumber__c'
        }
    };

    public Set<String> fieldsToNull {get; set;}

    public virtual Type getObjectType() {
        return ZuoraObject.class;
    }

    public Map<String, Object> getFieldValueMap() {
        final Map<String, Object> fieldValueMap =
                (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(this, true));
        final Map<String, Object> fieldValueMapReplaced = new Map<String, Object>();
        final Map<String, String> fieldReplaceMap = FieldReplaceMap.get(getObjectType());

        for (String fieldName : fieldValueMap.keySet()) {
            final Object fieldValue = fieldValueMap.get(fieldName);
            final String fieldNameReplaced;
            if (fieldReplaceMap != null && fieldReplaceMap.containsKey(fieldName)) {
                fieldNameReplaced = fieldReplaceMap.get(fieldName);
            } else if (fieldName == 'fieldsToNull') {
                fieldNameReplaced = fieldName;
            } else {
                fieldNameReplaced = fieldName.capitalize();
            }
            fieldValueMapReplaced.put(fieldNameReplaced, fieldValue);
        }
        return fieldValueMapReplaced;
    }

    public Map<String, String> getFieldReplaceMap() {
        return FieldReplaceMap.get(getObjectType());
    }

    public class ZuoraInvoice extends ZuoraObject {
        public String id {get; set;}
        public String accountId {get; set;}
        public String invoiceDate {get; set;}
        public String targetDate {get; set;}
        public String status {get; set;}

        public override Type getObjectType() {
            return ZuoraInvoice.class;
        }
    }

    public class ZuoraAccount extends ZuoraObject {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        public String accountNumber {get; set;}
        public String status {get; set;}
        public String crmId {get; set;}
        public String currencyCode {get; set;}
        public String soldToId {get; set;}
        public String vatNumber {get; set;}
        public String defaultPaymentMethodId {get; set;}
        public String billToId {get; set;}
        public String paymentTerm {get; set;}
        public String communicationProfileId {get; set;}
        public Boolean autoPay {get; set;}
        public String taxExemptStatus {get; set;}
        public String taxExemptCertificateID {get; set;}
        public String companyName {get; set;}

        public override Type getObjectType() {
            return ZuoraAccount.class;
        }
    }

    public virtual class ZuoraSubscription extends ZuoraObject {
        public String id {get; set;}
        public String name {get; set;}
        public String subscriptionNumber {get; set;}
        public String accountId {get; set;}
        public String accountName {get; set;}
        public String status {get; set;}
        public String termType {get; set;}
        public Date contractEffectiveDate {get; set;}
        public Integer currentTerm {get; set;}
        public Integer renewalTerm {get; set;}
        public Date termStartDate {get; set;}
        @AuraEnabled
        public Date termEndDate {get; set;}
        @AuraEnabled
        public Date subscriptionStartDate {get; set;}
        public Date subscriptionEndDate {get; set;}
        public String previousSubscriptionId {get; set;}
        public Date cancelledDate {get; set;}
        public String purchaseOrderNumber {get; set;}

        public Boolean isEvergreen() {
            return this.termType == EVERGREEN;
        }

        public override Type getObjectType() {
            return ZuoraSubscription.class;
        }
    }

    public class ZuoraSubscriptionProduct extends ZuoraProduct {
        public String chargeType {get; set;}
        public String chargeModel {get; set;}
        public String chargeNumber {get; set;}
        @AuraEnabled
        public Decimal mrr {get; set;}
        public String ratePlanChargeId {get; set;}
        @AuraEnabled
        public String ratePlanChargeName {get; set;}
        public String productRatePlanId {get; set;}
        public String productRatePlanChargeId {get; set;}
        @AuraEnabled
        public Decimal quantity {get; set;}
        public String ratePlanId {get; set;}
        public String billingPeriod {get; set;}
        public Decimal price {get; set;}
    }

    public virtual class ZuoraContact extends ZuoraObject {
        public String id {get; set;}
        public String accountId {get; set;}
        public String firstName {get; set;}
        public String lastName {get; set;}
        public String city {get; set;}
        public String address1 {get; set;}
        public String address2 {get; set;}
        public String state {get; set;}
        public String country {get; set;}
        public String workEmail {get; set;}
        public String postalCode {get; set;}
        public String companyName {get; set;}

        public override Type getObjectType() {
            return ZuoraContact.class;
        }
    }

    public class ZuoraContactWithCompanyName extends ZuoraContact {
        public String companyName {get; set;}
    }

    public virtual class ZuoraProduct extends ZuoraObject implements ZuoraProductCatalogService.Mapable, Comparable {
        public String id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        public String serviceType {get; set;}
        public String description {get; set;}
        public String sku {get; set;}

        public Boolean isSeatOrAddon() {
            ZuoraProductService zuoraProductSrv = ZuoraProductService.getInstance();
            return zuoraProductSrv.isSeat(this.serviceType)
                    || zuoraProductSrv.isProofingAddon(this.serviceType)
                    || zuoraProductSrv.isAdvancedFeatureAddon(this.serviceType);
        }

        public override Type getObjectType() {
            return ZuoraProduct.class;
        }

        public String getKeyField() {
            return this.id;
        }

        public Integer compareTo(final Object other) {
            if(other == null) {
                return 1;
            }
            return StringUtils.getEmptyIfNull(this.name).compareTo(((ZuoraProduct)other).name);
        }
    }

    public virtual class ZuoraRatePlan extends ZuoraObject implements ZuoraProductCatalogService.Mapable, Comparable {
        public String id {get; set;}
        public String name {get; set;}
        public String description {get; set;}
        public String ratePlanName {get; set;}
        public String productId {get; set;}
        public String productName {get; set;}
        public String productRatePlanId {get; set;}
        public String lastChangeType {get; set;}

        public boolean wasRemovedFromSubscription() {
            return REMOVED_TYPE.equals(lastChangeType);
        }

        public override Type getObjectType() {
            return ZuoraRatePlan.class;
        }

        public String getKeyField() {
            return this.productId;
        }

        public virtual Integer compareTo(final Object other) {
            if(other == null) {
                return 1;
            }
            return StringUtils.getEmptyIfNull(this.name).compareTo(((ZuoraRatePlan)other).name);
        }
    }

    public virtual class ZuoraRatePlanCharge extends ZuoraObject implements ZuoraProductCatalogService.Mapable {
        public String id {get; set;}
        public String name {get; set;}
        public String description {get; set;}
        public Decimal quantity {get; set;}
        public Decimal mrr {get; set;}
        public String type {get; set;}
        public String model {get; set;}
        public String productRatePlanId {get; set;}
        public String productRatePlanChargeId {get; set;}
        public String listPriceBase {get; set;}
        public String billingPeriod {get;set;}
        public Integer segment {get;set;}
        public String chargeModel {get; set;}
        public String chargeType {get; set;}
        public String chargeNumber {get; set;}

        public override Type getObjectType() {
            return ZuoraRatePlanCharge.class;
        }

        public String getKeyField() {
            return this.productRatePlanId;
        }
    }

    public class ZuoraRatePlanChargeTier extends ZuoraObject implements Comparable, ZuoraProductCatalogService.Mapable {
        public String id {get; set;}
        public Decimal price {get; set;}
        public Decimal startingUnit {get; set;}
        public Decimal endingUnit {get; set;}
        public Integer tier {get; set;}
        public String priceFormat {get; set;}
        public String productRatePlanChargeId {get; set;}

        public Integer compareTo(Object objectToCompareTo) {
            ZuoraRatePlanChargeTier tierToCompareTo = (ZuoraRatePlanChargeTier)objectToCompareTo;
            return this.tier - tierToCompareTo.tier;
        }

        public Boolean isPerUnit() {
            return 'Per Unit' == this.priceFormat || 'PerUnit' == this.priceFormat;
        }

        public override Type getObjectType() {
            return ZuoraRatePlanChargeTier.class;
        }

        public String getKeyField() {
            return this.productRatePlanChargeId;
        }
    }

    public class ZuoraAmendment extends ZuoraObject {
        public String id {get; set;}
        public String name {get; set;}
        public String createdById {get; set;}
        @AuraEnabled
        public DateTime createdDate {get; set;}
        public Date cancelledDate {get; set;}
        @AuraEnabled
        public Date effectiveDate {get; set;}

        public override Type getObjectType() {
            return ZuoraAmendment.class;
        }
    }

    public class ZuoraPaymentMethod extends ZuoraObject {
        public String id {get; set;}
        public String email {get; set;}
        public String creditCardHolderName {get; set;}
        public String creditCardCountry {get; set;}
        public String creditCardState {get; set;}
        public String creditCardCity {get; set;}
        public String creditCardAddress1 {get; set;}
        public String creditCardAddress2 {get; set;}
        public String creditCardPostalCode {get; set;}
        public String creditCardMaskNumber {get; set;}
        public Integer creditCardExpirationMonth {get; set;}
        public Integer creditCardExpirationYear {get; set;}

        public override Type getObjectType() {
            return ZuoraPaymentMethod.class;
        }
    }

    public class ZuoraSubscriptionWithRatePlans extends ZuoraSubscription {
        public List<ZuoraRatePlanWithCharges> ratePlans {get; set;}
    }

    public class ZuoraRatePlanWithCharges extends ZuoraRatePlan {
        public List<ZuoraRatePlanChargeWithTiers> ratePlanCharges {get; set;}
    }

    public class ZuoraRatePlanChargeWithTiers extends ZuoraRatePlanCharge {
        public List<ZuoraObject.ZuoraRatePlanChargeTier> tiers {get; set;}
    }
}
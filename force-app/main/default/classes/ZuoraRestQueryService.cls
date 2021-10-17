/**
 * @author anna.goreslavskaya
 */
public class ZuoraRestQueryService {

    public static ZuoraRestQueryService getInstance() {
        return (ZuoraRestQueryService)ServiceLocator.getInstance(ZuoraRestQueryService.class);
    }

    public static final String RECURRING = 'Recurring';

    private final ZuoraRestApi zuoraApi = ZuoraRestApi.getInstance();

    public ZuoraObject.ZuoraAccount findZuoraAccountById(final String zuoraAccountId) {
        final String zoql = 'SELECT Status, DefaultPaymentMethodId, BillToId, SoldToId, VatNumber__c FROM Account WHERE Id =\'' + zuoraAccountId + '\'';
        final List<ZuoraObject.ZuoraAccount> accounts = (List<ZuoraObject.ZuoraAccount>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraAccount>.class);
        if (accounts == null || accounts.isEmpty()) {
            return null;
        }
        return accounts[0];
    }

    public ZuoraObject.ZuoraAccount findZuoraAccountByWrikeAccountId(final Decimal wrikeAccountId) {
        final String zoql =
                'SELECT Id, Name, Status, CrmId, AccountNumber, Currency\n' +
                'FROM Account\n' +
                'WHERE AccountNumber =\'' + String.valueOf(wrikeAccountId) + '\'';
            final List<ZuoraObject.ZuoraAccount> zAccounts = (List<ZuoraObject.ZuoraAccount>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraAccount>.class);
            if (zAccounts == null || zAccounts.isEmpty()) {
                return null;
            }
            return zAccounts[0];
        }

        public String findZuoraAccountIdByWrikeAccountId(final Decimal wrikeAccountId) {
        final ZuoraObject.ZuoraAccount zuoraAccount = findZuoraAccountByWrikeAccountId(wrikeAccountId);
        return zuoraAccount != null ? zuoraAccount.id : null;
    }

    public List<ZuoraObject.ZuoraSubscription> findSubscriptionsByZuoraAccountId(final String zuoraAccountId) {
        final String zoql =
                'SELECT Id, Name, AccountId, Status, ContractEffectiveDate, TermType, CurrentTerm, ' +
                'RenewalTerm, TermStartDate, TermEndDate, SubscriptionEndDate, SubscriptionStartDate\n' +
                'FROM Subscription ' +
                'WHERE Status = \'Active\' AND AccountId = \'' + zuoraAccountId + '\'';
        final List<ZuoraObject.ZuoraSubscription> subscriptions =
                (List<ZuoraObject.ZuoraSubscription>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraSubscription>.class);
        return subscriptions;
    }

    public ZuoraObject.ZuoraAmendment findAmendmentChangedSubscriptionTo(final String subscriptionId) {
        final ZuoraObject.ZuoraSubscription originalSubscription = findSubscriptionById(subscriptionId);
        ZuoraObject.ZuoraAmendment cancelAmendment = findAmendmentBySubscriptionId(originalSubscription.previousSubscriptionId);
        cancelAmendment.cancelledDate = originalSubscription.cancelledDate;
        return cancelAmendment;
    }

    @TestVisible
    private ZuoraObject.ZuoraSubscription findSubscriptionById(final String subscriptionId) {
        final String zoql =
                'SELECT Id, Name, CancelledDate, PreviousSubscriptionId, AccountId, Status, ContractEffectiveDate, CurrentTerm, RenewalTerm, TermEndDate ' +
                'FROM Subscription ' +
                'WHERE Id = \'' + subscriptionId + '\'';
        final List<ZuoraObject.ZuoraSubscription> subscriptions =
                (List<ZuoraObject.ZuoraSubscription>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraSubscription>.class);
        return subscriptions.isEmpty() ? null : subscriptions.get(0);
    }

    @TestVisible
    private ZuoraObject.ZuoraAmendment findAmendmentBySubscriptionId(final String subscriptionId) {
        final String zoql =
                'SELECT Id, Name, CreatedById, CreatedDate, EffectiveDate ' +
                'FROM Amendment ' +
                'WHERE SubscriptionId = \'' + subscriptionId + '\'';
        final List<ZuoraObject.ZuoraAmendment> amendments = (List<ZuoraObject.ZuoraAmendment>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraAmendment>.class);
        System.assertEquals(1, amendments.size(), StringUtils.format('Amendment for subscription with id = {0} not found.', subscriptionId));
        return amendments.get(0);
    }

    public List<ZuoraObject.ZuoraProduct> findProductsByIds(final Set<String> ids) {
        final String productFilter = String.join(new List<String>(ids), '\' OR Id=\'');
        final String zoql = 'SELECT Id, Name, Description, serviceType__c ' +
                'FROM Product ' +
                'WHERE Id=\'' + productFilter + '\'';
        final List<ZuoraObject.ZuoraProduct> products =
                (List<ZuoraObject.ZuoraProduct>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraProduct>.class);
        return products;
    }

    public String getCheckPaymentMethodId(String checkPaymentMethodId) {
        if (checkPaymentMethodId != null) {
            return checkPaymentMethodId;
        }

        final String zoql = 'SELECT Id FROM PaymentMethod WHERE Type = \'Check\' AND AccountId = NULL';
        final List<ZuoraObject.ZuoraPaymentMethod> checkPaymentMethods =
                (List<ZuoraObject.ZuoraPaymentMethod>)zuoraApi.query(zoql,
                                List<ZuoraObject.ZuoraPaymentMethod>.class);

        if (checkPaymentMethods != null && !checkPaymentMethods.isEmpty()) {
            return checkPaymentMethods.get(0).id;
        }
        return null;
    }

    public Map<String, ZuoraObject.ZuoraContact> findContactMap(final String zuoraAccountId) {
        final List<ZuoraObject.ZuoraContact> contacts = (List<ZuoraObject.ZuoraContact>)zuoraApi.query(
                        'SELECT Id, WorkEmail, Country, State FROM Contact WHERE WorkEmail != null AND AccountId = \'' +
                        zuoraAccountId + '\'', List<ZuoraObject.ZuoraContact>.class);
        final Map<String, ZuoraObject.ZuoraContact> contactMap = new Map<String, ZuoraObject.ZuoraContact>();
        for (ZuoraObject.ZuoraContact contact : contacts) {
            contactMap.put(contact.workEmail, contact);
        }
        return contactMap;
    }

    public List<ZuoraObject.ZuoraSubscriptionWithRatePlans> findAllSubscriptionsByZuoraAccountId(final String zuoraAccountId) {
        final String query = '/v1/subscriptions/accounts/' + zuoraAccountId;
        final Map<String, String> additionalParams = new Map<String, String> {
        'charge-detail' => 'last-segment'
        };

        final List<ZuoraObject.ZuoraSubscriptionWithRatePlans> allSubscriptions =
                (List<ZuoraObject.ZuoraSubscriptionWithRatePlans>)ZuoraRestApi.getInstance().createGetRequest(
                        query)
                        .setParameters(additionalParams)
                        .setResponseParser(JsonApi.parseField('subscriptions',
                                List<ZuoraObject.ZuoraSubscriptionWithRatePlans>.class).required().parser())
                        .execute();

        return allSubscriptions;
    }

    public ZuoraObject.ZuoraAccount findAccountSoldToIdAndVatNumber(final String zuoraAccountId) {
        final List<ZuoraObject.ZuoraAccount> accounts = (List<ZuoraObject.ZuoraAccount>)zuoraApi.query(
                        'SELECT SoldToId, VatNumber__c FROM Account WHERE Id =\'' + zuoraAccountId + '\'',
                        List<ZuoraObject.ZuoraAccount>.class);
        return accounts.isEmpty() ? null : accounts.get(0);
    }

    public ZuoraObject.ZuoraContact findBillingContact(final String zuoraSoldToContactId, final String zuoraAccountId) {
        final String whereFilter = String.isNotBlank(zuoraSoldToContactId)
                                   ? ('Id = \'' + zuoraSoldToContactId + '\'')
                                   : ('AccountId = \'' + zuoraAccountId + '\' AND WorkEmail != NULL');
        final List<ZuoraObject.ZuoraContact> contacts = (List<ZuoraObject.ZuoraContact>)zuoraApi.query(
                        'SELECT Id, FirstName, LastName, WorkEmail, Country, Address1, Address2, City, State, PostalCode ' +
                        'FROM Contact WHERE ' + whereFilter, List<ZuoraObject.ZuoraContact>.class);
        return contacts.isEmpty() ? null : contacts.get(0);
    }

    public List<ZuoraObject.ZuoraProduct> findProductsByEffectiveEndDate(final String effectiveEndDate) {
        final String zoql = 'SELECT Id, Name, Description, serviceType__c, SKU FROM Product ' +
                'WHERE EffectiveEndDate > \'' + effectiveEndDate + '\' AND salesQuotes__c = \'Enabled\'';
        final List<ZuoraObject.ZuoraProduct> products =
                (List<ZuoraObject.ZuoraProduct>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraProduct>.class);
        return products;
    }

    public List<ZuoraObject.ZuoraProduct> findAllProductsByEffectiveEndDate(final String effectiveEndDate) {
        final String zoql = 'SELECT Id, Name, Description, serviceType__c, SKU FROM Product ' +
                'WHERE EffectiveEndDate > \'' + effectiveEndDate + '\'';
        final List<ZuoraObject.ZuoraProduct> products =
                (List<ZuoraObject.ZuoraProduct>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraProduct>.class);
        return products;
    }

    public List<ZuoraObject.ZuoraRatePlan> findProductRatePlansByEffectiveEndDate(final String effectiveEndDate) {
        final String zoql = 'SELECT Id, Name, Description, ProductId FROM ProductRatePlan WHERE EffectiveEndDate > \'' +
                effectiveEndDate + '\'';
        final List<ZuoraObject.ZuoraRatePlan> ratePlans =
                (List<ZuoraObject.ZuoraRatePlan>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraRatePlan>.class);
        return ratePlans;
    }

    public List<ZuoraObject.ZuoraRatePlan> findProductRatePlansByEffectiveEndDateAndProductId(final String effectiveEndDate, final String productId) {
        final String zoql = 'SELECT Id, Name, Description FROM ProductRatePlan WHERE EffectiveEndDate > \'' +
                effectiveEndDate + '\' AND ProductId = \'' + productId + '\'';
        final List<ZuoraObject.ZuoraRatePlan> ratePlans =
                (List<ZuoraObject.ZuoraRatePlan>) zuoraApi.query(zoql, List<ZuoraObject.ZuoraRatePlan>.class);
        return ratePlans;
    }

    public List<ZuoraObject.ZuoraRatePlanCharge> findProductsRatePlanCharges() {
        final String zoql =
                'SELECT Id, Name, BillingPeriod, ChargeModel, ChargeType, ProductRatePlanId, ListPriceBase FROM ProductRatePlanCharge';
        final List<ZuoraObject.ZuoraRatePlanCharge> ratePlanCharges =
                (List<ZuoraObject.ZuoraRatePlanCharge>) zuoraApi.query(zoql,
                                List<ZuoraObject.ZuoraRatePlanCharge>.class);
        return ratePlanCharges;
    }

    public List<ZuoraObject.ZuoraRatePlanCharge> findRatePlanChargesByProductRatePlanChargeIds(final List<String> ids) {
        String zoql =
                'SELECT Id, ProductRatePlanChargeId, ChargeNumber FROM RatePlanCharge WHERE ';
        for (Integer i = 0; i < ids.size(); i++) {
            zoql += ' ProductRatePlanChargeId = \'' + ids[i] + '\' ';
            if (i != ids.size() - 1) {
                zoql += ' OR ';
            }
        }
        final List<ZuoraObject.ZuoraRatePlanCharge> ratePlanCharges = (List<ZuoraObject.ZuoraRatePlanCharge>) zuoraApi.query(zoql,
                List<ZuoraObject.ZuoraRatePlanCharge>.class);
        return ratePlanCharges;
    }

    public List<ZuoraObject.ZuoraRatePlanChargeTier> findProductsRatePlanChargeTiersByCurrency(final ZuoraCurrency currencyCode) {
        final String zoql = 'SELECT Id, StartingUnit, EndingUnit, Price, PriceFormat, Tier, ProductRatePlanChargeId ' +
                'FROM ProductRatePlanChargeTier ' +
                'WHERE Currency = \'' + currencyCode + '\'';
        final List<ZuoraObject.ZuoraRatePlanChargeTier> ratePlanChargeTiers =
                (List<ZuoraObject.ZuoraRatePlanChargeTier>) zuoraApi.query(zoql,
                                List<ZuoraObject.ZuoraRatePlanChargeTier>.class);
        return ratePlanChargeTiers;
    }

    public String getAccountNameById(final String accountId) {
        final String zoql = 'SELECT Id, Name FROM Account WHERE Id = \'' + accountId + '\'';
        final List<ZuoraObject.ZuoraAccount> accounts =
                (List<ZuoraObject.ZuoraAccount>)zuoraApi.query(zoql, List<ZuoraObject.ZuoraAccount>.class);
        return accounts.isEmpty() ? null : accounts.get(0).name;
    }

    public List<ZuoraObject.ZuoraSubscriptionProduct> listSubscriptionProducts(final String subscriptionId) {
        final List<ZuoraObject.ZuoraSubscriptionProduct> subscriptionProducts = new List<ZuoraObject.ZuoraSubscriptionProduct>();
        final List<ZuoraObject.ZuoraRatePlan> ratePlans = (List<ZuoraObject.ZuoraRatePlan>)zuoraApi.query(
                'SELECT Id, Name, ProductRatePlanId ' +
                        'FROM RatePlan ' +
                        'WHERE SubscriptionId = \'' + subscriptionId + '\'',
                List<ZuoraObject.ZuoraRatePlan>.class);
        for (ZuoraObject.ZuoraRatePlan ratePlan : ratePlans) {
            final List<ZuoraObject.ZuoraRatePlanCharge> ratePlanCharges = (List<ZuoraObject.ZuoraRatePlanCharge>)zuoraApi.query(
                    'SELECT Id, Name, Quantity, MRR, ChargeType, ChargeModel, ChargeNumber, ProductRatePlanChargeId, ListPriceBase ' +
                            'FROM RatePlanCharge ' +
                            'WHERE IsLastSegment = true AND RatePlanId = \'' + ratePlan.id +
                            '\' AND ChargeType = \'' + RECURRING + '\'',
                    List<ZuoraObject.ZuoraRatePlanCharge>.class);

            if (ratePlanCharges.isEmpty()) {
                continue;
            }

            final List<ZuoraObject.ZuoraRatePlanChargeTier> ratePlanChargeTiers = (List<ZuoraObject.ZuoraRatePlanChargeTier>)zuoraApi.query(
                    'SELECT Id, Price, StartingUnit, EndingUnit, Tier, PriceFormat ' +
                            'FROM RatePlanChargeTier ' +
                            'WHERE RatePlanChargeId = \'' + ratePlanCharges[0].id + '\'',
                    List<ZuoraObject.ZuoraRatePlanChargeTier>.class);
            final List<ZuoraObject.ZuoraRatePlan> productRatePlans = (List<ZuoraObject.ZuoraRatePlan>)zuoraApi.query(
                    'SELECT Id, Name, Description, ProductId ' +
                            'FROM ProductRatePlan ' +
                            'WHERE Id=\'' + ratePlan.productRatePlanId + '\'',
                    List<ZuoraObject.ZuoraRatePlan>.class);
            final List<ZuoraObject.ZuoraProduct> product = findProductsByIds(new Set<String>{productRatePlans[0].productId});
            final List<ZuoraObject.ZuoraRatePlanCharge> productRatePlanCharges =
                    (List<ZuoraObject.ZuoraRatePlanCharge>)zuoraApi.query(
                            'SELECT Id, BillingPeriod, ProductRatePlanId ' +
                                    'FROM ProductRatePlanCharge ' +
                                    'WHERE ProductRatePlanId=\'' + productRatePlans[0].id + '\'',
                            List<ZuoraObject.ZuoraRatePlanCharge>.class);

            final ZuoraObject.ZuoraSubscriptionProduct subscriptionProduct = new ZuoraObject.ZuoraSubscriptionProduct();
            subscriptionProduct.id = product[0].id;
            subscriptionProduct.name = product[0].name;
            subscriptionProduct.description = productRatePlans[0].description;
            subscriptionProduct.serviceType = product[0].serviceType;
            subscriptionProduct.ratePlanId = ratePlan.id;
            subscriptionProduct.ratePlanChargeId = ratePlanCharges[0].id;
            subscriptionProduct.ratePlanChargeName = ratePlanCharges[0].name;
            subscriptionProduct.productRatePlanId = ratePlan.productRatePlanId;
            subscriptionProduct.productRatePlanChargeId = ratePlanCharges[0].productRatePlanChargeId;
            subscriptionProduct.quantity = ratePlanCharges[0].quantity;
            subscriptionProduct.mrr = ratePlanCharges[0].mrr;
            subscriptionProduct.chargeType = ratePlanCharges[0].chargeType;
            subscriptionProduct.chargeModel = ratePlanCharges[0].chargeModel;
            subscriptionProduct.chargeNumber = ratePlanCharges[0].chargeNumber;
            subscriptionProduct.billingPeriod = productRatePlanCharges[0].billingPeriod;

            if (subscriptionProduct.chargeModel == 'Flat Fee Pricing' && ratePlanChargeTiers.size() == 1) {
                subscriptionProduct.price = ratePlanChargeTiers[0].price;
            } else {
                for (ZuoraObject.ZuoraRatePlanChargeTier tier : ratePlanChargeTiers) {
                    Integer startUnit = Integer.valueOf(tier.startingUnit);
                    Integer endUnit = Integer.valueOf(tier.endingUnit);
                    String priceFormat = tier.priceFormat;
                    Boolean isQuantityInInterval = subscriptionProduct.quantity >= startUnit
                            && (endUnit == null || subscriptionProduct.quantity <= endUnit);
                    if(isQuantityInInterval) {
                        if(priceFormat == 'FlatFee' || priceFormat == 'Flat Fee') {
                            subscriptionProduct.price = tier.price;
                        } else if(priceFormat == 'PerUnit' || priceFormat == 'Per Unit') {
                            subscriptionProduct.price = tier.price * subscriptionProduct.quantity;
                        }
                    }
                }
            }

            subscriptionProducts.add(subscriptionProduct);
        }
        return subscriptionProducts;
    }

    public List<ZuoraObject.ZuoraAccount> getZuoraAccounts(String zuoraAccountId, Decimal wrikeAccountId, String notInStatus) {
        final String zoql = StringUtils.format(
                        'SELECT Id, Name, AccountNumber, Status, Currency FROM Account ' +
                        'WHERE Status != \'\'{0}\'\' AND Id = \'\'{1}\'\' OR AccountNumber = \'\'{2}\'\'',
                notInStatus, zuoraAccountId, wrikeAccountId);

        final List<ZuoraObject.ZuoraAccount> accounts =
                (List<ZuoraObject.ZuoraAccount>)zuoraApi.query(zoql, List<ZuoraObject.ZuoraAccount>.class);
        return accounts;
    }

    public String findDefaultPaymentMethodId(final String zuoraAccountId) {
        final String zoql =
                StringUtils.format('SELECT DefaultPaymentMethodId FROM Account WHERE Id =\'\'{0}\'\'', zuoraAccountId);
        final List<ZuoraObject.ZuoraAccount> accounts =
                (List<ZuoraObject.ZuoraAccount>)zuoraApi.query(zoql, List<ZuoraObject.ZuoraAccount>.class);
        return accounts.isEmpty() ? null : accounts.get(0).defaultPaymentMethodId;
    }

    public BillingInfo findCreditCardInfoByAccountId(final String zuoraAccountId) {
        final String defaultPaymentMethodId = findDefaultPaymentMethodId(zuoraAccountId);
        return findCreditCardInfoById(defaultPaymentMethodId, true);
    }

    public BillingInfo findCreditCardInfoById(final String paymentMethodId,
                                              final Boolean defaultPaymentMethod) {
        final ZuoraObject.ZuoraPaymentMethod card = findCreditCardById(paymentMethodId);
        return getCardBillingInfo(card, defaultPaymentMethod);
    }

    @TestVisible
    private ZuoraObject.ZuoraPaymentMethod findCreditCardById(final String paymentMethodId) {
        final String zoql =
                '           SELECT Id, Email, CreditCardHolderName, CreditCardMaskNumber, CreditCardExpirationMonth, CreditCardExpirationYear, ' +
                '                  CreditCardAddress1, CreditCardAddress2, CreditCardCity, CreditCardState, CreditCardCountry, CreditCardPostalCode, CreatedDate ' +
                '           FROM PaymentMethod ' +
                '           WHERE Type = \'CreditCard\' ' +
                '             AND PaymentMethodStatus = \'Active\' ' +
                '             AND Id = \'' + paymentMethodId + '\'';

        final List<ZuoraObject.ZuoraPaymentMethod> cards =
                (List<ZuoraObject.ZuoraPaymentMethod>)zuoraApi.query(zoql, List<ZuoraObject.ZuoraPaymentMethod>.class);
        return (cards != null && !cards.isEmpty()) ? cards.get(0) : null;
    }

    private BillingInfo getCardBillingInfo(final ZuoraObject.ZuoraPaymentMethod card,
                                           final Boolean defaultPaymentMethod) {
        if (card == null) {
            return null;
        }
        final BillingInfo billingInfo = new BillingInfo();
        final String cardId = card.id;
        billingInfo.id = cardId;
        billingInfo.defaultPaymentMethod = defaultPaymentMethod;
        billingInfo.email = card.email;
        final String holderName = card.creditCardHolderName;
        if (holderName != null) {
            final String[] names = holderName.split(' ', 2);
            if (names.size() > 1) {
                billingInfo.firstName = names[0];
                billingInfo.lastName = names[1];
            } else if (names.size() == 1) {
                billingInfo.firstName = names[0];
                billingInfo.lastName = '-';
            }
        }
        final String countryFullName = card.creditCardCountry;
        billingInfo.countryFullName = countryFullName;
        billingInfo.country = CountryUtil.findCountryCodeByValue(countryFullName);
        final String stateFullName = card.creditCardState;
        billingInfo.stateFullName = stateFullName;
        billingInfo.state = CountryUtil.findStateCodeByValue(stateFullName);
        billingInfo.city = card.creditCardCity;
        billingInfo.address1 = card.creditCardAddress1;
        billingInfo.address2 = card.creditCardAddress2;
        billingInfo.zip = card.creditCardPostalCode;
        billingInfo.cardNumber = card.creditCardMaskNumber;
        billingInfo.cardExpirationMonth = card.creditCardExpirationMonth;
        billingInfo.cardExpirationYear = card.creditCardExpirationYear;
        return billingInfo;
    }
}
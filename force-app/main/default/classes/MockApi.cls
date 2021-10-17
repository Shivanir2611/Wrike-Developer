@IsTest
public class MockApi {
    private static MockingProvider mockingProvider = new MockingProvider();

    public static Object mock(final Type mockedType) {
        return Test.createStub(mockedType, mockingProvider);
    }
    
    public static WithMock setup() {
        mockingProvider.setup = true;
        return mockingProvider;
    }

    public class MockingProvider implements System.StubProvider, WithMock {
        private final MockingMapper mapper = new MockingMapper();
        private Method currentMockedMethod;
        private Map<String, Object> currentMockedParameters;
        private Boolean setup = true;

        private MockingProvider() {
        }

        public WithMock mock(final Object methodCall, final Object returnedValue) {
            mock(methodCall, returnedValue, MockingStrategy.ParameterTypeMatch);
            return this;
        }

        public WithMock mockStrict(final Object methodCall, final Object returnedValue) {
            mock(methodCall, returnedValue, MockingStrategy.ParameterStrictValueMatch);
            return this;
        }

        private WithMock mock(final Object methodCall,
                              final Object returnedValue,
                              final MockingStrategy mockingStrategy) {
            if (!setup) {
                throw new MockingException('Mock method called after setup.');
            }
            if (this.currentMockedMethod != null) {
                final Type mockedType = this.currentMockedMethod.getMockedType();

                if (mockingStrategy == MockApi.MockingStrategy.ParameterTypeMatch) {
                    mapper.putParameterTypesSettings(mockedType, this.currentMockedMethod, this.currentMockedParameters,
                            returnedValue);
                } else if (mockingStrategy == MockApi.MockingStrategy.ParameterStrictValueMatch) {
                    mapper.putParameterValuesSettings(mockedType, this.currentMockedMethod,
                            this.currentMockedParameters, returnedValue);
                }
                this.currentMockedMethod = null;
            }
            return this;
        }

        public void build() {
            this.setup = false;
        }

        public Object handleMethodCall(final Object stub,
                                       final String methodName,
                                       final Type returnType,
                                       final List<Type> parameterTypes,
                                       final List<String> parameterNames,
                                       final List<Object> parameters) {
            final Type mockedType = Type.forName(String.valueOf(stub).split(':')[0].substringBefore('__sfdc'));
            ServiceLocator.setInstance(mockedType, stub);
            final Map<String, Type> parameterTypeMap = new Map<String, Type>();
            final Map<String, Object> parameterValueMap = new Map<String, Object>();
            for (Integer i = 0; i < parameterNames.size(); i++) {
                parameterTypeMap.put(parameterNames[i], parameterTypes[i]);
                parameterValueMap.put(parameterNames[i], parameters[i]);
            }
            final Method method = new Method(methodName, mockedType, returnType, parameterTypeMap);
            if (setup) {
                this.currentMockedMethod = method;
                this.currentMockedParameters = parameterValueMap;
                return null;
            }

            final MockingSettings mockingSettings =
                    mapper.findValuesSettingsByParameters(mockedType, method, parameterValueMap);
            if (mockingSettings == null) {
                mockingSettings = mapper.findTypesSettingsByParameters(mockedType, method);
            }

            if (mockingSettings != null) {
                return mockingSettings.getReturnedValue();
            }

            if (mapper.findValuesSettingsList(mockedType, method) != null) {
                throw new MockingException('Parameter mismatch for method ' + methodName);
            }
            return null;
        }
    }

    public class MockingMapper {
        private final Map<Type, Map<Method, List<MockingSettings>>> parameterValuesMockingMap = new Map<Type, Map<Method, List<MockingSettings>>>();
        private final Map<Type, Map<Method, MockingSettings>> parameterTypesMockingMap = new Map<Type, Map<Method, MockingSettings>>();

        private MockingSettings findTypesSettingsByParameters(final Type mockedType,
                                                              final Method method) {
            return parameterTypesMockingMap.containsKey(mockedType)
                   ? parameterTypesMockingMap.get(mockedType).get(method)
                   : null;
        }

        private MockingSettings findValuesSettingsByParameters(final Type mockedType,
                                                               final Method method,
                                                               final Map<String, Object> parameters) {
            final List<MockingSettings> mockingSettingsList = findValuesSettingsList(mockedType, method);
            if (mockingSettingsList != null) {
                for (MockingSettings mockingSettings : mockingSettingsList) {
                    if (mockingSettings.matchParameters(parameters)) {
                        return mockingSettings;
                    }
                }
            }
            return null;
        }

        private List<MockingSettings> findValuesSettingsList(final Type mockedType, final Method method) {
            return parameterValuesMockingMap.containsKey(mockedType)
                   ? parameterValuesMockingMap.get(mockedType).get(method)
                   : null;
        }

        private void putParameterTypesSettings(final Type mockedType,
                                               final Method method,
                                               final Map<String, Object> parameters,
                                               final Object returnedValue) {
            if (!parameterTypesMockingMap.containsKey(mockedType)) {
                parameterTypesMockingMap.put(mockedType, new Map<Method, MockingSettings>());
            }
            parameterTypesMockingMap.get(mockedType).put(method,
                    new MockingSettings(parameters, returnedValue));
        }

        private void putParameterValuesSettings(final Type mockedType,
                                                final Method method,
                                                final Map<String, Object> parameters,
                                                final Object returnedValue) {

            final MockingSettings mockingSettings = findValuesSettingsByParameters(mockedType, method, parameters);
            if (mockingSettings != null) {
                mockingSettings.returnedValue = returnedValue;
            } else {
                if (!parameterValuesMockingMap.containsKey(mockedType)) {
                    parameterValuesMockingMap.put(mockedType, new Map<Method, List<MockingSettings>>());
                }
                if (!parameterValuesMockingMap.get(mockedType).containsKey(method)) {
                    parameterValuesMockingMap.get(mockedType).put(method, new List<MockingSettings>());
                }
                parameterValuesMockingMap.get(mockedType).get(method).add(
                        new MockingSettings(parameters, returnedValue));
            }
        }
    }
    
    public interface WithMock {
        WithMock mock(Object methodCall, Object returnedValue);
        WithMock mockStrict(Object methodCall, Object returnedValue);
        void build();
    }
    
    public enum MockingStrategy { 
        ParameterTypeMatch, 
        ParameterStrictValueMatch
    }
    
    public class MockingSettings {
        private final Map<String, Object> parameters;
        private Object returnedValue;

        private MockingSettings(final Map<String, Object> parameters,
                                final Object returnedValue) {
            this.parameters = parameters;
            this.returnedValue = returnedValue;
        }

        private Map<String, Object> getParameters() {
            return this.parameters;
        }

        public Object getReturnedValue() {
            return this.returnedValue;
        }

        private Boolean matchParameters(Map<String, Object> parameters) {
            return parameters.equals(this.parameters);
        }
    }
    
    public class Method {
        private final String name;
        private final Type mockedType;
        private final Type returnType;
        private final Map<String, Type> parameterTypes;
        
        private Method(final String name, 
                       final Type mockedType, 
                       final Type returnType, 
                       final Map<String, Type> parameterTypes) {
            this.name = name;
            this.mockedType = mockedType;
            this.returnType = returnType;
            this.parameterTypes = parameterTypes;
        }
        
        public String getName() {
            return this.name;
        }
        
        public Type getMockedType() {
            return this.mockedType;
        }
        
        public Type getReturnType() {
            return this.returnType;
        }
        
        public Map<String, Type> getParameterTypes() {
            return this.parameterTypes;
        }
        
        public override Integer hashCode() {
            return name.hashCode() ^ parameterTypes.hashCode();
        }
        
        public Boolean equals(final Object other) {
            return other instanceOf Method 
                && name.equals(((Method)other).name)
                && mockedType.equals(((Method)other).mockedType)
                && parameterTypes.equals(((Method)other).parameterTypes);
        }
    }
    
    public class MockingException extends Exception {   
    }

    public static void mockZuoraRestQueryServiceDefault() {
        ZuoraObject.ZuoraSubscription testSubscription = new ZuoraObject.ZuoraSubscription();
        testSubscription.id = 'testSubscriptionId';
        testSubscription.name = 'testSubscriptionName';
        testSubscription.accountId = 'testSubscriptionAccountId';
        testSubscription.accountName = 'testSubscriptionAccountName';
        testSubscription.status = 'Active';
        testSubscription.contractEffectiveDate = DateUtils.getPacificLocalDate().addDays(3);
        testSubscription.renewalTerm = 12;
        testSubscription.termEndDate = DateUtils.getPacificLocalDate().addDays(3);
        testSubscription.subscriptionStartDate = DateUtils.getPacificLocalDate().addDays(-3);
        testSubscription.subscriptionEndDate = DateUtils.getPacificLocalDate().addDays(3);

        ZuoraObject.ZuoraSubscriptionWithRatePlans testSubscriptionWithRatePlans = new ZuoraObject.ZuoraSubscriptionWithRatePlans();
        testSubscriptionWithRatePlans.id = 'testSubscriptionId';
        testSubscriptionWithRatePlans.name = 'testSubscriptionName';
        testSubscriptionWithRatePlans.accountId = 'testSubscriptionAccountId';
        testSubscriptionWithRatePlans.accountName = 'testSubscriptionAccountName';
        testSubscriptionWithRatePlans.status = 'Active';
        testSubscriptionWithRatePlans.contractEffectiveDate = Date.today().addDays(3);
        testSubscriptionWithRatePlans.renewalTerm = 12;
        testSubscriptionWithRatePlans.termEndDate = Date.today().addDays(3);
        testSubscriptionWithRatePlans.subscriptionStartDate = Date.today().addDays(-3);
        testSubscriptionWithRatePlans.subscriptionEndDate = Date.today().addDays(3);
        testSubscriptionWithRatePlans.ratePlans = new List<ZuoraObject.ZuoraRatePlanWithCharges>();

        ZuoraObject.ZuoraAccount zAccount = TestDataFactory.createZuoraAccount('zuoraAccountId', '100');

        ZuoraObject.ZuoraSubscriptionProduct testSubscriptionProduct1 =
                TestDataFactory.createSubscriptionProduct(1, 'EnterpriseSeats', 5, 'Recurring', 'Annual', 100);
        ZuoraObject.ZuoraSubscriptionProduct testSubscriptionProduct2 =
                TestDataFactory.createSubscriptionProduct(2, 'ProofingAddon', 5, 'Recurring', 'Annual', 100);

        ZuoraRestQueryService zuoraRestQuerySrv = zuoraRestQueryService();
        MockApi.setup()
                .mock(zuoraRestQuerySrv.findSubscriptionsByZuoraAccountId(''),
                new List<ZuoraObject.ZuoraSubscription>{testSubscription})
                .mock(zuoraRestQuerySrv.findAllSubscriptionsByZuoraAccountId(''),
                new List<ZuoraObject.ZuoraSubscriptionWithRatePlans>{testSubscriptionWithRatePlans})
                .mock(zuoraRestQuerySrv.getZuoraAccounts('', 0, ''),
                new List<ZuoraObject.ZuoraAccount>{zAccount})
                .mock(zuoraRestQuerySrv.listSubscriptionProducts(''),
                new List<ZuoraObject.ZuoraSubscriptionProduct>{testSubscriptionProduct1, testSubscriptionProduct2})
                .mock(zuoraRestQuerySrv.findZuoraAccountByWrikeAccountId(0),
                TestDataFactory.createZuoraAccount('zuoraAccountId', '100'))
                .mock(zuoraRestQuerySrv.findCreditCardInfoByAccountId(''), new BillingInfo())
                .mock(zuoraRestQuerySrv.findCreditCardInfoById('', false), new BillingInfo())
                .build();
    }

    public static void mockQuoteValidatorCreation() {
        final QuoteValidatorService quoteValidatorSrvMock =
                (QuoteValidatorService)MockApi.mock(QuoteValidatorService.class);
        final WrikeQuote wQuote = new WrikeQuote();
        MockApi.setup()
                .mock(quoteValidatorSrvMock.createValidator(wQuote), new QuoteValidatorImpl(wQuote))
                .build();
    }

    public static void mockProductServiceDefault() {
        MockApi.setup()
                .mock(productService().findProductById(null), new WrikeProduct())
                .mock(productService().getExistingProductMap(), new Map<String, Product2>())
                .mock(productService().getExistingImplementationProductMap(), new Map<String, Map<String, Product2>>())
                .mock(productService().getProductRequiredDeployments(null, null), new List<WrikeProduct>())
                .build();
    }

    public static ZuoraRestQueryService zuoraRestQueryService() {
        return (ZuoraRestQueryService)MockApi.mock(ZuoraRestQueryService.class);
    }

    public static ZuoraProductCatalogService zuoraProductCatalogService() {
        return (ZuoraProductCatalogService)MockApi.mock(ZuoraProductCatalogService.class);
    }

    public static ProductService productService() {
        return (ProductService)MockApi.mock(ProductService.class);
    }
}
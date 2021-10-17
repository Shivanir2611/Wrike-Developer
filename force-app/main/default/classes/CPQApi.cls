public class CPQApi {

    public static CPQApi getInstance() {
        return (CPQApi)ServiceLocator.getInstance(CPQApi.class);
    }

    private static final Map<String, String> productTypeCodeMap = new Map<String, String> {
            'AdditionalIntegrateTasks1k' => 'r-othr-xtr-IntegrateEnhanced',
            'AdditionalVideoTranscoding100GB' => 'r-othr-xtr-VidUpload',
            'AnalyzeAddon' => 'r-lic-adn-Analyze',
            'BusinessSeats' => 'r-lic-base-Biz',
            'BizCreative' => 'r-lic-base-LegBaseWFM',
            'BusinessPlus2021Seats' => 'r-lic-base-BizPlus',
            'CollaboratorSeats' => 'r-othr-xtr-AddCollab',
            'DamAddon' => 'r-lic-adn-Publish',
            'EntCreative' => 'r-lic-base-LegBaseWFME',
            'EnterpriseSeats' => 'r-lic-base-Ent',
            'EnterpriseAdvanced2021Seats' => 'r-lic-base-EntPinnacle',
            'EnterpriseStandard2021Seats' => 'r-lic-base-EntStandard',
            'IntegrateAddon' => 'r-lic-adn-Integrate',
            'Premium2016Seats' => 'r-lic-base-Pro',
            'PremiumSeats' => 'r-lic-base-LegBasePro',
            'PremiumSupport' => 'r-othr-sprt-PremSupport',
            'ProjectSyncsAddon' => 'r-lic-adn-ProjSync',
            'ProofingAddon' => 'r-lic-adn-Proof',
            'ResourceAddon' => 'r-lic-adn-Resource',
            'SLA' => 'r-othr-xtr-LegUptime',
            'StorageTB' => 'r-othr-xtr-Storage',
            'Storage500GB' => 'r-othr-xtr-Storage500',
            'WrikeForMarketersPackage' => 'r-lic-pckg-WFM',
            'WrikeForProfessionalServicesPackage' => 'r-lic-pckg-WFPS',
            'WrikeLockAddon' => 'r-lic-adn-Lock',
            'WrikePerformancePackage' => 'r-lic-pckg-Performance'
    };

    public Map<Id, ProductModel> queryProductsMap(final Set<String> serviceTypes,
                                                  final String currencyCode) {
        final List<PricebookEntry> priceBookEntries = [
                SELECT Pricebook2Id, Product2.Id, Product2.ZuoraServiceType__c
                FROM PricebookEntry
                WHERE Pricebook2.Name = :CPQSettings__c.getOrgDefaults().PriceBookName__c
                  AND Product2.ProductCode IN :productTypeCodeMap.values()
                  AND CurrencyIsoCode = :currencyCode
                  AND Product2.ZuoraServiceType__c != null
        ];
        final Map<Id, ProductModel> productMap = new Map<Id, ProductModel>();
        for(PricebookEntry entry : priceBookEntries) {
            final Product2 product = entry.Product2;
            if(serviceTypes.contains(product.ZuoraServiceType__c)) {
                final String productJSON = SBQQ.ServiceRouter.load(
                        'SBQQ.ProductAPI.ProductLoader',
                        product.Id,
                        JSON.serialize(new Map<String, String> {
                            'pricebookId' => entry.Pricebook2Id,
                            'currencyCode' => currencyCode
                        })
                );
                if(String.isNotBlank(productJSON)) {
                    final ProductModel productModel = (ProductModel) JSON.deserialize(productJSON, ProductModel.class);
                    if(productModel != null && productModel.record != null) {
                        productModel.record.ZuoraServiceType__c = product.ZuoraServiceType__c;
                        productMap.put(product.Id, productModel);
                    }
                }
            }
        }
        return productMap;
    }

    public QuoteModel readQuote(final Id quoteId) {
        final String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    public QuoteModel save(final QuoteModel quote) {
        String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    public QuoteModel calculate(final QuoteModel quote) {
        String quoteJSON = SBQQ.ServiceRouter.load(
                'SBQQ.QuoteAPI.QuoteCalculator',
                null,
                JSON.serialize(new Map<String, Object> { 'quote' => quote }));
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    public QuoteModel addProducts(QuoteModel quote, List<ProductModel> products, Integer groupKey) {
        final String quoteJSON = SBQQ.ServiceRouter.load(
                'SBQQ.QuoteAPI.QuoteProductAdder',
                null,
                JSON.serialize(new AddProductContext(quote, products, groupKey))
        );
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    public class QuoteLineGroupModel {
        public SBQQ__QuoteLineGroup__c record;
        public Decimal netNonSegmentTotal;
        public Integer key;
    }

    public class QuoteLineModel {
        public SBQQ__QuoteLine__c record;
        public Boolean amountDiscountProrated;
        public Integer parentGroupKey;
        public Integer parentItemKey;
        public Integer key;
        public Boolean upliftable;
        public String configurationType;
        public String configurationEvent;
        public Boolean reconfigurationDisabled;
        public Boolean descriptionLocked;
        public Boolean productQuantityEditable;
        public Decimal productQuantityScale;
        public String dimensionType;
        public Boolean productHasDimensions;
        public Decimal targetCustomerAmount;
        public Decimal targetCustomerTotal;
    }

    public class QuoteModel {
        public SBQQ__Quote__c record {get; set;}
        public List<QuoteLineModel> lineItems {get; set;}
        public List<QuoteLineGroupModel> lineItemGroups {get; set;}
        public Integer nextKey;
        public Boolean applyAdditionalDiscountLast;
        public Boolean applyPartnerDiscountFirst;
        public Boolean channelDiscountsOffList;
        public Decimal customerTotal;
        public Decimal netTotal;
        public Decimal netNonSegmentTotal;
    }

    public class ProductModel {
        public Product2 record;
        public Id upgradedAssetId;
        public String currencySymbol;
        public String currencyCode;
        public List<String> featureCategories;
        public List<OptionModel> options;
        public List<FeatureModel> features;
        public ConfigurationModel configuration;
        public List<ConfigAttributeModel> configurationAttributes;
        public List<ConfigAttributeModel> inheritedConfigurationAttributes;
        public List<ConstraintModel> constraints;
    }

    public class OptionModel {
        public SBQQ__ProductOption__c record;
        public Map<String,String> externalConfigurationData;
        public Boolean configurable;
        public Boolean configurationRequired;
        public Boolean quantityEditable;
        public Boolean priceEditable;
        public Decimal productQuantityScale;
        public Boolean priorOptionExists;
        public Set<Id> dependentIds;
        public Map<String,Set<Id>> controllingGroups;
        public Map<String,Set<Id>> exclusionGroups;
        public String reconfigureDimensionWarning;
        public Boolean hasDimension;
        public Boolean isUpgrade;
        public String dynamicOptionKey;
    }

    public class FeatureModel {
        public SBQQ__ProductFeature__c record;
        public String instructionsText;
        public Boolean containsUpgrades;
    }

    public class ConstraintModel {
        public SBQQ__OptionConstraint__c record;
        public Boolean priorOptionExists;
    }

    public class ConfigurationModel {
        public Id configuredProductId;
        public Id optionId;
        public SBQQ__ProductOption__c optionData;
        public SBQQ__ProductOption__c configurationData;
        public SBQQ__ProductOption__c inheritedConfigurationData;
        public ConfigurationModel[] optionConfigurations;
        public Boolean configured;
        public Boolean changedByProductActions;
        public Boolean isDynamicOption;
        public Boolean isUpgrade;
        public Set<Id> disabledOptionIds;
        public Set<Id> hiddenOptionIds;
        public Decimal listPrice;
        public Boolean priceEditable;
        public List<String> validationMessages;
        public String dynamicOptionKey;
    }

    public class ConfigAttributeModel {
        public String name;
        public String targetFieldName;
        public Decimal displayOrder;
        public String colmnOrder;
        public Boolean required;
        public Id featureId;
        public String position;
        public Boolean appliedImmediately;
        public Boolean applyToProductOptions;
        public Boolean autoSelect;
        public List<String> shownValues;
        public List<String> hiddenValues;
        public Boolean hidden;
        public String noSuchFieldName;
    }

    public class AddProductContext {
        public QuoteModel quote;
        public List<ProductModel> products;
        public Integer groupKey;
        public final Boolean ignoreCalculate = true;

        public AddProductContext(final QuoteModel quote,
                                 final List<ProductModel> products,
                                 final Integer groupKey) {
            this.quote = quote;
            this.products = products;
            this.groupKey = groupKey;
        }
    }
}
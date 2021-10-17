public class DeploymentService {

    public static DeploymentService getInstance() {
        return (DeploymentService)ServiceLocator.getInstance(DeploymentService.class);
    }

    private CPQProductService productSrv = CPQProductService.getInstance();

    public List<Deployment__c> createDeployments(final List<Id> closedWonOpportunityIds) {
        final Map<Id, List<OpportunityLineItem>> opportunityLineItemMap = getOpportunityLineItemMap(closedWonOpportunityIds);
        final List<Deployment__c> deployments = new List<Deployment__c>();

        for (Id opportunityId : opportunityLineItemMap.keySet()) {
            final List<OpportunityLineItem> items = opportunityLineItemMap.get(opportunityId);

            OpportunityLineItem baseStandardDeployment = null;
            final List<OpportunityLineItem> addonStandardDeployments = new List<OpportunityLineItem>();
            final List<OpportunityLineItem> addonIntegrateDeployments = new List<OpportunityLineItem>();
            Decimal maxStandardDeliveryDays = 0;
            Decimal maxIntegrateDeliveryDays = 0;
            Decimal exhibitBNewSKUDeliveryDays = 0;

            final Set<String> legacyProductOptionCodes =
                    productSrv.getProductOptionCodesByPackageProductCode(CPQProductService.ProfessionalServicesPackageLegacy);
            final Set<String> productOptionCodes =
                    productSrv.getProductOptionCodesByPackageProductCode(CPQProductService.ProfessionalServicesPackage);

            for (OpportunityLineItem item : items) {
                if (isStandardDeployment(item)) {
                    baseStandardDeployment = item;
                } else if (isStandardAddonDeployment(item)) {
                    addonStandardDeployments.add(item);
                } else if (isIntegrateAddonDeployment(item)) {
                    addonIntegrateDeployments.add(item);
                }
                if (isStandard(item) && item.Product2.Delivery_Timeframe__c > maxStandardDeliveryDays) {
                    maxStandardDeliveryDays = item.Product2.Delivery_Timeframe__c;
                } else if (isIntegrate(item) && item.Product2.Delivery_Timeframe__c > maxIntegrateDeliveryDays) {
                    maxIntegrateDeliveryDays = item.Product2.Delivery_Timeframe__c;
                }
                if (isPinnacle(item)) {
                    deployments.addAll(createPinnacleDeployments(item));
                }
                if (item.Product2.DeploymentExhibit__c == 'B'
                        && !legacyProductOptionCodes.contains(item.ProductCode)
                        && productOptionCodes.contains(item.ProductCode)
                        && !productSrv.isJumpstart(item.ProductCode)) {
                    exhibitBNewSKUDeliveryDays = item.Product2.Delivery_Timeframe__c;
                }
            }

            for (OpportunityLineItem item : items) {
                if (isDeployment(item)
                        && !isSelfStart(item)
                        && !isStandardAddonDeployment(item)
                        && !isStandardDeployment(item)
                        && !isIntegrateAddonDeployment(item)
                        && !isPinnacle(item)) {
                    deployments.add(createDeployment(
                            item,
                            new List<OpportunityLineItem>(),
                            exhibitBNewSKUDeliveryDays,
                            maxIntegrateDeliveryDays
                    ));
                }
            }
            if (baseStandardDeployment != null || !addonStandardDeployments.isEmpty()) {
                deployments.add(createDeployment(
                        baseStandardDeployment,
                        addonStandardDeployments,
                        exhibitBNewSKUDeliveryDays,
                        maxStandardDeliveryDays
                ));
            }
            if (!addonIntegrateDeployments.isEmpty()) {
                deployments.add(createDeployment(
                        null,
                        addonIntegrateDeployments,
                        exhibitBNewSKUDeliveryDays,
                        maxIntegrateDeliveryDays
                ));
            }
        }
        return deployments;
    }

    private Integer getDeliveryDays(final OpportunityLineItem item,
                                    final Decimal exhibitBNewSKUDeliveryDays,
                                    final Decimal maxAggregatedDeliveryDays) {
        final Decimal deliveryDays = item.Product2.Delivery_Timeframe__c;
        if (exhibitBNewSKUDeliveryDays != 0) {
            if (item.Product2.DeliveryTimeframeType__c == 'Exhibit B') {
                return exhibitBNewSKUDeliveryDays.intValue();
            }
            if (item.Product2.DeliveryTimeframeType__c == 'Add-on extended' && deliveryDays != null) {
                return deliveryDays.intValue() + 40;
            }
        }
        if (isStandard(item) || isIntegrate(item)) {
            return maxAggregatedDeliveryDays.intValue();
        }
        if (deliveryDays != null) {
            return deliveryDays.intValue();
        }
        return null;
    }

    private Decimal getCurrencyMultiplier(final String currencyIsoCode) {
        if ('EUR'.equalsIgnoreCase(currencyIsoCode)) {
            return 0.9;
        }
        if ('JPY'.equalsIgnoreCase(currencyIsoCode)) {
            return 110;
        }
        return 1;
    }

    private List<Deployment__c> createPinnacleDeployments(final OpportunityLineItem item) {
        final List<Deployment__c> deployments = new List<Deployment__c>();
        final Date deploymentStartDate = item.Opportunity.Deployment_Start_Date__c != null
                                         ? item.Opportunity.Deployment_Start_Date__c
                                         : DateUtils.getPacificLocalDate();
        final Decimal currencyMultiplier = getCurrencyMultiplier(item.Opportunity.CurrencyIsoCode);
        final Decimal analyzeBasePrice = Settings__c.getOrgDefaults().AnalyzeBasePrice__c * currencyMultiplier;
        final Decimal masterySilverPrice = Settings__c.getOrgDefaults().ReportsMasterySilverPrice__c * currencyMultiplier;
        final Decimal analyzeBaseBudgetedHours = Settings__c.getOrgDefaults().AnalyzeBaseBudgetedHours__c;
        final Decimal mainDeploymentListPrice = item.ListPrice - analyzeBasePrice - masterySilverPrice;
        deployments.add(new Deployment__c(
                Name = getConsultingServicesDeploymentName(
                        item.Opportunity.Account.Name,
                        item.Product2.Deployment_Package2__c,
                        item.Product2.Deployment_Method__c,
                        deploymentStartDate
                ),
                Account__c = item.Opportunity.Account.Id,
                Opportunity__c = item.Opportunity.Id,
                Deployment_Type2__c = item.PG3__c,
                Deployment_Package2__c = item.Product2.Deployment_Package2__c,
                Deployment_Method__c = item.Product2.Deployment_Method__c,
                DeploymentEffectivePrice2__c = item.UnitPrice / item.ListPrice * mainDeploymentListPrice,
                DeploymentListPrice2__c = mainDeploymentListPrice,
                Budgeted_Hours__c = item.Product2.Budgeted_Hours__c - analyzeBaseBudgetedHours,
                Start_Date__c = deploymentStartDate,
                Original_Delivery_Deadline__c = deploymentStartDate.addDays(item.Product2.Delivery_Timeframe__c.intValue())
        ));
        deployments.add(new Deployment__c(
                Name = getConsultingServicesDeploymentName(
                        item.Opportunity.Account.Name,
                        'Pinnacle - Analyze Standard',
                        item.Product2.Deployment_Method__c,
                        deploymentStartDate
                ),
                Account__c = item.Opportunity.Account.Id,
                Opportunity__c = item.Opportunity.Id,
                Deployment_Type2__c = 'SA Services',
                Deployment_Package2__c = 'Pinnacle - Analyze Standard',
                Deployment_Method__c = item.Product2.Deployment_Method__c,
                DeploymentEffectivePrice2__c = item.UnitPrice / item.ListPrice * analyzeBasePrice,
                DeploymentListPrice2__c = analyzeBasePrice,
                Budgeted_Hours__c = analyzeBaseBudgetedHours,
                Start_Date__c = deploymentStartDate,
                Original_Delivery_Deadline__c = deploymentStartDate.addDays(item.Product2.Delivery_Timeframe__c.intValue())
        ));
        return deployments;
    }

    private Deployment__c createDeployment(final OpportunityLineItem baseDeployment,
                                           final List<OpportunityLineItem> addonDeployments,
                                           final Decimal exhibitBNewSKUDeliveryDays,
                                           final Decimal maxAggregatedDeliveryDays) {
        final OpportunityLineItem baseOrFirstDeployment;
        if (baseDeployment == null) {
            baseOrFirstDeployment = addonDeployments.get(0);
            addonDeployments.remove(0);
        } else {
            baseOrFirstDeployment = baseDeployment;
        }

        final String deploymentType = baseOrFirstDeployment.PG2__c == 'Deployment' ? baseOrFirstDeployment.PG3__c : 'Add On';
        final String deploymentPackage = baseOrFirstDeployment.PG2__c == 'Deployment' ? baseOrFirstDeployment.Product2.Deployment_Package2__c : 'Add On';
        final String deploymentMethod = baseOrFirstDeployment.PG2__c == 'Deployment' ? baseOrFirstDeployment.Product2.Deployment_Method__c : 'Remote';
        final Date deploymentStartDate = baseOrFirstDeployment.Opportunity.Deployment_Start_Date__c != null
                                         ? baseOrFirstDeployment.Opportunity.Deployment_Start_Date__c
                                         : DateUtils.getPacificLocalDate();
        final Decimal discount = baseOrFirstDeployment.UnitPrice / baseOrFirstDeployment.ListPrice;
        final Deployment__c deployment = new Deployment__c(
                Name = isConsultingServices(baseOrFirstDeployment)
                       ? getConsultingServicesDeploymentName(baseOrFirstDeployment.Opportunity.Account.Name, deploymentPackage, deploymentMethod, deploymentStartDate)
                       : getDeploymentName(baseOrFirstDeployment.Opportunity.Account.Name, deploymentType, deploymentPackage, deploymentMethod, deploymentStartDate),
                Account__c = baseOrFirstDeployment.Opportunity.Account.Id,
                Opportunity__c = baseOrFirstDeployment.Opportunity.Id,
                Deployment_Type2__c = deploymentType,
                Deployment_Package2__c = deploymentPackage,
                Deployment_Method__c = deploymentMethod,
                DeploymentEffectivePrice2__c = baseOrFirstDeployment.UnitPrice -
                        getCustomEducationEffectivePriceUSD(baseOrFirstDeployment.ProductCode)
                        * discount
                        * getCurrencyMultiplier(baseOrFirstDeployment.Opportunity.CurrencyIsoCode),
                DeploymentListPrice2__c = baseOrFirstDeployment.ListPrice,
                Budgeted_Hours__c = baseOrFirstDeployment.Product2.Budgeted_Hours__c,
                Start_Date__c = deploymentStartDate,
                Original_Delivery_Deadline__c = deploymentStartDate.addDays(getDeliveryDays(
                        baseOrFirstDeployment,
                        exhibitBNewSKUDeliveryDays,
                        maxAggregatedDeliveryDays
                ))
        );

        final List<String> addonNames = new List<String>();
        if (baseOrFirstDeployment.PG2__c == 'Add On') {
            addonNames.add(baseOrFirstDeployment.Product2.ZuoraRatePlanName__c != null
                           ? baseOrFirstDeployment.Product2.ZuoraRatePlanName__c
                           : baseOrFirstDeployment.Product2.Name);
        }

        for (OpportunityLineItem item : addonDeployments) {
            deployment.DeploymentEffectivePrice2__c += item.UnitPrice;
            deployment.DeploymentListPrice2__c += item.ListPrice;
            deployment.Budgeted_Hours__c += item.Product2.Budgeted_Hours__c;
            addonNames.add(item.Product2.ZuoraRatePlanName__c != null
                           ? item.Product2.ZuoraRatePlanName__c
                           : item.Product2.Name);
        }
        if (!addonNames.isEmpty()) {
            deployment.AddOns__c = String.join(addonNames, ', ');
        }
        return deployment;
    }

    private Decimal getCustomEducationEffectivePriceUSD(final String productCode) {
        if (productSrv.isBusinessA(productCode) || productSrv.isBusinessB(productCode)) {
            return Settings__c.getOrgDefaults().QuickStartPrice__c;
        }
        if (productSrv.isWrikeAnalyzeStandard(productCode)) {
            return Settings__c.getOrgDefaults().ReportsMasterySilverPrice__c;
        }
        if (productSrv.isPinnacleACore(productCode) || productSrv.isPinnacleBCore(productCode)) {
            return 25;
        }
        return 0;
    }

    private String getDeploymentName(final String accountName,
                                     final String deploymentType,
                                     final String deploymentPackage,
                                     final String deploymentMethod,
                                     final Date startDate) {
        final String formattedStartDate = DateUtils.format(startDate, 'yyyyMMdd');
        final String deploymentInfo = ' ' + deploymentType + ' ' + deploymentPackage + ' ' + deploymentMethod + ' ' + formattedStartDate;
        return accountName.abbreviate(80 - deploymentInfo.length()) + deploymentInfo;
    }

    private String getConsultingServicesDeploymentName(final String accountName,
                                                       final String deploymentPackage,
                                                       final String deploymentMethod,
                                                       final Date startDate) {
        final String formattedStartDate = DateUtils.format(startDate, 'yyyyMMdd');
        final String deploymentInfo = ' - ' + deploymentPackage + ' - ' + deploymentMethod + ' - ' + formattedStartDate;
        return accountName.abbreviate(80 - deploymentInfo.length()) + deploymentInfo;
    }

    private Boolean isDeployment(final OpportunityLineItem item) {
        return item.PG1__c == 'Services'
                && (item.PG2__c == 'Add On'
                        && (item.PG3__c == 'Standard' || item.PG3__c == 'Analyze')
                        || item.PG2__c == 'Deployment'
                                && (item.PG3__c == 'Standard'
                                        || item.PG3__c == 'Integrate'
                                        || item.PG3__c == 'Custom'
                                        || item.PG3__c == 'E-Learning'
                                        || item.PG3__c == 'Consulting Services'));
    }

    private Boolean isConsultingServices(final OpportunityLineItem item) {
        return item.PG1__c == 'Services' && item.PG2__c == 'Deployment' && item.PG3__c == 'Consulting Services';
    }

    private Boolean isStandardAddonDeployment(final OpportunityLineItem item) {
        return item.PG1__c == 'Services' && item.PG2__c == 'Add On' && item.PG3__c == 'Standard';
    }

    private Boolean isStandardDeployment(final OpportunityLineItem item) {
        return item.PG1__c == 'Services' && item.PG2__c == 'Deployment' && item.PG3__c == 'Standard';
    }

    private Boolean isIntegrateAddonDeployment(final OpportunityLineItem item) {
        return item.PG1__c == 'Services' && item.PG2__c == 'Add On' && item.PG3__c == 'Integrate';
    }

    private Boolean isStandard(final OpportunityLineItem item) {
        return item.PG1__c == 'Services' && (item.PG2__c == 'Add On' || item.PG2__c == 'Deployment') && item.PG3__c == 'Standard';
    }

    private Boolean isIntegrate(final OpportunityLineItem item) {
        return item.PG1__c == 'Services' && (item.PG2__c == 'Add On' || item.PG2__c == 'Deployment') && item.PG3__c == 'Integrate';
    }

    private Boolean isSelfStart(final OpportunityLineItem item) {
        return item.Product2.ZuoraProductName__c != null
               ? item.Product2.ZuoraProductName__c == 'Self Start'
               : item.Product2.Name == 'Self Start';
    }

    private Boolean isPinnacle(final OpportunityLineItem item) {
        return item.Product2.Name.contains('Pinnacle') && !item.Product2.Name.contains('Core');
    }

    private Map<Id, List<OpportunityLineItem>> getOpportunityLineItemMap(final List<Id> closedWonOpportunityIds) {
        final List<OpportunityLineItem> opportunityLineItems = [
                SELECT Id, Product2.Id, Product2.ZuoraServiceType__c, Product2.Name, Product2.Deployment_Method__c,
                       Product2.Deployment_Package2__c, Product2.Budgeted_Hours__c, Product2.Delivery_Timeframe__c,
                       Product2.ZuoraProductName__c, Product2.ZuoraRatePlanName__c, Product2.PG1__c, Product2.PG2__c,
                       Product2.PG3__c, Product2.ProductCode, Opportunity.Id, Opportunity.Name, Opportunity.AccountId,
                       Opportunity.Account.Name, Opportunity.CurrencyIsoCode, UnitPrice, ListPrice, PG1__c, PG2__c,
                       PG3__c, Opportunity.Deployment_Start_Date__c, ProductCode, Product2.DeploymentExhibit__c,
                       Product2.DeliveryTimeframeType__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :closedWonOpportunityIds
                AND Product2.ZuoraServiceType__c = 'Implementation'
        ];

        final Map<Id, List<OpportunityLineItem>> opportunityLineItemMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem opportunityItem : opportunityLineItems) {
            final Id opportunityId = opportunityItem.OpportunityId;
            if (!opportunityLineItemMap.containsKey(opportunityId)) {
                opportunityLineItemMap.put(opportunityId, new List<OpportunityLineItem>());
            }
            opportunityLineItemMap.get(opportunityId).add(opportunityItem);
        }
        return opportunityLineItemMap;
    }
}
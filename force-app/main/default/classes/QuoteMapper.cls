public class QuoteMapper {

    private static final Logger log = Logger.create(QuoteMapper.class);
    private static final ZuoraProductService zuoraSrv = ZuoraProductService.getInstance();
    private static final QuoteDateService amendmentQuoteDateSrv = AmendmentQuoteDateService.getInstance();

    public static WrikeQuoteProduct mapToWikeProduct(ZuoraObject.ZuoraSubscriptionProduct subscriptionProduct, Integer term) {
        WrikeQuoteProduct wrikeQuoteProduct = new WrikeQuoteProduct();
        wrikeQuoteProduct.zuoraProductId = subscriptionProduct.id;
        wrikeQuoteProduct.name = subscriptionProduct.name;
        wrikeQuoteProduct.serviceType = subscriptionProduct.serviceType;
        wrikeQuoteProduct.description = subscriptionProduct.description;
        wrikeQuoteProduct.quantity = Integer.valueOf(subscriptionProduct.quantity);
        wrikeQuoteProduct.zuoraProductRatePlanId = subscriptionProduct.productRatePlanId;
        wrikeQuoteProduct.zuoraProductRatePlanChargeId = subscriptionProduct.productRatePlanChargeId;
        wrikeQuoteProduct.zuoraProductRatePlanChargeName = subscriptionProduct.ratePlanChargeName;
        wrikeQuoteProduct.zuoraRatePlanId = subscriptionProduct.ratePlanId;
        wrikeQuoteProduct.zuoraRatePlanChargeId = subscriptionProduct.ratePlanChargeId;
        wrikeQuoteProduct.chargeType = subscriptionProduct.chargeType;
        wrikeQuoteProduct.chargeModel = subscriptionProduct.chargeModel;
        wrikeQuoteProduct.chargeNumber = subscriptionProduct.chargeNumber;
        wrikeQuoteProduct.mrr = subscriptionProduct.mrr;
        wrikeQuoteProduct.term = term;
        wrikeQuoteProduct.billingPeriodName = subscriptionProduct.billingPeriod;
        wrikeQuoteProduct.effectivePrice = subscriptionProduct.price;
        if(zuoraSrv.isSeat(subscriptionProduct.serviceType) && subscriptionProduct.quantity > 0) {
            wrikeQuoteProduct.effectivePricePerUserPerMonth =
                    (subscriptionProduct.price/subscriptionProduct.quantity/wrikeQuoteProduct.getBillingPeriodInMonth())
                    .setScale(2, RoundingMode.HALF_UP);
        }
        wrikeQuoteProduct.originalSubscriptionProduct = subscriptionProduct;
        return wrikeQuoteProduct;
    }

    public static WrikeQuote mapToWrikeQuote(ZuoraObject.ZuoraSubscription subscription,
                                             List<ZuoraObject.ZuoraSubscriptionProduct> subscriptionProducts) {
        WrikeQuote wQuote = new WrikeQuote();
        wQuote.zuoraSubscriptionId = subscription.id;
        wQuote.zuoraSubscriptionName = subscription.name;
        wQuote.zuoraAccountId = subscription.accountId;
        wQuote.zuoraAccountName = subscription.accountName;
        wQuote.currentTerm = subscription.currentTerm;
        wQuote.renewalTerm = subscription.renewalTerm;
        wQuote.subscriptionStartDate = subscription.subscriptionStartDate;
        wQuote.subscriptionEndDate = subscription.subscriptionEndDate;
        wQuote.effectiveDate = amendmentQuoteDateSrv.getEffectiveDate(wQuote);
        wQuote.validUntil = amendmentQuoteDateSrv.getValidUntil(wQuote);
        wQuote.invoiceDate = wQuote.effectiveDate;

        String billingPeriod = '';
        for (ZuoraObject.ZuoraSubscriptionProduct subscriptionProduct : subscriptionProducts) {
            wQuote.addItem(WrikeQuoteItem.State.EXISTING, mapToWikeProduct(subscriptionProduct, subscription.currentTerm));
            if (!zuoraSrv.isSeat(subscriptionProduct.serviceType)) {
                continue;
            }

            if (String.isBlank(billingPeriod)) {
                billingPeriod = subscriptionProduct.billingPeriod;
            }
            if (billingPeriod != subscriptionProduct.billingPeriod) {
                throw new LogicException('There are products with different billing period in the subscription.');
            }
        }
        return wQuote;
    }

    public static WrikeQuoteProduct mapToWrikeProduct(Quote_Product__c quoteProduct) {
        WrikeQuoteProduct wrikeQuoteProduct = new WrikeQuoteProduct();
        wrikeQuoteProduct.id = quoteProduct.Id;
        wrikeQuoteProduct.name = quoteProduct.Name;
        wrikeQuoteProduct.description = quoteProduct.Description__c;
        wrikeQuoteProduct.quantity = Integer.valueOf(quoteProduct.Quantity__c);
        wrikeQuoteProduct.term = Integer.valueOf(quoteProduct.Term__c);
        wrikeQuoteProduct.chargeType = quoteProduct.ChargeType__c;
        wrikeQuoteProduct.chargeModel = quoteProduct.ChargeModel__c;
        wrikeQuoteProduct.chargeNumber = quoteProduct.ChargeNumber__c;
        wrikeQuoteProduct.serviceType = quoteProduct.ServiceType__c;
        wrikeQuoteProduct.effectivePrice = quoteProduct.Price__c;
        wrikeQuoteProduct.effectivePricePerUserPerMonth = quoteProduct.PricePerUserPerMonth__c;
        wrikeQuoteProduct.discount = quoteProduct.Discount__c;
        wrikeQuoteProduct.discountReason = quoteProduct.DiscountReason__c;
        wrikeQuoteProduct.zuoraProductId = quoteProduct.ZuoraProductId__c;
        wrikeQuoteProduct.zuoraProductRatePlanId = quoteProduct.ZuoraProductRatePlanId__c;
        wrikeQuoteProduct.zuoraProductRatePlanChargeId = quoteProduct.ZuoraProductRatePlanChargeId__c;
        wrikeQuoteProduct.zuoraProductRatePlanChargeName = quoteProduct.ZuoraProductRatePlanChargeName__c;
        wrikeQuoteProduct.zuoraRatePlanId = quoteProduct.ZuoraRatePlanId__c;
        wrikeQuoteProduct.zuoraRatePlanChargeId = quoteProduct.ZuoraRatePlanChargeId__c;
        wrikeQuoteProduct.mrr = quoteProduct.MRR__c;
        wrikeQuoteProduct.billingPeriodName = quoteProduct.BillingPeriodName__c;
        final Boolean listPriceIgnored = SettingsProvider.isCustomRatePlan(quoteProduct.ZuoraProductRatePlanChargeName__c);
        wrikeQuoteProduct.billingIntervalListPrice = listPriceIgnored ? 0 : quoteProduct.BillingIntervalListPrice__c;
        wrikeQuoteProduct.priceFormat = quoteProduct.PriceFormat__c;
        wrikeQuoteProduct.product2Id = quoteProduct.Product__c;
        wrikeQuoteProduct.softBundleDiscountApplied = quoteProduct.SoftBundleDiscountApplied__c;
        return wrikeQuoteProduct;
    }

    public static WrikeQuoteItem mapToWrikeQuoteItem(Quote_Item__c quoteItem) {
        WrikeQuoteItem wQuoteItem = new WrikeQuoteItem();
        wQuoteItem.id = quoteItem.Id;
        wQuoteItem.quoteId = quoteItem.Quote__c;
        wQuoteItem.setStateAsString(quoteItem.State__c);
        wQuoteItem.productId = quoteItem.Product__c;
        wQuoteItem.uid = quoteItem.UID__c;
        wQuoteItem.parentItemUID = quoteItem.ParentItemUID__c;
        wQuoteItem.product = mapToWrikeProduct(quoteItem.Product__r);
        return wQuoteItem;
    }

    public static List<WrikeQuoteItem> mapToWrikeQuoteItem(List<Quote_Item__c> quoteItems) {
        List<WrikeQuoteItem> wQuoteItems = new List<WrikeQuoteItem>();
        for (Quote_Item__c quoteItem : quoteItems) {
            wQuoteItems.add(mapToWrikeQuoteItem(quoteItem));
        }
        return wQuoteItems;
    }

    public static WrikeQuote mapToWrikeQuoteWithLineItems(Quote__c quote) {
        WrikeQuote wQuote = new WrikeQuote();
        wQuote.id = quote.Id;
        wQuote.name = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Name);
        wQuote.primary = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.Primary__c);
        wQuote.createdDate = (DateTime)SobjectUtils.getValueIfExist(quote, Quote__c.CreatedDate);
        wQuote.effectiveDate = (Date)SobjectUtils.getValueIfExist(quote, Quote__c.EffectiveDate__c);
        wQuote.subscriptionStartDate = (Date)SobjectUtils.getValueIfExist(quote, Quote__c.SubscriptionStartDate__c);
        wQuote.subscriptionEndDate = (Date)SobjectUtils.getValueIfExist(quote, Quote__c.SubscriptionEndDate__c);
        wQuote.validUntil = (Date)SobjectUtils.getValueIfExist(quote, Quote__c.ValidUntil__c);
        wQuote.opportunityId = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Opportunity__c);
        wQuote.quoteNumber = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Number__c);
        wQuote.effectiveDate = (Date)SobjectUtils.getValueIfExist(quote, Quote__c.EffectiveDate__c);
        wQuote.zuoraAccountId = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Zuora_Account_Id__c);
        wQuote.zuoraAccountName = (String)SobjectUtils.getValueIfExist(quote, Quote__c.ZuoraAccountName__c);
        wQuote.zuoraSubscriptionId = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Zuora_Subscription_Id__c);
        wQuote.zuoraSubscriptionName = (String)SobjectUtils.getValueIfExist(quote, Quote__c.ZuoraSubscriptionName__c);
        wQuote.zuoraCreditCardId = (String)SobjectUtils.getValueIfExist(quote, Quote__c.ZuoraCreditCardId__c);
        wQuote.wrikeAccountId = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.WrikeAccountId__c));
        wQuote.companyName = (String)SobjectUtils.getValueIfExist(quote, Quote__c.CompanyName__c);
        wQuote.salesName = (String)SobjectUtils.getValueIfExist(quote, Quote__c.SalesName__c);
        wQuote.salesEmail = (String)SobjectUtils.getValueIfExist(quote, Quote__c.SalesEmail__c);
        wQuote.salesPhone = (String)SobjectUtils.getValueIfExist(quote, Quote__c.SalesPhone__c);
        wQuote.creditCardLink = (String)SobjectUtils.getValueIfExist(quote, Quote__c.CreditCardLink__c);
        wQuote.attachemntId = (String)SobjectUtils.getValueIfExist(quote, Quote__c.PurchaseOrderAttachmentId__c);
        wQuote.pdfId = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Pdf_Id__c);
        wQuote.total = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.Total__c);
        wQuote.deltaMrr = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.DeltaMrr__c);
        wQuote.baseLicenseMrr = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.BaseLicenseMrr__c);
        wQuote.targetInvoiceDate = (Date)SobjectUtils.getValueIfExist(quote, Quote__c.TargetInvoiceDate__c);
        wQuote.invoiceDate = (Date)SobjectUtils.getValueIfExist(quote, Quote__c.InvoiceDate__c);
        wQuote.currentTerm = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.InitialTerm__c));
        wQuote.newTerm = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.NewTerm__c));
        wQuote.renewalTerm = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.RenewalTerm__c));
        wQuote.paymentTerm = (String)SobjectUtils.getValueIfExist(quote, Quote__c.PaymentTerm__c);
        wQuote.legalTerms = (String)SobjectUtils.getValueOrDefault(
                quote,
                Quote__c.LegalTerms__c,
                Schema.SObjectType.Quote__c.fields.LegalTerms__c.getDefaultValue());
        wQuote.legalTermsEffectiveDate = (Date)SobjectUtils.getValueIfExist(quote, Quote__c.LegalTermsEffectiveDate__c);
        wQuote.savedHashCode = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.HashCode__c));
        wQuote.approvalReason = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Reason_for_Approval_Request__c);
        wQuote.discountReason = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Reason_for_Discount__c);
        wQuote.lastEditBy = (String)SobjectUtils.getValueIfExist(quote, Quote__c.LastEditBy__c);
        wQuote.lastEditDateTime = (Datetime)SobjectUtils.getValueIfExist(quote, Quote__c.LastEditDateTime__c);
        wQuote.taxExempt = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.TaxExempt__c);
        wQuote.taxExemptCertificateId = (String)SobjectUtils.getValueIfExist(quote, Quote__c.TaxExemptCertificateId__c);
        wQuote.dataCenter = (String)SobjectUtils.getValueIfExist(quote, Quote__c.DataCenter__c);
        wQuote.originalQuoteId = (String)SobjectUtils.getValueIfExist(quote, Quote__c.OriginalQuote__c);
        wQuote.isOriginalQuoteApproved = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.IsOriginalQuoteApproved__c);

        wQuote.licenseDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.LicenseDiscount__c);
        wQuote.deploymentDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.DeploymentDiscount__c);
        wQuote.resourceManagementDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.ResourceManagementDiscount__c);
        wQuote.collaboratorBaseLicenseRate = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.CollaboratorBaseLicenseRate__c);
        wQuote.deploymentName = (String)SobjectUtils.getValueIfExist(quote, Quote__c.DeploymentName__c);
        wQuote.oldProductName = (String)SobjectUtils.getValueIfExist(quote, Quote__c.OldProductName__c);
        wQuote.newProductName = (String)SobjectUtils.getValueIfExist(quote, Quote__c.NewProductName__c);
        wQuote.billingPeriodName = (String)SobjectUtils.getValueIfExist(quote, Quote__c.BillingPeriodName__c);
        wQuote.oldQuantity = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.OldQuantity__c));
        wQuote.newQuantity = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.NewQuantity__c));
        wQuote.proofingAddonQuantity = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.AddonQuantity__c));
        wQuote.advancedFeatureAddonQuantity = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.AdvancedFeatureAddonQuantity__c));
        wQuote.oldPricePerUserPerMonth = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.OldPricePerUserPerMonth__c);
        wQuote.newPricePerUserPerMonth = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.NewPricePerUserPerMonth__c);
        wQuote.isTravelPaid = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.IsTravelPaid__c);
        wQuote.noPSIntegrate = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.NoPSIntegrate__c);
        wQuote.onetimeDiscountIncluded = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.OnetimeDiscountIncluded__c);
        wQuote.agencyReliefOfferDiscount = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.AgencyReliefOfferDiscount__c);
        wQuote.numberOfTeams = Integer.valueOf(SobjectUtils.getValueIfExist(quote, Quote__c.NumberOfTeams__c));
        wQuote.hasCustomDeployment = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.HasCustomDeployment__c);
        wQuote.additionalUsers = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.AdditionalUsers__c);
        wQuote.autoRenewalRemoval = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.AutoRenewalRemoval__c);
        wQuote.renewalPriceProtection = (String)SobjectUtils.getValueIfExist(quote, Quote__c.RenewalPriceProtection__c);
        wQuote.publicityRightsRemoval = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.PublicityRightsRemoval__c);
        wQuote.coMarketingAddition = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.CoMarketingAddition__c);
        wQuote.governingLaw = (String)SobjectUtils.getValueIfExist(quote, Quote__c.GoverningLaw__c);
        wQuote.termsDataCenter = (String)SobjectUtils.getValueIfExist(quote, Quote__c.TermsDataCenter__c);
        wQuote.wfmDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikeForMarketersDiscount__c);
        wQuote.wfpsDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikeForProfessionalServicesDiscount__c);
        wQuote.wrikePerformancePackageDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikePerformancePackageDiscount__c);
        wQuote.projectSyncsDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.ProjectSyncsDiscount__c);
        wQuote.wrikeAnalyzeDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikeAnalyzeDiscount__c);
        wQuote.wrikeIntegrateDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikeIntegrateDiscount__c);
        wQuote.wrikeIntegrateEnhancedDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikeIntegrateEnhancedDiscount__c);
        wQuote.wrikeLockDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikeLockDiscount__c);
        wQuote.wrikeProofDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikeProofDiscount__c);
        wQuote.wrikePublishDiscount = (Decimal)SobjectUtils.getValueIfExist(quote, Quote__c.WrikePublishDiscount__c);
        wQuote.premiumSupportMismatch = (Boolean)SobjectUtils.getValueIfExist(quote, Quote__c.PremiumSupportMismatch__c);

        Quote__c originalQuote = (Quote__c)SobjectUtils.getSobjectIfExist(quote, Quote__c.OriginalQuote__c);
        if (originalQuote != null) {
            wQuote.originalQuoteName = (String)SobjectUtils.getValueIfExist(originalQuote, Quote__c.Name);
        }

        Opportunity relatedOpportunity = (Opportunity)SobjectUtils.getSobjectIfExist(quote, Quote__c.Opportunity__c);
        if (relatedOpportunity != null) {
            wQuote.accountId = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.AccountId);
            wQuote.opportunityName = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Name);
            wQuote.verticalSegment = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Vertical_Segment__c);

            User opportunityOwner = (User)SobjectUtils.getSobjectIfExist(relatedOpportunity, Opportunity.OwnerId);
            if (opportunityOwner != null) {
                wQuote.ownerName = (String)SobjectUtils.getValueIfExist(opportunityOwner, User.Name);
                wQuote.ownerEmail = (String)SobjectUtils.getValueIfExist(opportunityOwner, User.Email);
                wQuote.ownerPhone = (String)SobjectUtils.getValueIfExist(opportunityOwner, User.Phone);
            }

            wQuote.opportunity = new OpportunityDto();
            wQuote.opportunity.id = (String)SobjectUtils.getValueIfExist(quote, Quote__c.Opportunity__c);
            wQuote.opportunity.name = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Name);
            wQuote.opportunity.billingCountryCode = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.BillingCountryCode__c);
            wQuote.opportunity.vat = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.VAT__c);
            wQuote.opportunity.vatValidStatus = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.VAT_Valid__c);
            wQuote.opportunity.opportunityDataId = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.OpportunityData__c);
            wQuote.opportunity.currencyCode = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.CurrencyIsoCode);
            wQuote.opportunity.billingContact = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Billing_Contact__c);
            wQuote.opportunity.competitorLostTo = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Competitor_Lost_To__c);
            wQuote.opportunity.reasonsLostTo = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Reasons_Lost__c);
            wQuote.opportunity.subReason = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Sub_Reason__c);
            wQuote.opportunity.lostReasonDetail = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Lost_Reason_Detail__c);
            wQuote.opportunity.otherCompetitorsWonLostTo = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Other_Competitors_Won_Lost_To__c);
            wQuote.opportunity.otherWonLostReasons = (String)SobjectUtils.getValueIfExist(relatedOpportunity, Opportunity.Other_Won_Lost_Reasons__c);

            RecordType opportunityRecordType = (RecordType)SobjectUtils.getSobjectIfExist(relatedOpportunity, Opportunity.RecordTypeId);
            if (opportunityRecordType != null) {
                wQuote.opportunity.recordTypeDeveloperName = (String)SobjectUtils.getValueIfExist(opportunityRecordType, RecordType.DeveloperName);
            }
        }

        Contact billingContact = (Contact)SobjectUtils.getSobjectIfExist(relatedOpportunity, Opportunity.Billing_Contact__c);
        if (billingContact != null) {
            wQuote.contact = new ContactBean();
            wQuote.contact.firstname = (String)SobjectUtils.getValueIfExist(billingContact, Contact.FirstName);
            wQuote.contact.lastname = (String)SobjectUtils.getValueIfExist(billingContact, Contact.LastName);
            wQuote.contact.email = (String)SobjectUtils.getValueIfExist(billingContact, Contact.Email);
            wQuote.contact.mailingStreet = (String)SobjectUtils.getValueIfExist(billingContact, Contact.MailingStreet);
            wQuote.contact.mailingCity = (String)SobjectUtils.getValueIfExist(billingContact, Contact.MailingCity);
            wQuote.contact.mailingState = (String)SobjectUtils.getValueIfExist(billingContact, Contact.MailingState);
            wQuote.contact.mailingStateCode = (String)SobjectUtils.getValueIfExist(billingContact, Contact.MailingStateCode);
            wQuote.contact.mailingCountryCode = (String)SobjectUtils.getValueIfExist(billingContact, Contact.MailingCountryCode);
            wQuote.contact.mailingCountry = (String)SobjectUtils.getValueIfExist(billingContact, Contact.MailingCountry);
            wQuote.contact.mailingPostalCode = (String)SobjectUtils.getValueIfExist(billingContact, Contact.MailingPostalCode);

            wQuote.contactEmail = wQuote.contact.email;
            wQuote.companyAddress = String.join(new List<String> {
                wQuote.contact.mailingStreet,
                 wQuote.contact.mailingCity,
                 wQuote.contact.mailingStateCode,
                 wQuote.contact.mailingPostalCode,
                 wQuote.contact.mailingCountryCode}, ', ');
        }

        wQuote.setAmendmentTypeAsString((String)SobjectUtils.getValueIfExist(quote, Quote__c.AmendmentType__c));
        wQuote.setQuoteTypeAsString((String)SobjectUtils.getValueIfExist(quote, Quote__c.QuoteType__c));
        wQuote.setStatusAsString((String)SobjectUtils.getValueIfExist(quote, Quote__c.Status__c));
        wQuote.setCurrency((String)SobjectUtils.getValueIfExist(quote, Quote__c.CurrencyIsoCode));
        wQuote.items = mapToWrikeQuoteItem(quote.Quote_Items__r);

        return wQuote;
    }

    public static Quote__c mapToQuote(final WrikeQuote wQuote) {
        final Quote__c newQuote = new  Quote__c();

        if(wQuote.id == null) {
            newQuote.CurrencyIsoCode = wQuote.getCurrencyCode();
        } else {
            newQuote.Id = wQuote.id;
        }
        newQuote.Name = wQuote.name;
        newQuote.AmendmentType__c = wQuote.getAmendmentTypeAsString();
        newQuote.EffectiveDate__c = wQuote.effectiveDate;
        newQuote.SubscriptionStartDate__c = wQuote.subscriptionStartDate;
        newQuote.SubscriptionEndDate__c = wQuote.subscriptionEndDate;
        newQuote.Opportunity__c = wQuote.opportunityId;
        newQuote.QuoteType__c = wQuote.getQuoteTypeAsString();
        newQuote.Status__c = wQuote.getStatusAsString();
        newQuote.ValidUntil__c = wQuote.validUntil;
        newQuote.WrikeAccountId__c = wQuote.wrikeAccountId;
        newQuote.Zuora_Account_Id__c = wQuote.zuoraAccountId;
        newQuote.ZuoraAccountName__c = wQuote.zuoraAccountName;
        newQuote.Zuora_Subscription_Id__c = wQuote.zuoraSubscriptionId;
        newQuote.ZuoraSubscriptionName__c = wQuote.zuoraSubscriptionName;
        newQuote.CompanyName__c = wQuote.companyName;
        newQuote.LegalTerms__c = wQuote.legalTerms;
        newQuote.LegalTermsEffectiveDate__c = wQuote.legalTermsEffectiveDate;
        newQuote.PaymentTerm__c = wQuote.paymentTerm;
        newQuote.InitialTerm__c = wQuote.currentTerm;
        newQuote.NewTerm__c = wQuote.newTerm;
        newQuote.RenewalTerm__c = wQuote.renewalTerm;
        newQuote.Total__c = wQuote.total;
        newQuote.DeltaMrr__c = wQuote.deltaMrr;
        newQuote.BaseLicenseMrr__c = wQuote.baseLicenseMrr;
        newQuote.UserDeltaMrr__c = wQuote.userDeltaMrr;
        newQuote.InvoiceDate__c = wQuote.invoiceDate;
        newQuote.TaxExempt__c = wQuote.taxExempt;
        newQuote.TaxExemptCertificateId__c = wQuote.taxExemptCertificateId;
        newQuote.OnetimeDiscountIncluded__c = (wQuote.onetimeDiscountIncluded == true);
        newQuote.AgencyReliefOfferDiscount__c = (wQuote.agencyReliefOfferDiscount == true);
        newQuote.NumberOfTeams__c = wQuote.numberOfTeams;
        newQuote.DataCenter__c = wQuote.dataCenter;
        newQuote.OriginalQuote__c = wQuote.originalQuoteId;
        newQuote.IsOriginalQuoteApproved__c = wQuote.isOriginalQuoteApproved;

        newQuote.LicenseDiscount__c = wQuote.licenseDiscount;
        newQuote.DeploymentDiscount__c = wQuote.deploymentDiscount;
        newQuote.ResourceManagementDiscount__c = wQuote.resourceManagementDiscount;
        newQuote.CollaboratorBaseLicenseRate__c = wQuote.collaboratorBaseLicenseRate;
        newQuote.DeploymentName__c = wQuote.deploymentName;
        newQuote.OldProductName__c = wQuote.oldProductName;
        newQuote.NewProductName__c = wQuote.newProductName;
		newQuote.BillingPeriodName__c = wQuote.billingPeriodName;
        newQuote.OldQuantity__c = wQuote.oldQuantity;
        newQuote.NewQuantity__c = wQuote.newQuantity;
        newQuote.AddonQuantity__c = wQuote.proofingAddonQuantity;
        newQuote.AdvancedFeatureAddonQuantity__c = wQuote.advancedFeatureAddonQuantity;
        newQuote.OldPricePerUserPerMonth__c = wQuote.oldPricePerUserPerMonth;
        newQuote.NewPricePerUserPerMonth__c = wQuote.newPricePerUserPerMonth;
        newQuote.IsTravelPaid__c = wQuote.isTravelPaid;
        newQuote.NoPSIntegrate__c = wQuote.noPSIntegrate;
        newQuote.PriceIncreasePercent__c = wQuote.priceIncreasePercent;
        newQuote.HasWrikeIntegrate__c = (wQuote.hasWrikeIntegrate == true);
        newQuote.MissingDeployments__c = wQuote.missingDeployments;
        newQuote.HasCustomDeployment__c = (wQuote.hasCustomDeployment == true);
        newQuote.MaxDeploymentDiscount__c = wQuote.maxDeploymentDiscount;
        newQuote.HasFTE__c = (wQuote.hasFTE == true);
        newQuote.AdditionalUsers__c = (wQuote.additionalUsers == true);
        newQuote.AutoRenewalRemoval__c = (wQuote.autoRenewalRemoval == true);
        newQuote.RenewalPriceProtection__c = wQuote.renewalPriceProtection;
        newQuote.PublicityRightsRemoval__c = (wQuote.publicityRightsRemoval == true);
        newQuote.CoMarketingAddition__c = (wQuote.coMarketingAddition == true);
        newQuote.GoverningLaw__c = wQuote.governingLaw;
        newQuote.TermsDataCenter__c = wQuote.termsDataCenter;
        newQuote.WrikeForMarketersDiscount__c = wQuote.wfmDiscount;
        newQuote.WrikeForProfessionalServicesDiscount__c = wQuote.wfpsDiscount;
        newQuote.WrikePerformancePackageDiscount__c = wQuote.wrikePerformancePackageDiscount;
        newQuote.ProjectSyncsDiscount__c = wQuote.projectSyncsDiscount;
        newQuote.WrikeAnalyzeDiscount__c = wQuote.wrikeAnalyzeDiscount;
        newQuote.WrikeIntegrateDiscount__c = wQuote.wrikeIntegrateDiscount;
        newQuote.WrikeIntegrateEnhancedDiscount__c = wQuote.wrikeIntegrateEnhancedDiscount;
        newQuote.WrikeLockDiscount__c = wQuote.wrikeLockDiscount;
        newQuote.WrikeProofDiscount__c = wQuote.wrikeProofDiscount;
        newQuote.WrikePublishDiscount__c = wQuote.wrikePublishDiscount;
        newQuote.BronzeCertificationDiscount__c = wQuote.bronzeCertificationDiscount;
        newQuote.SilverCertificationDiscount__c = wQuote.silverCertificationDiscount;
        newQuote.AdditionalCollaboratorDiscount__c = wQuote.additionalCollaboratorDiscount;
        newQuote.HasUnlimitedCollaborators__c = (wQuote.hasUnlimitedCollaborators == true);
        newQuote.PremiumSupportMismatch__c = (wQuote.premiumSupportMismatch == true);
        newQuote.SelfStartDiscount__c = wQuote.selfStartDiscount;
        newQuote.SmartStartDiscount__c = wQuote.smartStartDiscount;
        newQuote.LegacyIntegrateAddon__c = (wQuote.hasWrikePerformancePackage == true || wQuote.hasOldWrikeIntegrateAddon == true);

        if (wQuote.getIsChanged()) {
            newQuote.HashCode__c = wQuote.hashCode();
            newQuote.LastEditBy__c = UserInfo.getUserId();
            newQuote.LastEditDateTime__c = Datetime.now();
            newQuote.Status__c = WrikeQuote.Status.DRAFT.name();
            newQuote.Primary__c = false;
            if (wQuote.savedHashCode != null) {
                newQuote.IsOriginalQuoteApproved__c = false;
            }
        }
        if(wQuote.items != null) {
            final List<String> discountReasons = new List<String>();
            for(WrikeQuoteItem item : wQuote.items) {
                if(item.getIsAdded() && item.product.discount > 0 && String.isNotBlank(item.product.discountReason)) {
                    discountReasons.add(item.product.discountReason);
                }
            }
            newQuote.Reason_for_Discount__c = discountReasons.isEmpty() ? null : String.join(discountReasons, ';');
        }
        return newQuote;
    }

    public static Quote_Item__c mapToQuoteItem(WrikeQuoteItem wQuoteItem) {
        Quote_Item__c quoteItem = new Quote_Item__c();
        quoteItem.Id = wQuoteItem.id;
        quoteItem.State__c = wQuoteItem.getStateAsString();
        quoteItem.Quote__c = wQuoteItem.quoteId;
        quoteItem.Product__c = wQuoteItem.productId;
        quoteItem.UID__c = wQuoteItem.uid;
        quoteItem.ParentItemUID__c = wQuoteItem.parentItemUID;
        return quoteItem;
    }

    public static List<Quote_Item__c> mapToQuoteItem(List<WrikeQuoteItem> wQuoteItems) {
        List<Quote_Item__c> quoteItems = new List<Quote_Item__c>();
        for (WrikeQuoteItem wQuoteItem : wQuoteItems) {
            quoteItems.add(mapToQuoteItem(wQuoteItem));
        }
        return quoteItems;
    }

    public static Quote_Product__c mapToQuoteProduct(WrikeQuoteProduct wProduct) {
        Quote_Product__c quoteProduct = new Quote_Product__c();
        quoteProduct.Id = wProduct.id;
        quoteProduct.Name = wProduct.name;
        quoteProduct.Description__c = wProduct.description;
        quoteProduct.BillingIntervalListPrice__c = wProduct.billingIntervalListPrice;
        quoteProduct.MRR__c = wProduct.mrr;
        quoteProduct.Price__c = wProduct.effectivePrice;
        quoteProduct.PricePerUserPerMonth__c = wProduct.effectivePricePerUserPerMonth;
        quoteProduct.Discount__c = wProduct.discount;
        quoteProduct.DiscountReason__c = wProduct.discountReason;
        quoteProduct.Quantity__c = wProduct.quantity;
        quoteProduct.ChargeType__c = wProduct.chargeType;
        quoteProduct.ChargeModel__c = wProduct.chargeModel;
        quoteProduct.ChargeNumber__c = wProduct.chargeNumber;
        quoteProduct.PriceFormat__c = wProduct.priceFormat;
        quoteProduct.ServiceType__c = wProduct.serviceType;
        quoteProduct.Term__c = wProduct.term;
        quoteProduct.ZuoraProductId__c = wProduct.zuoraProductId;
        quoteProduct.ZuoraProductRatePlanId__c = wProduct.zuoraProductRatePlanId;
        quoteProduct.ZuoraProductRatePlanChargeId__c = wProduct.zuoraProductRatePlanChargeId;
        quoteProduct.ZuoraProductRatePlanChargeName__c = wProduct.zuoraProductRatePlanChargeName;
        quoteProduct.ZuoraRatePlanId__c = wProduct.zuoraRatePlanId;
        quoteProduct.ZuoraRatePlanChargeId__c = wProduct.zuoraRatePlanChargeId;
        quoteProduct.BillingPeriodName__c = wProduct.billingPeriodName;
        quoteProduct.SoftBundleDiscountApplied__c = wProduct.softBundleDiscountApplied == true;
        return quoteProduct;
    }

    public static List<Quote_Product__c> mapToQuoteProduct(final List<WrikeQuoteItem> wQuoteItems) {
        final ProductService productSrv = ProductService.getInstance();
        final Map<String, Product2> productMap = productSrv.getExistingProductMap();
        final Map<String, Map<String, Product2>> implementationProductMap =
                productSrv.getExistingImplementationProductMap();

        List<Quote_Product__c> quoteProducts = new List<Quote_Product__c>();
        for (WrikeQuoteItem quoteItem : wQuoteItems) {
            final Quote_Product__c product = mapToQuoteProduct(quoteItem.product);

            final Map<String, Product2> rateplanMap = implementationProductMap.get(product.ZuoraProductId__c);
            final Product2 linkedProduct = rateplanMap != null
                    ? rateplanMap.get(product.ZuoraProductRatePlanId__c)
                    : productMap.get(product.ZuoraProductId__c);
            product.Product__c = linkedProduct != null ? linkedProduct.Id : null;
            quoteProducts.add(product);
        }
        return quoteProducts;
    }
}
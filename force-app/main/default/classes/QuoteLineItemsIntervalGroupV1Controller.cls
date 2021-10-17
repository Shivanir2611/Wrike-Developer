/***********************************************************************************
* Class Name : QuoteLineItemsIntervalGroupV1Controller
* Created By : Azarudeen (Exafort)
-----------------------------------------------------------------------------------
* Description : Controller class to provide data to QuoteLineItemsIntervalGroupV1 Visualforce page
-----------------------------------------------------------------------------------
* Version History:
* Version      Developer Name      Date            Detail Features
* 1.0          Azarudeen        05-12-2020       Initial Development
* 2.0          Azarudeen        05-16-2020       Changed design as per Interval Grouping (Line Editor Group)
* 2.1          Azarudeen        05-20-2020       Added display variations on columns
**********************************************************************************/
public class QuoteLineItemsIntervalGroupV1Controller {
    
    //set of public variables
    public Id quoteId;
    public SBQQ__Quote__c quote {get; set;}
    public Boolean displayOneTimePartnerCommission {get; set;}
    Public string SUBSCRIPTIONFEES {get;set;}
    Public string PRODUCTS {get;set;}
    Public string QTY {get;set;}
    Public string ANNUALLISTRATE {get;set;}
    Public string LISTRATE {get;set;}
    Public string DISCOUNT {get;set;}
    Public string ONETIMEDISCOUNT {get;set;}
    Public string PARTNERDISCOUNT {get;set;}
    Public string ANNUALEFFECTIVERATE {get;set;}
    Public string TERM {get;set;}
    Public string LINETOTAL {get;set;}
    Public string ADDITIONALSUBSCRIPTIONFEES {get;set;}
    Public string PROFSERVICESONETIMEFEES {get;set;}
    Public string OTHERONETIMEFEES {get;set;}
    Public string QUOTETOTAL{get;set;}
    public string currencyISOCode{get;set;}
    
    //set of public flags to conditionally display different tables
    public boolean subscriptionProductsExists {get;set;}
    public boolean addnlSubscriptionProductsExists {get;set;}
    public boolean professionalServicesExists {get;set;}
    public boolean otherOneTimeProductsExists {get;set;}
    public Boolean showSubscriptionTable {get;set;}
    
    //set of public flags to conditionally display different columns
    public boolean displayQuantity {get;set;}
    public boolean displayAnnualListRate {get;set;}
    public boolean displayDiscount {get;set;}
    public string discountDisplayType {get;set;}
    public boolean displayAnnualEffectiveRate {get;set;}
    public boolean displayTermEffectiveTotal {get;set;}
    public boolean displayPartnerDiscount {get;set;}
    public boolean displayOneTimeDiscount {get;set;}
    
    //public variables to display Discount type (Currency/Percentage)
    public decimal totalTemplateDiscountAmt {get;set;}
    public decimal totalTemplateDiscountPercentage {get;set;}
    
    //public variables to display total for each table
    public Decimal SubscriptionFeesTotal {get;set;}
    public Decimal subscriptiontotalWithPartnerDiscount {get;set;}
    public Decimal addtnlsubscriptotalWithPartnerDiscount {get;set;}
    public Decimal AdditionalSubscriptionFeesTotal {get;set;}
    public Decimal OtherOneTimeFeesTotal {get;set;}
    public Decimal professionalServicesTotal {get;set;}
    public Decimal grandTotal {get;set;}
    public Decimal oneTimeDiscountTotal {get; set;}
    
    //public variables to collect data and display
    public Map<String, List<SBQQ__QuoteLine__c>> intervalKeyWithLineItemsMap {get;set;}
    public Map<String, Integer> intervalKeyWithLineItemsMapListSize {get;set;}
    public Map<String, String> deploymentScheduleIntervalMap {get;set;}
    public Map<String, String> deploymentScheduleIntervalForEachLineMap {get;set;}
    public Map<String, List<SBQQ__QuoteLine__c>> supportProductsMap {get;set;}
    public List<SBQQ__QuoteLine__c> professionalServicesList {get;set;}
    Public List<SBQQ__QuoteLine__c> otherOneTimeFeesMap {get;set;}
    public List<String> intervalKeyList {get;set;}
    public Map<String, Integer> rowspanHelperMap {get;set;}
    
    public Map<String, Decimal> eachIntervalTotalDiscountInPercentage {get;set;}
    public Map<String, Decimal> eachIntervalTotalDiscountInAmt {get;set;}
    public Map<String, Decimal> eachIntervalOneTotalDiscountInAmt {get;set;}
    public Map<String, Decimal> eachIntervalTotalAnnualListRate {get;set;}
    public Map<String, Decimal> eachIntervalTotalAnnualPartnerRate{get;set;}
    public Map<String, Decimal> eachIntervalTotalAnnualEffectRate{get;set;}
    public Map<String, Decimal> eachIntervalPartnerDiscount {get;set;}
    public Map<String, Decimal> eachIntervalTotalAnnualEffectiveRate {get;set;}
    public Map<String, Decimal> subscriptionsEachIntervalLineTotal {get;set;}
    public Map<String, Decimal> subscriptionsEachIntervalLinePartnerTotal {get;set;}
    public Map<String, Decimal> subscriptionsEachIntervalCustomerAmount {get;set;}
    public Map<String, Decimal> subscriptionsEachIntervalEffectiveAmount {get;set;}
    public Map<String, Integer> quantityRowSpanHelperMap {get;set;}
    public Map<String, boolean> notFrmSolutionPkgWithinSameIntervalMap {get;set;}
    public Integer numberOfColumnsToSpan {get;set;}
    public Integer subscriptionTotalTextSpan {get;set;}
    public String columnWidth {get;set;}
    public Integer numberOfOnetimeColumnsToSpan {get;set;}
    
    //professional services bundle
    public boolean professionalServPackage{get;set;}
    public List<SBQQ__QuoteLine__c> professionalServicesPackageList {get;set;}
    public Decimal profServPackageListRate {get;set;}
    public Decimal profServPackageDiscountInPercentage {get;set;}
    public Decimal profServPackageDiscountInAmt {get;set;}
    public Decimal profServPackagePartnerDiscount {get;set;}
    public Decimal profServPackageTotal {get;set;}
    public Integer numberOfRowsToSpanProfServ {get;set;}
    
    //below map used to display only the dates in the subscription table.
    public Map<string, string> displayOnlyDatesMap{get;set;}
    public Boolean hasReseller {get;set;}
    
    //constructor
    public QuoteLineItemsIntervalGroupV1Controller(){
        //define initial values for all the variables
        this.quoteId = (Id)ApexPages.currentPage().getParameters().get(Constants.QID);
        this.quote = [
                SELECT Id, ResellerAccount__c, CurrencyIsoCode, SBQQ__NetAmount__c, Display_One_Time_Discount__c,
                       Display_Quantity__c, Display_Annual_List_Rate__c, Display_Discount__c, Display_Line_Total__c,
                       Display_Annual_Effective_Rate__c, Discount_Type__c, Display_Partner_Discount__c, QuoteSubType__c,
                       DisplayAnnualPartnerRate__c, DisplayPartnerPurchasePrice__c, OneTimeDiscountApplied__c
                FROM SBQQ__Quote__c
                WHERE Id = :quoteId
        ];
        this.displayOneTimePartnerCommission = false;

        SUBSCRIPTIONFEES = Constants.SUBSCRIPTIONFEES;
        PRODUCTS = Constants.PRODUCTS;
        QTY = Constants.QTY;
        ANNUALLISTRATE = Constants.ANNUALLISTRATE;
        LISTRATE = Constants.LISTRATE;
        DISCOUNT = Constants.DISCOUNT;
        ONETIMEDISCOUNT = Constants.ONETIMEDISCOUNT;
        PARTNERDISCOUNT = Constants.PARTNERDISCOUNT;
        ANNUALEFFECTIVERATE = Constants.ANNUALEFFECTIVERATE;
        TERM = Constants.TERM;
        LINETOTAL = Constants.LINETOTAL;
        ADDITIONALSUBSCRIPTIONFEES = Constants.ADDITIONALSUBSCRIPTIONFEES;
        PROFSERVICESONETIMEFEES = Constants.PROFSERVICESONETIMEFEES;
        OTHERONETIMEFEES = Constants.OTHERONETIMEFEES;
        QUOTETOTAL = Constants.QUOTETOTAL;
        currencyISOCode = '';
        subscriptionProductsExists = false;
        addnlSubscriptionProductsExists = false;
        professionalServicesExists = false;
        otherOneTimeProductsExists = false;
        
        displayQuantity = false;
        displayAnnualListRate = false;
        displayDiscount = false;
        discountDisplayType = '';
        displayAnnualEffectiveRate = false;
        displayTermEffectiveTotal = false;
        displayPartnerDiscount = false;
        displayOneTimeDiscount = false;
        
        totalTemplateDiscountAmt = 0;
        totalTemplateDiscountPercentage = 0;
        
        SubscriptionFeesTotal = 0;
        subscriptiontotalWithPartnerDiscount = 0;
        addtnlsubscriptotalWithPartnerDiscount = 0;
        AdditionalSubscriptionFeesTotal = 0;
        OtherOneTimeFeesTotal = 0;
        professionalServicesTotal = 0;
        grandTotal = 0;
        oneTimeDiscountTotal = 0;
        intervalKeyWithLineItemsMap = new Map<String, List<SBQQ__QuoteLine__c>>();
        intervalKeyWithLineItemsMapListSize = new Map<String, Integer>();
        deploymentScheduleIntervalMap = new Map<String, String>();
        deploymentScheduleIntervalForEachLineMap = new Map<String, String>();
        supportProductsMap = new Map<String, List<SBQQ__QuoteLine__c>>();
        professionalServicesList = new List<SBQQ__QuoteLine__c>();
        otherOneTimeFeesMap = new List<SBQQ__QuoteLine__c>();
        intervalKeyList = new List<String>();
        rowspanHelperMap = new Map<String, Integer>();
        
        eachIntervalTotalDiscountInPercentage = new Map<String, Decimal>();
        eachIntervalTotalDiscountInAmt = new Map<String, Decimal>();
        eachIntervalOneTotalDiscountInAmt = new Map<String, Decimal>();
        eachIntervalTotalAnnualListRate = new Map<String, Decimal>();
        eachIntervalTotalAnnualEffectRate = new Map<String, Decimal>();
        eachIntervalTotalAnnualPartnerRate = new Map<String, Decimal>();
        eachIntervalPartnerDiscount = new Map<String, Decimal>();
        eachIntervalTotalAnnualEffectiveRate = new Map<String, Decimal>();
        subscriptionsEachIntervalLineTotal = new Map<String, Decimal>();
        subscriptionsEachIntervalLinePartnerTotal = new Map<String, Decimal>();
        subscriptionsEachIntervalCustomerAmount = new Map<String, Decimal>();
        quantityRowSpanHelperMap = new Map<String, Integer>();
        notFrmSolutionPkgWithinSameIntervalMap = new Map<String, boolean>();
        numberOfColumnsToSpan = 0;
        subscriptionTotalTextSpan = 0;
        numberOfOnetimeColumnsToSpan = 1;
        columnWidth = '';
        professionalServPackage = false;
        professionalServicesPackageList = new List<SBQQ__QuoteLine__c>();
        profServPackageListRate =0;
        profServPackageDiscountInPercentage=0;
        profServPackageDiscountInAmt=0;
        profServPackagePartnerDiscount = 0;
        profServPackageTotal = 0;
        numberOfRowsToSpanProfServ=0;
        
        displayOnlyDatesMap = new Map<string, string>();
        showSubscriptionTable = true;
        hasReseller = false;
    }
    //below method is invoked on page action
    public void getLines(){
        Set<String> intervalSet = new Set<String>();
         if ('Add Deployment Only'.equals(quote.QuoteSubType__c)) {
             this.showSubscriptionTable = false;
         }
        //quote level data fields to use in page
        CurrencyIsoCode = quote.CurrencyIsoCode;
        grandTotal = quote.SBQQ__NetAmount__c;
        displayQuantity = quote.Display_Quantity__c;
        displayAnnualListRate = quote.Display_Annual_List_Rate__c;
        displayDiscount = quote.Display_Discount__c;
        discountDisplayType = quote.Discount_Type__c != null? quote.Discount_Type__c : 'Percentage';
        displayAnnualEffectiveRate = quote.Display_Annual_Effective_Rate__c;
        displayTermEffectiveTotal = quote.Display_Line_Total__c;
        displayPartnerDiscount = quote.Display_Partner_Discount__c;
        if(quote.Display_One_Time_Discount__c && quote.Display_Discount__c){
            displayOneTimeDiscount = true;
        }
        this.hasReseller = quote.ResellerAccount__c != null;

        //form the interval term
        for(SBQQ__QuoteLine__c quotelineItem : sortQuoteLinesBasedOnSolutionPackage(quote.Id)){
            if (quotelineItem.EffectiveLine__c
                    && quotelineItem.NonRenewableDiscount__c != null
                    && quotelineItem.NonRenewableDiscount__c > 0) {
                this.oneTimeDiscountTotal = this.oneTimeDiscountTotal +
                        quotelineItem.NonRenewableDiscount__c
                        * quotelineItem.SBQQ__EffectiveQuantity__c
                        * quotelineItem.SBQQ__ProrateMultiplier__c;
            }
            if(quotelineItem.SBQQ__SubscriptionType__c != null && quotelineItem.SBQQ__SubscriptionType__c != 'One-time' ){
                if(quotelineItem.SBQQ__EffectiveStartDate__c != null && quotelineItem.SBQQ__EffectiveEndDate__c != null){
                    //pass the start date and end date to reusable method to return the date format. For ex: 12/31/2020 convert to DEC 31, 2020
                    string intervalKey = returnMonthName(quotelineItem.SBQQ__EffectiveStartDate__c.month())+' '+quotelineItem.SBQQ__EffectiveStartDate__c.day()+', '+quotelineItem.SBQQ__EffectiveStartDate__c.year()+' - '+returnMonthName(quotelineItem.SBQQ__EffectiveEndDate__c.month())+' '+quotelineItem.SBQQ__EffectiveEndDate__c.day()+', '+quotelineItem.SBQQ__EffectiveEndDate__c.year();
                    if(quotelineItem.SBQQ__Group__c != null){
                        intervalKey = intervalKey+' - '+quotelineItem.SBQQ__Group__r.Id;
                    }
                    intervalSet.add(intervalKey);
                    subscriptionProductsExists = true;
                }
            }
        }
        if(intervalSet.size() > 0){
            intervalKeyList.addAll(intervalSet);
        }

        for(SBQQ__QuoteLine__c quotelineItem : sortQuoteLinesBasedOnSolutionPackage(quote.Id)){
            //form the intervalkey
            string intervalKey='';
            if(quotelineItem.SBQQ__EffectiveStartDate__c != null && quotelineItem.SBQQ__EffectiveEndDate__c != null){
                intervalKey = returnMonthName(quotelineItem.SBQQ__EffectiveStartDate__c.month())+' '+quotelineItem.SBQQ__EffectiveStartDate__c.day()+', '+quotelineItem.SBQQ__EffectiveStartDate__c.year()+' - '+returnMonthName(quotelineItem.SBQQ__EffectiveEndDate__c.month())+' '+quotelineItem.SBQQ__EffectiveEndDate__c.day()+', '+quotelineItem.SBQQ__EffectiveEndDate__c.year();
                if(quotelineItem.SBQQ__Group__c != null){
                    intervalKey = intervalKey+' - '+quotelineItem.SBQQ__Group__r.Id;
                }
            }

            //collect the subscription products in a map
            if(quotelineItem.SBQQ__SubscriptionType__c != null && quotelineItem.SBQQ__SubscriptionType__c == 'Renewable' && quotelineItem.SBQQ__Product__r.PG1__c !='Services'){

                if(intervalKeyWithLineItemsMap.containsKey(intervalKey)){
                    List<SBQQ__QuoteLine__c> tempLineItem = intervalKeyWithLineItemsMap.get(intervalKey);
                    tempLineItem.add(quotelineItem);
                    intervalKeyWithLineItemsMap.put(intervalKey, tempLineItem);
                }
                else{
                    List<SBQQ__QuoteLine__c> tempLineItem = new List<SBQQ__QuoteLine__c>();
                    tempLineItem.add(quotelineItem);
                    intervalKeyWithLineItemsMap.put(intervalKey, tempLineItem);
                }
                SubscriptionFeesTotal += quotelineItem.SBQQ__NetTotal__c;
                subscriptiontotalWithPartnerDiscount += quotelineItem.SBQQ__CustomerTotal__c;

                //Calculate total discount for each interval group in Percentage
                if(quotelineItem.SBQQ__RequiredBy__c != null && (quotelineItem.SBQQ__RequiredBy__r.SBQQ__ProductName__c == 'Wrike Solution Package' || quotelineItem.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__ProductName__c == 'Wrike Solution Package')){
                    if(discountDisplayType != '' && discountDisplayType == 'Percentage'){
                        if(eachIntervalTotalDiscountInPercentage.containsKey(intervalKey)){
                            Decimal lineItemDiscount = eachIntervalTotalDiscountInPercentage.get(intervalKey);
                            Decimal originalDiscount = 0;
                            if(quotelineItem.SBQQ__TotalDiscountRate__c == null){
                                originalDiscount = 0;
                            }
                            else{
                                originalDiscount = quotelineItem.SBQQ__TotalDiscountRate__c;
                            }
                            //Decimal tempDiscount = lineItemDiscount + originalDiscount;
                            eachIntervalTotalDiscountInPercentage.put(intervalKey, lineItemDiscount + originalDiscount);
                        }
                        else{
                            if(quotelineItem.SBQQ__TotalDiscountRate__c != null){
                                eachIntervalTotalDiscountInPercentage.put(intervalKey, quotelineItem.SBQQ__TotalDiscountRate__c);
                            }
                            else{
                                eachIntervalTotalDiscountInPercentage.put(intervalKey, 0);
                            }
                        }
                    }
                    //Calculate discount for each interval group in Amount
                    //else if(discountDisplayType != '' && discountDisplayType == 'Currency'){
                    if(eachIntervalTotalDiscountInAmt.containsKey(intervalKey)){
                        Decimal lineItemDiscount = eachIntervalTotalDiscountInAmt.get(intervalKey);
                        Decimal originalDiscount = 0;
                        if(quotelineItem.SBQQ__TotalDiscountAmount__c == null){
                            originalDiscount = 0;
                        }
                        else{
                            originalDiscount = quotelineItem.SBQQ__TotalDiscountAmount__c;
                        }
                        //Decimal tempDiscount = lineItemDiscount + originalDiscount;
                        eachIntervalTotalDiscountInAmt.put(intervalKey, lineItemDiscount + originalDiscount);
                    }
                    else{
                        if(quotelineItem.SBQQ__TotalDiscountAmount__c != null){
                            eachIntervalTotalDiscountInAmt.put(intervalKey, quotelineItem.SBQQ__TotalDiscountAmount__c);
                        }
                        else{
                            eachIntervalTotalDiscountInAmt.put(intervalKey, 0);
                        }
                    }
                    //calculate each interval group Partner Discount
                    if(eachIntervalPartnerDiscount.containsKey(intervalKey)){
                        Decimal lineItemPartnerDiscount = eachIntervalPartnerDiscount.get(intervalKey);
                        Decimal partnerDisc = 0;
                        if(quotelineItem.SBQQ__PartnerDiscount__c != null){
                            partnerDisc = quotelineItem.SBQQ__PartnerDiscount__c;
                        }
                        eachIntervalPartnerDiscount.put(intervalKey, lineItemPartnerDiscount + partnerDisc);
                    }
                    else{
                        Decimal partnerDisc = 0;
                        if(quotelineItem.SBQQ__PartnerDiscount__c != null){
                            partnerDisc = quotelineItem.SBQQ__PartnerDiscount__c;
                        }
                        eachIntervalPartnerDiscount.put(intervalKey, partnerDisc);
                    }
                    //}
                    //calculate each interval group Line Total
                    if(subscriptionsEachIntervalLineTotal.containsKey(intervalKey)){
                        Decimal lineItemTotal = subscriptionsEachIntervalLineTotal.get(intervalKey);
                        subscriptionsEachIntervalLineTotal.put(intervalKey, lineItemTotal + quotelineItem.SBQQ__CustomerTotal__c);
                    }
                    else{
                        subscriptionsEachIntervalLineTotal.put(intervalKey, quotelineItem.SBQQ__CustomerTotal__c);
                    }

                    if(subscriptionsEachIntervalLinePartnerTotal.containsKey(intervalKey)){
                        Decimal lineItemPartnerTotal = subscriptionsEachIntervalLinePartnerTotal.get(intervalKey);
                        subscriptionsEachIntervalLinePartnerTotal.put(intervalKey, lineItemPartnerTotal + quotelineItem.SBQQ__NetTotal__c);
                    }
                    else{
                        subscriptionsEachIntervalLinePartnerTotal.put(intervalKey, quotelineItem.SBQQ__NetTotal__c);
                    }

                    //calculate each interval group customer total for finding partner discount -> Partner Discount = Customer Total - Net Total
                    if(subscriptionsEachIntervalCustomerAmount.containsKey(intervalKey)){
                        Decimal customerTotal = subscriptionsEachIntervalCustomerAmount.get(intervalKey);
                        subscriptionsEachIntervalCustomerAmount.put(intervalKey, customerTotal+quotelineItem.SBQQ__CustomerTotal__c);
                    }
                    else{
                        subscriptionsEachIntervalCustomerAmount.put(intervalKey, quotelineItem.SBQQ__CustomerTotal__c);
                    }

                    //calculate one-time discount for each group
                    if(eachIntervalOneTotalDiscountInAmt.containsKey(intervalKey)){
                        Decimal oneTimeDiscount = eachIntervalOneTotalDiscountInAmt.get(intervalKey);
                        Decimal oneTime = 0;
                        if(quotelineItem.TermNonRenewableDiscount__c != null){
                            oneTime = quotelineItem.TermNonRenewableDiscount__c;
                        }
                        eachIntervalOneTotalDiscountInAmt.put(intervalKey,oneTimeDiscount + oneTime );
                    }
                    else{
                        Decimal oneTime = 0;
                        if(quotelineItem.TermNonRenewableDiscount__c != null){
                            oneTime = quotelineItem.TermNonRenewableDiscount__c;
                        }
                        eachIntervalOneTotalDiscountInAmt.put(intervalKey,oneTime);
                    }

                    //calculate each interval group Annual List Rate
                    if(eachIntervalTotalAnnualListRate.containsKey(intervalKey)){
                        Decimal AnnualListRate = eachIntervalTotalAnnualListRate.get(intervalKey);
                        eachIntervalTotalAnnualListRate.put(intervalKey, AnnualListRate + quotelineItem.Annual_List_Price__c);
                    }
                    else{
                        eachIntervalTotalAnnualListRate.put(intervalKey, quotelineItem.Annual_List_Price__c);
                    }

                    //calculate each interval group Annual Effective Rate
                    final Decimal annualPartnerRate = (quotelineItem.SBQQ__NetTotal__c / quotelineItem.SBQQ__ProrateMultiplier__c) / (quotelineItem.SBQQ__DefaultSubscriptionTerm__c / 12);
                    if(eachIntervalTotalAnnualPartnerRate.containsKey(intervalKey)){
                        Decimal prevAnnualPartnerRate = eachIntervalTotalAnnualPartnerRate.get(intervalKey);
                        eachIntervalTotalAnnualPartnerRate.put(intervalKey, prevAnnualPartnerRate + annualPartnerRate);
                    }
                    else{
                        eachIntervalTotalAnnualPartnerRate.put(intervalKey, annualPartnerRate);
                    }

                    final Decimal annualEffectiveRate = (quotelineItem.SBQQ__CustomerTotal__c / quotelineItem.SBQQ__ProrateMultiplier__c) / (quotelineItem.SBQQ__DefaultSubscriptionTerm__c / 12);
                    if(eachIntervalTotalAnnualEffectRate.containsKey(intervalKey)){
                        Decimal prevAnnualEffectiveRate = eachIntervalTotalAnnualEffectRate.get(intervalKey);
                        eachIntervalTotalAnnualEffectRate.put(intervalKey, prevAnnualEffectiveRate + annualEffectiveRate);
                    }
                    else{
                        eachIntervalTotalAnnualEffectRate.put(intervalKey, annualEffectiveRate);
                    }

                    //calculate each interval group Annual Effective Rate for Total Discount Rate Percentage calculation
                    if(eachIntervalTotalAnnualEffectiveRate.containsKey(intervalKey)){
                        Decimal prevAnnualEffectiveRate = eachIntervalTotalAnnualEffectiveRate.get(intervalKey);
                        eachIntervalTotalAnnualEffectiveRate.put(intervalKey, prevAnnualEffectiveRate + quotelineItem.SBQQ__ListTotal__c);
                    }
                    else{
                        eachIntervalTotalAnnualEffectiveRate.put(intervalKey, quotelineItem.SBQQ__ListTotal__c);
                    }

                }


                //Map Wrike Solution Package header
                if(quotelineItem.SBQQ__RequiredBy__c != null && (quotelineItem.SBQQ__RequiredBy__r.SBQQ__ProductName__c == 'Wrike Solution Package' || quotelineItem.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__ProductName__c == 'Wrike Solution Package')){
                    notFrmSolutionPkgWithinSameIntervalMap.put(quotelineItem.Id, true);
                    System.debug('### intervalKey ### '+intervalKey);
                    deploymentScheduleIntervalMap.put(intervalKey, 'Wrike Solution Package');
                    deploymentScheduleIntervalForEachLineMap.put(intervalKey+quotelineItem.Id, 'Wrike Solution Package');
                }
                else{
                    notFrmSolutionPkgWithinSameIntervalMap.put(quotelineItem.Id, false);
                    //if key already presents, do not override with empty value
                    if(deploymentScheduleIntervalMap.containsKey(intervalKey)){
                        if(deploymentScheduleIntervalMap.get(intervalKey) == 'Wrike Solution Package'){
                            deploymentScheduleIntervalMap.put(intervalKey, 'Wrike Solution Package');
                        }
                    }
                    else{
                        deploymentScheduleIntervalMap.put(intervalKey, '');
                    }
                    deploymentScheduleIntervalForEachLineMap.put(intervalKey+quotelineItem.Id, '');
                }

            }
            //collect support products in a map
            else if((quotelineItem.SBQQ__Product__r.PG2__c != null && quotelineItem.SBQQ__Product__r.PG2__c =='Support')){
                if(supportProductsMap.containsKey(intervalKey)){
                    List<SBQQ__QuoteLine__c> tempLineItem = supportProductsMap.get(intervalKey);
                    tempLineItem.add(quotelineItem);
                    supportProductsMap.put(intervalKey, tempLineItem);
                }
                else{
                    List<SBQQ__QuoteLine__c> tempLineItem = new List<SBQQ__QuoteLine__c>();
                    tempLineItem.add(quotelineItem);
                    supportProductsMap.put(intervalKey, tempLineItem);
                }
                AdditionalSubscriptionFeesTotal +=quotelineItem.SBQQ__NetTotal__c;
                addtnlsubscriptotalWithPartnerDiscount += quotelineItem.SBQQ__CustomerTotal__c;
                addnlSubscriptionProductsExists = true;
            }
            //collect professional services in a map
            else if(quotelineItem.SBQQ__Product__r.PG1__c == 'Services' && (quotelineItem.SBQQ__Product__r.PG2__c=='Deployment' || quotelineItem.SBQQ__Product__r.PG2__c =='Add On')){
                //professionalServicesList.add(quotelineItem);
                professionalServicesTotal +=quotelineItem.SBQQ__NetTotal__c;
                professionalServicesExists = true;

                if (quotelineItem.SBQQ__RequiredBy__c != null
                        && quotelineItem.SBQQ__RequiredBy__r.SBQQ__ProductName__c == 'Professional Services Package') {

                    professionalServPackage = true;
                    professionalServicesPackageList.add(quotelineItem);
                    profServPackageListRate = profServPackageListRate + quotelineItem.SBQQ__ListPrice__c;
                    if(discountDisplayType == 'Percentage'){
                        profServPackageDiscountInPercentage = profServPackageDiscountInPercentage + quotelineItem.SBQQ__TotalDiscountRate__c;
                    }
                    profServPackageDiscountInAmt = profServPackageDiscountInAmt + quotelineItem.SBQQ__TotalDiscountAmount__c;
                    profServPackageTotal = profServPackageTotal + quotelineItem.SBQQ__NetTotal__c;
                    profServPackagePartnerDiscount = quotelineItem.SBQQ__PartnerDiscount__c;
                }
                else{
                    professionalServicesList.add(quotelineItem);
                }
            }
            else if((quotelineItem.SBQQ__SubscriptionType__c == 'One-time' || quotelineItem.SBQQ__SubscriptionType__c == '' || quotelineItem.SBQQ__SubscriptionType__c == null) && !quotelineItem.SBQQ__ProductName__c.Contains('Professional')){
                OtherOneTimeFeesTotal+=quotelineItem.SBQQ__NetTotal__c;
                otherOneTimeFeesMap.add(quotelineItem);
                otherOneTimeProductsExists = true;
            }
        }
        //form the map to rowspan within a table for Wrike Solution package products
        for(String mapKeyset : intervalKeyWithLineItemsMap.keySet()){
            List<SBQQ__QuoteLine__c> quoteLines = intervalKeyWithLineItemsMap.get(mapKeyset);
            
            integer i=0;
            for(SBQQ__QuoteLine__c eachLine : quoteLines){
                if(eachLine.SBQQ__RequiredBy__c != null && (eachLine.SBQQ__RequiredBy__r.SBQQ__ProductName__c == 'Wrike Solution Package' || eachLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__ProductName__c == 'Wrike Solution Package')){
                    i++;
                }
            }
            rowspanHelperMap.put(mapKeyset, i);
            intervalKeyWithLineItemsMapListSize.put(mapKeyset, i);
            
            /*if(quoteLines.size() == 1){
                quantityRowSpanHelperMap.put(mapKeyset+ '-' + string.valueOf(quoteLines[0].SBQQ__Quantity__c), 1);
            }
            else if(quoteLines.size() > 1){
                for(SBQQ__QuoteLine__c lineItem : quoteLines){
                    
                }
                
            }*/
            /*decimal quantity=0;
            Integer i=0;
            for(SBQQ__QuoteLine__c lineItem : quoteLines){
                if(quantity ==lineItem.SBQQ__Quantity__c){
                    i++;
                }
                quantity =lineItem.SBQQ__Quantity__c;
            }
            quantityRowSpanHelperMap.put(mapKeyset, i);
            system.debug('####quantityRowSpanHelperMap ###'+quantityRowSpanHelperMap);*/
        }
        numberOfRowsToSpanProfServ = professionalServicesPackageList.size() + 1;
        if(profServPackageDiscountInPercentage > 0 && professionalServicesPackageList.size() > 0){
            profServPackageDiscountInPercentage = profServPackageDiscountInPercentage / professionalServicesPackageList.size();
        }
        colspan(displayDiscount,displayAnnualListRate,displayPartnerDiscount,displayOneTimeDiscount, displayAnnualEffectiveRate, displayTermEffectiveTotal);
        
        //remove extra languge in the group date header in the subscription table
        if(!intervalKeyList.isEmpty()){
            for(String str : intervalKeyList){
                string uptoStartDate = str.substringBefore('-');
                string remainingAfterStartDate = str.substringAfter('-');
                
                displayOnlyDatesMap.put(str, uptoStartDate+'-'+remainingAfterStartDate.substringBefore('-'));
            }
        }
        
    }
    Public void colspan(boolean displayDiscount, boolean displayAnnualListRate, boolean displayPartnerDiscount, boolean displayOneTimeDiscount, boolean displayAnnualEffectiveRate, boolean displayTermEffectiveTotal){
        //Integer numberTospan = 0;
        Integer columnWidthInNum = 0;
        if(displayDiscount == false && displayAnnualListRate == false && displayPartnerDiscount == false && displayOneTimeDiscount == false){
            numberOfColumnsToSpan = 4;
            subscriptionTotalTextSpan = 3;
            //columnWidth = '67%';
            columnWidthInNum = 66;
        }
        else if((displayDiscount == false && displayAnnualListRate == false && displayPartnerDiscount == false) || 
                (displayAnnualListRate == false && displayPartnerDiscount == false && displayOneTimeDiscount == false) ||
                (displayPartnerDiscount == false && displayOneTimeDiscount == false && displayDiscount == false) || 
                (displayOneTimeDiscount == false && displayDiscount == false && displayAnnualListRate == false)){
                    
            numberOfColumnsToSpan = 5;
            subscriptionTotalTextSpan = 4;
            //columnWidth = '58%';
            columnWidthInNum = 57;
        }
        else if((displayDiscount == false && displayAnnualListRate == false) || 
                (displayAnnualListRate == false && displayPartnerDiscount == false) || 
                (displayPartnerDiscount == false && displayOneTimeDiscount == false) ||
                (displayOneTimeDiscount == false && displayDiscount == false) ||
                (displayAnnualListRate == false && displayDiscount == false) ||
                (displayAnnualListRate == false && displayOneTimeDiscount == false)){
                    
            numberOfColumnsToSpan = 6;
            subscriptionTotalTextSpan = 5;
            //columnWidth = '49%';
            columnWidthInNum = 48;
        }
        else if((displayDiscount == false || displayAnnualListRate == false) || 
                (displayAnnualListRate == false || displayPartnerDiscount == false) || 
                (displayPartnerDiscount == false || displayOneTimeDiscount == false) ||
                (displayOneTimeDiscount == false || displayDiscount == false) ||
                (displayAnnualListRate == false || displayDiscount == false) ||
                (displayAnnualListRate == false || displayOneTimeDiscount == false)){
                    
            numberOfColumnsToSpan = 7;
            subscriptionTotalTextSpan = 6;
            //columnWidth = '40%';
            columnWidthInNum = 39;
        }
        else{
            numberOfColumnsToSpan = 8;
            subscriptionTotalTextSpan = 7;
            //columnWidth = '31%';
            columnWidthInNum = 30;
        }
        if (quote.DisplayAnnualPartnerRate__c) {
            numberOfColumnsToSpan = numberOfColumnsToSpan + 1;
            subscriptionTotalTextSpan = subscriptionTotalTextSpan + 1;
        }
        if (quote.DisplayPartnerPurchasePrice__c) {
            numberOfColumnsToSpan = numberOfColumnsToSpan + 1;
            subscriptionTotalTextSpan = subscriptionTotalTextSpan + 1;
        }
        
        //check Annual Effective Rate and Term Effective Total
        if(displayAnnualEffectiveRate == false){
            numberOfColumnsToSpan = numberOfColumnsToSpan -1;
            subscriptionTotalTextSpan = subscriptionTotalTextSpan - 1;
            columnWidthInNum = columnWidthInNum+13;
        }
        if(displayTermEffectiveTotal == false){
            numberOfColumnsToSpan = numberOfColumnsToSpan -1;
            subscriptionTotalTextSpan = subscriptionTotalTextSpan - 1;
            columnWidthInNum = columnWidthInNum+13;
        }
        if(columnWidthInNum != null){
            columnWidth = string.valueOf(columnWidthInNum)+'%';
        }

        if (displayDiscount) {
            numberOfOnetimeColumnsToSpan = numberOfOnetimeColumnsToSpan + 1;
        }
        if (displayAnnualListRate) {
            numberOfOnetimeColumnsToSpan = numberOfOnetimeColumnsToSpan + 1;
        }
        if (displayTermEffectiveTotal) {
            numberOfOnetimeColumnsToSpan = numberOfOnetimeColumnsToSpan + 1;
        }
        if (displayPartnerDiscount) {
            numberOfOnetimeColumnsToSpan = numberOfOnetimeColumnsToSpan + 1;
        }
        system.debug('#### columnWidth ====> '+columnWidth);
    }
    public string returnMonthName(Integer month){
        String monthName = '';
        if(month == 1){monthName='JAN';}else if(month == 2){monthName='FEB';}else if(month == 3){monthName='MAR';}else if(month == 4){monthName='APR';}else if(month == 5){monthName='MAY';}else if(month == 6){monthName='JUN';}else if(month == 7){monthName='JUL';}else if(month == 8){monthName='AUG';}else if(month == 9){monthName='SEP';}else if(month == 10){monthName='OCT';}else if(month == 11){monthName='NOV';}else if(month == 12){monthName='DEC';}
        return monthName;
    }
    public List<SBQQ__QuoteLine__c> sortQuoteLinesBasedOnSolutionPackage(final String quoteId){
        final List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        final List<SBQQ__QuoteLineGroup__c> quoteGroups = [
                SELECT Id, (
                    SELECT Id, Annual_List_Price__c, SBQQ__Number__c, SBQQ__RequiredBy__r.SBQQ__ProductName__c,
                           SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__ProductName__c, SBQQ__Quantity__c,
                           SBQQ__EffectiveQuantity__c, QS_Annual_Recurring_Revenue__c, NonRenewableDiscount__c,
                           EffectiveLine__c, SBQQ__ProductCode__c, SBQQ__DefaultSubscriptionTerm__c,
                           TermNonRenewableDiscount__c, SBQQ__ProrateMultiplier__c, SBQQ__PartnerDiscount__c, Hide_Quantity__c,
                           SBQQ__PriorQuantity__c, SBQQ__ListTotal__c, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c,
                           SBQQ__StartDate__c, SBQQ__EndDate__c, Subscription_Start_To_End_Dates__c, SBQQ__SubscriptionTerm__c,
                           SBQQ__ListPrice__c, SBQQ__TotalDiscountAmount__c,SBQQ__NetTotal__c,SBQQ__CustomerTotal__c, SBQQ__Group__c,
                           SBQQ__Group__r.Name, SBQQ__Group__r.Id, SBQQ__Group__r.SBQQ__Description__c, SBQQ__ProductFamily__c,
                           SBQQ__ProductOption__c, SBQQ__ProductOption__r.SBQQ__ConfiguredSKU__r.Name, SBQQ__RequiredBy__c,
                           SBQQ__TotalDiscountRate__c, SBQQ__ProductName__c, SBQQ__ProductOption__r.SBQQ__Feature__c,
                           SBQQ__ProductOption__r.SBQQ__Feature__r.Name, SBQQ__Description__c, SBQQ__SubscriptionType__c,
                           SBQQ__Bundled__c, SBQQ__Product__r.PG1__c, SBQQ__Product__r.PG2__c
                    FROM SBQQ__LineItems__r
                    WHERE SBQQ__ProductName__c != 'Wrike Solution Package'
                      AND SBQQ__Bundled__c = false
                      ORDER BY SBQQ__EffectiveStartDate__c, SBQQ__Product__r.SBQQ__SortOrder__c
                )
                FROM SBQQ__QuoteLineGroup__c
                WHERE SBQQ__Quote__c = :quoteId
                ORDER BY createddate
        ];
        for(SBQQ__QuoteLineGroup__c quoteGroup : quoteGroups) {
            Boolean effectiveGroup = false;
            for (SBQQ__QuoteLine__c line : quoteGroup.SBQQ__LineItems__r){
                if (line.EffectiveLine__c) {
                    effectiveGroup = true;
                }
            }
            if (effectiveGroup) {
                List<SBQQ__QuoteLine__c> nonSolutionPackageItems = new List<SBQQ__QuoteLine__c>();
                for (SBQQ__QuoteLine__c lineItem : quoteGroup.SBQQ__LineItems__r) {
                    final Boolean display = lineItem.EffectiveLine__c
                            || CPQProductService.getInstance().isPremiumSupportOrSuccess(lineItem.SBQQ__ProductCode__c);
                    if (display) {
                        if (lineItem.SBQQ__RequiredBy__c != null && (
                                        lineItem.SBQQ__RequiredBy__r.SBQQ__ProductName__c == 'Wrike Solution Package' ||
                                        lineItem.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__ProductName__c ==
                                        'Wrike Solution Package')) {
                            quoteLineList.add(lineItem);
                        } else {
                            nonSolutionPackageItems.add(lineItem);
                        }
                    }
                }
                for (SBQQ__QuoteLine__c lineItem : nonSolutionPackageItems) {
                    if (lineItem.SBQQ__RequiredBy__c != null &&
                            (lineItem.SBQQ__RequiredBy__r.SBQQ__ProductName__c != 'Wrike Solution Package')) {
                        quoteLineList.add(lineItem);
                    }
                }
                for (SBQQ__QuoteLine__c lineItem : quoteGroup.SBQQ__LineItems__r) {
                    final Boolean display = lineItem.EffectiveLine__c
                            || CPQProductService.getInstance().isPremiumSupportOrSuccess(lineItem.SBQQ__ProductCode__c);
                    if (lineItem.SBQQ__RequiredBy__c == null && display) {
                        quoteLineList.add(lineItem);
                    }
                }
            }
        }
        return quoteLineList;
    }
}
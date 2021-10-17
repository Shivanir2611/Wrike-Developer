@isTest
public class QuoteLineItemsIntervalGroupV1ContrTest {

    public testMethod static void quoteTemplateTest(){
        Product2 prod = new Product2();
        prod.Name = 'Test Prod';
        prod.SBQQ__SubscriptionType__c = 'Renewable';
        prod.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prod.SBQQ__SubscriptionTerm__c = 1;
        prod.IsActive = true;
        insert prod;
        
        /*Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        update standardPricebook;*/
        
        Id  standardPricebook = Test.getStandardPricebookId();
        
        //standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        
        insert new PricebookEntry(pricebook2id = standardPricebook, product2id = prod.id,unitprice=100,isActive=true);
        
        PriceBookEntry priceEntry = [Select id from PriceBookEntry limit 1];
        
        Account acc = new Account();
        acc.Name='Test Account';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'Test Opp';
        opp.CloseDate=Date.today().addMonths(5);
        opp.StageName='0-MQL';
        opp.Pricebook2Id = standardPricebook;
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__PriceBook__c = standardPricebook;
        quote.SBQQ__PricebookId__c= standardPricebook;
        quote.SBQQ__StartDate__c = Date.today().addMonths(6);
        quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(1);
        quote.SBQQ__SubscriptionTerm__c = 12;
        quote.Display_Discount__c = true;
        insert quote;
        
        SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c ();
        quoteGroup.Name = 'Group 1';
        quoteGroup.SBQQ__Quote__c = quote.Id;
        Insert quoteGroup;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = prod.Id;
        quoteLine.SBQQ__Group__c = quoteGroup.Id;
        quoteLine.SBQQ__Quantity__c = 100;
        quoteLine.SBQQ__PricebookEntryId__c = priceEntry.Id;
        insert quoteLine;

        final PageReference page = Page.QuoteLineItemsIntervalGroupV1;
        page.getParameters().put('qid', quote.Id);
        Test.setCurrentPage(page);

        QuoteLineItemsIntervalGroupV1Controller quoteTemplate = new QuoteLineItemsIntervalGroupV1Controller();
        quoteTemplate.quoteId = quote.Id;
        quoteTemplate.getLines();
    }
    public testMethod static void quoteTemplateTestWithWrikeSolutionPackage(){
        Product2 prod = new Product2();
        prod.Name = 'Wrike Solution Package';
        prod.SBQQ__SubscriptionType__c = 'Renewable';
        prod.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prod.SBQQ__SubscriptionTerm__c = 1;
        prod.IsActive = true;
        insert prod;
        
        Product2 prod1 = new Product2();
        prod1.Name = 'Test Prod';
        prod1.SBQQ__SubscriptionType__c = 'Renewable';
        prod1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prod1.SBQQ__SubscriptionTerm__c = 1;
        prod1.IsActive = true;
        insert prod1;
        
        SBQQ__ProductOption__c po = new SBQQ__ProductOption__c();
        po.SBQQ__ConfiguredSKU__c = prod.Id;
        po.SBQQ__OptionalSKU__c = prod1.Id;
        po.SBQQ__Bundled__c = true;
        po.SBQQ__Number__c = 1;
        insert po;
        
        /*Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        update standardPricebook;*/
        
        Id  standardPricebook = Test.getStandardPricebookId();
        
        //standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        
        insert new PricebookEntry(pricebook2id = standardPricebook, product2id = prod.id,unitprice=100,isActive=true);
        
        PriceBookEntry priceEntry = [Select id from PriceBookEntry limit 1];
        
        Account acc = new Account();
        acc.Name='Test Account';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'Test Opp';
        opp.CloseDate=Date.today().addMonths(5);
        opp.StageName='0-MQL';
        opp.Pricebook2Id = standardPricebook;
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__PriceBook__c = standardPricebook;
        quote.SBQQ__PricebookId__c= standardPricebook;
        quote.SBQQ__StartDate__c = Date.today().addMonths(6);
        quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(1);
        quote.SBQQ__SubscriptionTerm__c = 12;
        quote.Display_Discount__c = true;
        insert quote;
        
        SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c ();
        quoteGroup.Name = 'Group 1';
        quoteGroup.SBQQ__Quote__c = quote.Id;
        Insert quoteGroup;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = prod.Id;
        quoteLine.SBQQ__Group__c = quoteGroup.Id;
        quoteLine.SBQQ__Quantity__c = 100;
        quoteLine.SBQQ__PricebookEntryId__c = priceEntry.Id;
        quoteLine.SBQQ__NetPrice__c = 1000;
        quoteLine.SBQQ__CustomerPrice__c = 1000;
        quoteLine.SBQQ__ProrateMultiplier__c = 12;
        quoteLine.SBQQ__DefaultSubscriptionTerm__c = 1;
        insert quoteLine;
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c();
        quoteLine1.SBQQ__Quote__c = quote.Id;
        quoteLine1.SBQQ__Product__c = prod1.Id;
        quoteLine1.SBQQ__Group__c = quoteGroup.Id;
        quoteLine1.SBQQ__Quantity__c = 100;
        quoteLine1.SBQQ__PricebookEntryId__c = priceEntry.Id;
        quoteLine1.SBQQ__NetPrice__c = 100;
        quoteLine1.SBQQ__CustomerPrice__c = 100;
        quoteLine1.SBQQ__RequiredBy__c = quoteLine.Id;
        quoteLine1.SBQQ__ProrateMultiplier__c = 12;
        quoteLine1.SBQQ__DefaultSubscriptionTerm__c = 1;
        insert quoteLine1;

        final PageReference page = Page.QuoteLineItemsIntervalGroupV1;
        page.getParameters().put('qid', quote.Id);
        Test.setCurrentPage(page);
        
        QuoteLineItemsIntervalGroupV1Controller quoteTemplate = new QuoteLineItemsIntervalGroupV1Controller();
        quoteTemplate.quoteId = quote.Id;
        quoteTemplate.getLines();
    }
    public testMethod static void quoteTemplateTestWithPremiumSupport(){
        Product2 prod = new Product2();
        prod.Name = 'Premium Support';
        prod.Family = 'Support';
        prod.SBQQ__SubscriptionPricing__c = 'Percent of Total';
        prod.SBQQ__SubscriptionType__c = '';
        prod.IsActive = true;
        insert prod;
        
        /*Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        update standardPricebook;*/
        
        Id  standardPricebook = Test.getStandardPricebookId();
        
        //standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        
        insert new PricebookEntry(pricebook2id = standardPricebook, product2id = prod.id,unitprice=100,isActive=true);
        
        PriceBookEntry priceEntry = [Select id from PriceBookEntry limit 1];
        
        Account acc = new Account();
        acc.Name='Test Account';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'Test Opp';
        opp.CloseDate=Date.today().addMonths(5);
        opp.StageName='0-MQL';
        opp.Pricebook2Id = standardPricebook;
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__PriceBook__c = standardPricebook;
        quote.SBQQ__PricebookId__c= standardPricebook;
        quote.SBQQ__StartDate__c = Date.today().addMonths(6);
        quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(1);
        quote.SBQQ__SubscriptionTerm__c = 12;
        quote.Display_Discount__c = true;
        insert quote;
        
        SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c ();
        quoteGroup.Name = 'Group 1';
        quoteGroup.SBQQ__Quote__c = quote.Id;
        Insert quoteGroup;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = prod.Id;
        quoteLine.SBQQ__Group__c = quoteGroup.Id;
        quoteLine.SBQQ__Quantity__c = 100;
        quoteLine.SBQQ__PricebookEntryId__c = priceEntry.Id;
        quoteLine.SBQQ__NetPrice__c = 1000;
        quoteLine.SBQQ__CustomerPrice__c = 1000;
        insert quoteLine;

        final PageReference page = Page.QuoteLineItemsIntervalGroupV1;
        page.getParameters().put('qid', quote.Id);
        Test.setCurrentPage(page);
        
        QuoteLineItemsIntervalGroupV1Controller quoteTemplate = new QuoteLineItemsIntervalGroupV1Controller();
        quoteTemplate.quoteId = quote.Id;
        quoteTemplate.getLines();
    }
    public testMethod static void quoteTemplateTestWithProfServices(){
        Product2 prod = new Product2();
        prod.Name = 'Professional Service';
        prod.Family = 'Professional Services';
        prod.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prod.IsActive = true;
        insert prod;
        
        /*Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        update standardPricebook;*/
        
        Id  standardPricebook = Test.getStandardPricebookId();
        
        //standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        
        insert new PricebookEntry(pricebook2id = standardPricebook, product2id = prod.id,unitprice=100,isActive=true);
        
        PriceBookEntry priceEntry = [Select id from PriceBookEntry limit 1];
        
        Account acc = new Account();
        acc.Name='Test Account';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'Test Opp';
        opp.CloseDate=Date.today().addMonths(5);
        opp.StageName='0-MQL';
        opp.Pricebook2Id = standardPricebook;
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__PriceBook__c = standardPricebook;
        quote.SBQQ__PricebookId__c= standardPricebook;
        quote.SBQQ__StartDate__c = Date.today().addMonths(6);
        quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(1);
        quote.SBQQ__SubscriptionTerm__c = 12;
        quote.Display_Discount__c = true;
        insert quote;
        
        SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c ();
        quoteGroup.Name = 'Group 1';
        quoteGroup.SBQQ__Quote__c = quote.Id;
        Insert quoteGroup;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = prod.Id;
        quoteLine.SBQQ__Group__c = quoteGroup.Id;
        quoteLine.SBQQ__Quantity__c = 100;
        quoteLine.SBQQ__PricebookEntryId__c = priceEntry.Id;
        quoteLine.SBQQ__NetPrice__c = 1000;
        quoteLine.SBQQ__CustomerPrice__c = 1000;
        insert quoteLine;

        final PageReference page = Page.QuoteLineItemsIntervalGroupV1;
        page.getParameters().put('qid', quote.Id);
        Test.setCurrentPage(page);

        QuoteLineItemsIntervalGroupV1Controller quoteTemplate = new QuoteLineItemsIntervalGroupV1Controller();
        quoteTemplate.quoteId = quote.Id;
        quoteTemplate.getLines();
    }
    public testMethod static void quoteTemplateTestWithOneTime(){
        Product2 prod = new Product2();
        prod.Name = 'Custom Product';
        prod.Family = 'Custom';
        prod.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prod.SBQQ__SubscriptionType__c = 'One-time';
        prod.IsActive = true;
        insert prod;
        
        /*Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        update standardPricebook;*/
        
        Id  standardPricebook = Test.getStandardPricebookId();
        
        //standardPricebook = [SELECT Id, IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        
        insert new PricebookEntry(pricebook2id = standardPricebook, product2id = prod.id,unitprice=100,isActive=true);
        
        PriceBookEntry priceEntry = [Select id from PriceBookEntry limit 1];
        
        Account acc = new Account();
        acc.Name='Test Account';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'Test Opp';
        opp.CloseDate=Date.today().addMonths(5);
        opp.StageName='0-MQL';
        opp.Pricebook2Id = standardPricebook;
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__PriceBook__c = standardPricebook;
        quote.SBQQ__PricebookId__c= standardPricebook;
        quote.SBQQ__StartDate__c = Date.today().addMonths(6);
        quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(1);
        quote.SBQQ__SubscriptionTerm__c = 12;
        quote.Display_Discount__c = true;
        insert quote;
        
        SBQQ__QuoteLineGroup__c quoteGroup = new SBQQ__QuoteLineGroup__c ();
        quoteGroup.Name = 'Group 1';
        quoteGroup.SBQQ__Quote__c = quote.Id;
        Insert quoteGroup;
        
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quote.Id;
        quoteLine.SBQQ__Product__c = prod.Id;
        quoteLine.SBQQ__Group__c = quoteGroup.Id;
        quoteLine.SBQQ__Quantity__c = 100;
        quoteLine.SBQQ__PricebookEntryId__c = priceEntry.Id;
        quoteLine.SBQQ__NetPrice__c = 1000;
        quoteLine.SBQQ__CustomerPrice__c = 1000;
        insert quoteLine;

        final PageReference page = Page.QuoteLineItemsIntervalGroupV1;
        page.getParameters().put('qid', quote.Id);
        Test.setCurrentPage(page);

        QuoteLineItemsIntervalGroupV1Controller quoteTemplate = new QuoteLineItemsIntervalGroupV1Controller();
        quoteTemplate.quoteId = quote.Id;
        quoteTemplate.getLines();
    }
}
@IsTest
public class CPQQuotePartnerSelectionControllerTest {

    @IsTest
    static void testSearchForPartnerAccounts() {
        final Account partnerAccount = new Account(
                Name = 'Test Partner Account',
                CurrencyIsoCode = 'USD',
                RecordTypeId = SchemaUtils.getRecordTypeIdByName(Account.getSObjectType(), 'Partner')
        );
        insert partnerAccount;
        final List<LookupInputSearchResultItem> resultItems =
                CPQQuotePartnerSelectionController.searchForPartnerAccounts('Partn');
        System.assertEquals(1, resultItems.size());
        System.assertEquals(partnerAccount.Name, resultItems.get(0).title);
    }

    @IsTest
    static void testUpdateQuotePartnerAccount() {
        final Account partnerAccount = new Account(
                Name = 'Test Partner Account',
                CurrencyIsoCode = 'USD',
                RecordTypeId = SchemaUtils.getRecordTypeIdByName(Account.getSObjectType(), 'Partner'),
                AgreementType__c = 'Reseller',
                GoverningTerms__c = 'aaa',
                GoverningTermsDate__c = Date.today().addDays(30),
                PaymentTerms__c = 'Net 45',
                OnetimeFeesCommission__c = 0,
                NewSubscriptionCommission__c = 5
        );
        insert partnerAccount;

        final QS_Bill_To_Ship_To__c billTo = new QS_Bill_To_Ship_To__c(
                QS_Account__c = partnerAccount.Id,
                QS_Email__c = 'test@email.com',
                QS_Bill_To__c = true
        );
        insert billTo;
        final QS_Bill_To_Ship_To__c shipTo = new QS_Bill_To_Ship_To__c(
                QS_Account__c = partnerAccount.Id,
                QS_Email__c = 'test1@email.com',
                QS_Ship_To__c = true
        );
        insert shipTo;

        final Account account = TestDataFactory.createAccount();
        insert account;
        final Opportunity opportunity = TestDataFactory.createOpportunity(account.Id, 123);
        insert opportunity;
        final Product2 product = new Product2(Name = 'Test Product');
        insert product;
        final SBQQ__Quote__c quote = new SBQQ__Quote__c(
                QuoteType__c = 'New Subscription',
                SBQQ__Account__c = account.Id,
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__LineItemsGrouped__c = true
        );
        insert quote;
        final SBQQ__QuoteLineGroup__c recurringGroup =  new SBQQ__QuoteLineGroup__c(
                Name = 'Test Group',
                SBQQ__StartDate__c = Date.newInstance(Date.today().year(), 1, 31),
                SBQQ__EndDate__c = Date.newInstance(Date.today().year() + 1, 1, 30),
                SBQQ__Quote__c = quote.Id,
                OneTime__c = false
        );
        insert recurringGroup;
        final SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                SBQQ__Group__c = recurringGroup.Id,
                SBQQ__SubscriptionType__c = 'Renewable',
                SBQQ__ProductSubscriptionType__c = 'Renewable',
                SBQQ__NetPrice__c = 500,
                SBQQ__Quantity__c = 5,
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = product.Id,
                NonRenewableDiscount__c = 2.5
        );
        insert quoteLine;
        final String message = CPQQuotePartnerSelectionController.updateQuotePartnerAccount(quote.Id, partnerAccount.Id);
        System.assertEquals(null, message);
        final SBQQ__Quote__c updatedQuote = [
                SELECT Id, ResellerAccount__c, SBQQ__PaymentTerms__c, Governing_Terms__c, Date_of_Agreement__c,
                       Automatic_Renewal__c, PartnerAgreementType__c, CustomGoverningTerms__c, SubscriptionCommission__c,
                       QS_Bill_To__r.QS_Email__c, QS_Bill_To__r.PartnerAccount__c, QS_Bill_To__r.QS_Account__c,
                       QS_Ship_To__r.QS_Email__c, QS_Ship_To__r.PartnerAccount__c, QS_Ship_To__r.QS_Account__c
                FROM SBQQ__Quote__c
                WHERE Id = :quote.Id
        ];
        System.assertEquals(partnerAccount.Id, updatedQuote.ResellerAccount__c);
        System.assertEquals('Net 45', updatedQuote.SBQQ__PaymentTerms__c);
        System.assertEquals('Partner Agreement', updatedQuote.Governing_Terms__c);
        System.assertEquals(Date.today().addDays(30), updatedQuote.Date_of_Agreement__c);
        System.assertEquals('No', updatedQuote.Automatic_Renewal__c);
        System.assertEquals('Reseller', updatedQuote.PartnerAgreementType__c);
        System.assertEquals('aaa', updatedQuote.CustomGoverningTerms__c);
        System.assertEquals(5, updatedQuote.SubscriptionCommission__c);
        System.assertEquals('test@email.com', updatedQuote.QS_Bill_To__r.QS_Email__c);
        System.assertEquals(account.Id, updatedQuote.QS_Bill_To__r.QS_Account__c);
        System.assertEquals(partnerAccount.Id, updatedQuote.QS_Bill_To__r.PartnerAccount__c);
        System.assertEquals('test1@email.com', updatedQuote.QS_Ship_To__r.QS_Email__c);
        System.assertEquals(account.Id, updatedQuote.QS_Ship_To__r.QS_Account__c);
        System.assertEquals(partnerAccount.Id, updatedQuote.QS_Ship_To__r.PartnerAccount__c);

        final SBQQ__QuoteLine__c updatedQuoteLine = [
            SELECT NonRenewableDiscount__c, SBQQ__PartnerDiscount__c
            FROM SBQQ__QuoteLine__c
            WHERE Id = :quoteLine.Id
        ];
        System.assertEquals(null, updatedQuoteLine.NonRenewableDiscount__c);
        System.assertEquals(5, updatedQuoteLine.SBQQ__PartnerDiscount__c);

        final List<Partner__c> opportunityPartners = [
                SELECT Id, Partner__c
                FROM Partner__c
                WHERE Opportunity__c = :opportunity.Id
        ];
        System.assertEquals(1, opportunityPartners.size());
        System.assertEquals(partnerAccount.Id, opportunityPartners.get(0).Partner__c);
    }
}
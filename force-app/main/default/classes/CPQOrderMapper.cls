public class CPQOrderMapper {

    public static List<Line_Item_Billing_Schedule__c> mapToLineItemBillingSchedules(final List<CPQLineItemBillingSchedule> cpqItems) {
        final List<Line_Item_Billing_Schedule__c> items = new List<Line_Item_Billing_Schedule__c>();
        for (CPQLineItemBillingSchedule cpqItem : cpqItems) {
            items.add(mapToLineItemBillingSchedule(cpqItem));
        }
        return items;
    }

    public static Line_Item_Billing_Schedule__c mapToLineItemBillingSchedule(final CPQLineItemBillingSchedule cpqItem) {
        final Line_Item_Billing_Schedule__c item = new Line_Item_Billing_Schedule__c();
        item.Id = cpqItem.id;
        item.Name = cpqItem.name;
        item.Internal_Invoice_Number__c = cpqItem.invoiceNumber;
        item.Service_Start_Date__c = cpqItem.serviceStartDate;
        item.Service_End_Date__c = cpqItem.serviceEndDate;
        item.Invoice_Date__c = cpqItem.invoiceDate;
        item.Invoice_Allocated_Amount__c = cpqItem.invoiceAllocatedAmount;
        item.Order_Effective_Price__c = cpqItem.effectivePrice;
        item.Quantity__c = cpqItem.quantity;
        item.Charge_Type__c = cpqItem.chargeType;
        item.Product_NetSuite_Internal_ID__c = cpqItem.netSuiteInternalId;
        item.Product__c = cpqItem.productId;
        item.Order__c = cpqItem.orderId;
        item.Order_Line_Id__c = cpqItem.orderItemId;
        item.CurrencyIsoCode = cpqItem.currencyCode;
        return item;
    }
}
public class DisplayBillingSchedulesController {
    public Id QuoteRecordId;
    public String INVOICENUMBER{get;set;}
    public String INVOICEDATE{get;set;}
    public String SERVICESTART{get;set;}
    public String SERVICEEND{get;set;}
    public String SUBSCRIPTIONAMOUNT{get;set;}
    public String ONETIMEFEES{get;set;}
    public String INVOICETOTAL{get;set;}
    public String PAYMENTSCHEDULES{get;set;}
    public String PAYMENTSCHEDULEDESC{get;set;}
    public BillingSchedulesInWrapper MainWrapper{get;set;}
    public Boolean ShowPaymentSchedules{get;set;}
    //conditional display of Subscription fees and One Time feess
    public boolean displaySubscriptionFees {get;set;}
    public boolean displayOneTimeFees {get;set;}
    
    public DisplayBillingSchedulesController(){
        QuoteRecordId = (Id)ApexPages.currentPage().getParameters().get(Constants.QID);
        MainWrapper = new BillingSchedulesInWrapper();
        INVOICENUMBER = Constants.INVOICENUMBER;
        INVOICEDATE = Constants.INVOICEDATE;
        SERVICESTART = Constants.SERVICESTART;
        SERVICEEND = Constants.SERVICEEND;
        SUBSCRIPTIONAMOUNT = Constants.SUBSCRIPTIONAMOUNT;
        ONETIMEFEES = Constants.ONETIMEFEES;
        INVOICETOTAL = Constants.INVOICETOTAL;
        PAYMENTSCHEDULES = Constants.PAYMENTSCHEDULES;
        PAYMENTSCHEDULEDESC = Constants.PAYMENTSCHEDULEDESC;
        ShowPaymentSchedules = false;
        displaySubscriptionFees = false;
        displayOneTimeFees = false;
    }
    
    class BillingSchedulesInWrapper {
        public FinalBillingSchedulesInWrapper BillScheduleList {get; set;}
        @TestVisible public BillingSchedulesInWrapper(){
            BillScheduleList = new FinalBillingSchedulesInWrapper();
        }
    }
    class FinalBillingSchedulesInWrapper {
        public List<Billing_Schedule__c> BillScheduleList {get; set;}
        @TestVisible public FinalBillingSchedulesInWrapper(){
            BillScheduleList = new List<Billing_Schedule__c>();
        }
    }
    
    public void GetInvoices(){
        List<Billing_Schedule__c> AddedBillingSchedulesInList = new List<Billing_Schedule__c>();
        for(Billing_Schedule__c EachBillSchedule : [SELECT Id, Name, Invoice_Number__c, Service_Start_Date__c, Service_End_Date__c, Invoice_Date__c, 
                                                    Subscription_Amount__c, One_Time_Fee_Amount__c, Invoice_Total__c, Quote__r.Show_Billing_Schedule_on_Quote__c, CurrencyIsoCode
                                                    FROM Billing_Schedule__c 
                                                    WHERE Quote__c =: QuoteRecordId
                                                    ORDER BY Invoice_Date__c ASC nulls last
                                                   ]) 
        {
            FinalBillingSchedulesInWrapper FbsInWrap = new FinalBillingSchedulesInWrapper();
            MainWrapper.BillScheduleList = FbsInWrap;
            if(EachBillSchedule.Quote__r.Show_Billing_Schedule_on_Quote__c){
                ShowPaymentSchedules = true;
            }
            AddedBillingSchedulesInList.add(EachBillSchedule);
            if(EachBillSchedule.Subscription_Amount__c != null && EachBillSchedule.Subscription_Amount__c != 0 && displaySubscriptionFees == false){
                displaySubscriptionFees = true;
            }
            if(EachBillSchedule.One_Time_Fee_Amount__c != null && EachBillSchedule.One_Time_Fee_Amount__c != 0 && displayOneTimeFees == false){
                displayOneTimeFees = true;
            }
        }
        if(!AddedBillingSchedulesInList.isEmpty() && AddedBillingSchedulesInList != null){
            MainWrapper.BillScheduleList.BillScheduleList = AddedBillingSchedulesInList;
        }
    }
}
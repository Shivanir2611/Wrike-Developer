public class CPQApproval {

    @AuraEnabled
    public Id id {get; set;}
    @AuraEnabled
    public String name {get; set;}
    @AuraEnabled
    public Id chainId {get; set;}
    @AuraEnabled
    public String chainName {get; set;}
    @AuraEnabled
    public Id ruleId {get; set;}
    @AuraEnabled
    public String ruleName {get; set;}
    @AuraEnabled
    public Decimal step {get; set;}
    @AuraEnabled
    public String status {get; set;}
    @AuraEnabled
    public String comments {get; set;}
    @AuraEnabled
    public Id approverUserId {get; set;}
    @AuraEnabled
    public Id approverGroupId {get; set;}
    @AuraEnabled
    public String approverGroupMemberNames {get; set;}
    @AuraEnabled
    public String approverName {get; set;}
    @AuraEnabled
    public Id assignedToId {get; set;}
    @AuraEnabled
    public String assignedToName {get; set;}
    @AuraEnabled
    public Id approvedById {get; set;}
    @AuraEnabled
    public String approvedByName {get; set;}
    @AuraEnabled
    public Id quoteId {get; set;}
}
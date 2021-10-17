trigger WrikeDeploymentTrigger on Deployment__c (after insert, after update) {
    final WrikeDeploymentTriggerHandler handler = WrikeDeploymentTriggerHandler.getInstance();
    
    if(Trigger.isAfter && Trigger.isInsert){
        handler.afterInsert(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        handler.afterUpdate(Trigger.oldMap,Trigger.newMap);   
    }
}
trigger LH_account_for_subscription on account(before update, before insert, after update, after insert) {
     if(trigger.isAfter && trigger.isUpdate){
        LH.LH_Realtime_Run.performFkTriggerLookups(trigger.oldMap, trigger.newMap, new Map<string, string>{
        'Foreign Key Object Name' => 'account',
        'Child Object Name' => 'subscription__c'
        });
     }
}
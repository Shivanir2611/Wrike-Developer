trigger LH_user_for_opportunity on user(before update, before insert, after update, after insert) {
     if(trigger.isAfter && trigger.isUpdate){
        LH.LH_Realtime_Run.performFkTriggerLookups(trigger.oldMap, trigger.newMap, new Map<string, string>{
        'Foreign Key Object Name' => 'user',
        'Child Object Name' => 'opportunity'
        });
     }
}
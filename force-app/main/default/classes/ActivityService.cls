public class ActivityService {

    public static ActivityService getInstance() {
        return (ActivityService)ServiceLocator.getInstance(ActivityService.class);
    }

    public Activity__c createActivity(final Task sourceTask, final String activityDataId) {
        if (sourceTask == null || activityDataId == null || sourceTask.Origin_Task_Id__c != null) {
            return null;
        }
        final Activity__c activity = new Activity__c();
        activity.Activity_Data__c = activityDataId;
        activity.ActivityDateTime__c = Datetime.now();
        activity.Direction__c = sourceTask.Direction__c;
        activity.Duration__c = sourceTask.Duration__c;
        activity.Subject__c = sourceTask.Subject;
        activity.Type__c = sourceTask.Type;
        activity.Task_Id__c = sourceTask.Id;
        if ((String.isBlank(sourceTask.Type) || sourceTask.Type == 'Call')
                && sourceTask.Duration__c != null) {
            activity.Sub_Type__c = sourceTask.Direction__c == 'Inbound' ? 'Inbound' : 'Outbound';
        } else if (sourceTask.Type == 'Email' && sourceTask.Subject != null) {
            final Boolean outbound = sourceTask.Subject.contains('[Email] [Out]');
            final Boolean inbound = sourceTask.Subject.contains('[Email] [In]');
            if (outbound || inbound) {
                activity.Sub_Type__c = outbound ? 'Outbound' : 'Inbound';
            }
        }
        return activity;
    }
}
public class GroupService {

    public static final String GENERAL_LEAD_QUEUE = 'General_Lead_Queue';
    public static final String SUPPORT_LEAD_QUEUE = 'Support_Lead_Queue';
    public static final String RECYCLED_LEAD_QUEUE = 'Recycled_Lead_Queue';

    private static final Set<String> queues = new Set<String>{
        GENERAL_LEAD_QUEUE,
        SUPPORT_LEAD_QUEUE,
        RECYCLED_LEAD_QUEUE
    };

    private static Map<String, String> queueNameToId = new Map<String, String>();

    private final GroupQueryService groupQuerySrv = GroupQueryService.getInstance();
    private final UserQueryService userQuerySrv = UserQueryService.getInstance();

    public static GroupService getInstance() {
        return (GroupService)ServiceLocator.getInstance(GroupService.class);
    }

    public String getQueueIdByDevNameOrNull(final String queueDevName) {
        final String queueId = queueNameToId.get(queueDevName);
        if (queueId == null && queues.contains(queueDevName)) {
            fillQueueNameToId();
            return queueNameToId.get(queueDevName);
        }
        List<Group> foundQueues = this.groupQuerySrv.findQueueByDevName(queueDevName);
        if (foundQueues.isEmpty()) {
            return null;
        }
        final Group theQueue = foundQueues.get(0);
        queueNameToId.put(theQueue.DeveloperName, theQueue.Id);
        return theQueue.Id;
    }

    public Boolean isRecycledLeadQueue(final String queueId) {
        return queueId == getQueueIdByDevNameOrNull(RECYCLED_LEAD_QUEUE);
    }

    public Set<Id> getUserGroupIds(final Id userId) {
        final List<GroupMember> groupMembers = groupQuerySrv.findGroupMembersByUserId(userId);
        final Set<Id> groupIds = new Set<Id>();
        for (GroupMember groupMember : groupMembers) {
            groupIds.add(groupMember.GroupId);
        }
        return groupIds;
    }

    public Map<Id, List<String>> getGroupMemberNames(final Set<Id> groupIds) {
        final List<GroupMember> groupMembers = groupQuerySrv.findGroupMembersByGroupIds(groupIds);
        final List<Id> userIds = new List<Id>();
        for (GroupMember groupMember : groupMembers) {
            userIds.add(groupMember.UserOrGroupId);
        }
        final Map<Id, User> userMap = new Map<Id, User>(userQuerySrv.listByIds(userIds));
        final Map<Id, List<String>> groupMemberNamesMap = new Map<Id, List<String>>();
        for (GroupMember groupMember : groupMembers) {
            final User user = userMap.get(groupMember.UserOrGroupId);
            if (user != null) {
                final String userName = userMap.get(groupMember.UserOrGroupId).Name;
                if (!groupMemberNamesMap.containsKey(groupMember.GroupId)) {
                    groupMemberNamesMap.put(groupMember.GroupId, new List<String>{userName});
                } else {
                    groupMemberNamesMap.get(groupMember.GroupId).add(userName);
                }
            }
        }
        return groupMemberNamesMap;
    }

    private void fillQueueNameToId() {
        List<Group> foundQueues = this.groupQuerySrv.findQueuesByDevNames(queues);
        for (Group theQueue : foundQueues) {
            queueNameToId.put(theQueue.DeveloperName, theQueue.Id);
        }
    }
}
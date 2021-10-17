public class GroupQueryService {

    public static GroupQueryService getInstance() {
        return (GroupQueryService)ServiceLocator.getInstance(GroupQueryService.class);
    }

    public List<Group> findQueueByDevName(final String devName) {
        return [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
                AND DeveloperName = :devName
        ];
    }

    public List<Group> findQueuesByDevNames(final Set<String> devNames) {
        return [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
                AND DeveloperName IN :devNames
        ];
    }

    public List<GroupMember> findGroupMembersByUserId(final Id userId) {
        return [
                SELECT Id, GroupId
                FROM GroupMember
                WHERE UserOrGroupId = :userId
        ];
    }

    public List<GroupMember> findGroupMembersByGroupIds(final Set<Id> groupIds) {
        return [
                SELECT Id, UserOrGroupId, GroupId
                FROM GroupMember
                WHERE GroupId IN :groupIds
        ];
    }
}
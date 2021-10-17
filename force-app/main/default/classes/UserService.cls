public class UserService {

    public static UserService getInstance() {
        return (UserService)ServiceLocator.getInstance(UserService.class);
    }

    private final UserQueryService userQuerySrv;
    private final UserRecordAccessService userRecordAccessSrv;

    public UserService() {
        this.userQuerySrv = UserQueryService.getInstance();
        this.userRecordAccessSrv = UserRecordAccessService.getInstance();
    }

    public User findUserById(String userId) {
        List<User> users = userQuerySrv.findById(userId);
        if (users.isEmpty()) {
            throw new LogicException('User with id = {0} not found.', userId);
        }
        return users[0];
    }

    public Boolean isUsUser(final Id userId) {
        return findUserById(userId)?.USGeo__c == true;
    }

    public List<User> filterUsersByRecordAccess(List<User> users, String recordId) {
        Integer numberOfQueriesLeft = Limits.getLimitQueries() - Limits.getQueries();
        if (users.size() > numberOfQueriesLeft) {
            return users;
        }

        List<User> usersWithAccess = new List<User>();
        for (User currentUser : users) {
            if (this.userRecordAccessSrv.hasEditAccess(currentUser.Id, recordId)) {
                usersWithAccess.add(currentUser);
            }
        }
        return usersWithAccess;
    }

    public List<User> findApproversWithRecordAccess(String approverLevel, String opportunityApproverType, String recordId) {
        List<User> approvers = this.userQuerySrv.findEqualsOrGreaterThenApproverLevel(approverLevel, opportunityApproverType);
        return filterUsersByRecordAccess(approvers, recordId);
    }
}
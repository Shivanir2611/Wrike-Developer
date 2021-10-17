public class UserRecordAccessService {

    private static final String NONE_LEVEL = 'None';
    private static final String READ_LEVEL = 'Read';
    private static final String EDIT_LEVEL = 'Edit';
    private static final String DELETE_LEVEL = 'Delete';
    private static final String TRANSFER_LEVEL = 'Transfer';
    private static final String All_LEVEL = 'All';

    public List<String> ACCESS_LEVELS = new List<String>{
        NONE_LEVEL, READ_LEVEL, EDIT_LEVEL, DELETE_LEVEL, TRANSFER_LEVEL, All_LEVEL
    };

    private final UserRecordAccessQueryService userRecordAccessQuerySrv;

    public static UserRecordAccessService getInstance() {
        return (UserRecordAccessService)ServiceLocator.getInstance(UserRecordAccessService.class);
    }

    public UserRecordAccessService() {
        this.userRecordAccessQuerySrv = UserRecordAccessQueryService.getInstance();
    }

    public String getMaxAccessLevel(String userId, String recordId) {
        List<UserRecordAccess> userRecordAccesses =
            this.userRecordAccessQuerySrv.findByUserIdAndRecordId(userId, recordId);
        if (userRecordAccesses.isEmpty()) {
            return NONE_LEVEL;
        }
        return userRecordAccesses[0].MaxAccessLevel;
    }

    public Boolean hasEditAndDeleteAccess(String userId, String recordId) {
        String maxAccessLevel = getMaxAccessLevel(userId, recordId);

        Integer userMAxAccessLevelIndex = 0;
        Integer deleteLevelIndex = 0;
        for (Integer i = 0; i < ACCESS_LEVELS.size(); i++) {
            String currentLevel = ACCESS_LEVELS[i];
            if (currentLevel == maxAccessLevel) {
                userMAxAccessLevelIndex = i;
            }
            if (currentLevel == DELETE_LEVEL) {
                deleteLevelIndex = i;
            }
        }
        return userMAxAccessLevelIndex >= deleteLevelIndex;

    }

    public Boolean hasEditAccess(final String userId, final String recordId) {
        List<UserRecordAccess> userRecordAccesses =
            this.userRecordAccessQuerySrv.findByUserIdAndRecordId(userId, recordId);
        if (userRecordAccesses.isEmpty()) {
            return false;
        }
        return userRecordAccesses[0].HasEditAccess;
    }

    public Boolean hasDeleteAccess(final String userId, final String recordId) {
        List<UserRecordAccess> userRecordAccesses =
            this.userRecordAccessQuerySrv.findByUserIdAndRecordId(userId, recordId);
        if (userRecordAccesses.isEmpty()) {
            return false;
        }
        return userRecordAccesses[0].HasDeleteAccess;
    }
}
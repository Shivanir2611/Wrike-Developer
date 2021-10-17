public without sharing class UserRecordAccessQueryService {

    public static UserRecordAccessQueryService getInstance() {
        return (UserRecordAccessQueryService)ServiceLocator.getInstance(UserRecordAccessQueryService.class);
    }

    public List<UserRecordAccess> findByUserIdAndRecordId(String userId, String recordId) {
        return [
            SELECT RecordId, MaxAccessLevel, HasEditAccess, HasDeleteAccess
            FROM UserRecordAccess
            WHERE UserId = :userId
                AND RecordId = :recordId
        ];
    }
}
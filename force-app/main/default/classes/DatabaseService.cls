public virtual class DatabaseService {

    public static DatabaseService getInstance() {
        return (DatabaseService)ServiceLocator.getInstance(DatabaseService.class);
    }

    private static final Logger log = Logger.create(DatabaseService.class);
    private static final Result SuccessResult = new Result(true, null);
    private static final Result DmlNotAllowedResult = new Result(false, 'DML not allowed.');

    private static final Integer MAX_NUMBER_RECORDS = 10000;
    private static final String MAX_NUMBER_RECORDS_EXEPTION = 'You can pass a maximum of 10,000 sObject records to a single DML operation.';
    private static final String INSERT_ERROR_LOG_KEY = 'Insert Error';
    private static final String UPDATE_ERROR_LOG_KEY = 'Update Error';
    private static final String UPSERT_ERROR_LOG_KEY = 'Upsert Error';
    private static final String DELETE_ERROR_LOG_KEY = 'Delete Error';

    private final List<sObject> sObjectsForDml = new List<sObject>();

    public void addSobject(final sObject sObj) {
        this.sObjectsForDml.add(sObj);
    }

    public Boolean insertSObject(final SObject obj) {
        return insertAndGetResult(obj, true).isSuccess();
    }

    public Boolean insertSObject(List<SObject> objs) {
        return insertAndGetResult(objs, true).isSuccess();
    }

    public Result insertAndGetResult(final SObject obj, final Boolean isPartialDmlAllowed) {
        return insertAndGetResult(new List<SObject> { obj }, isPartialDmlAllowed);
    }

    public Result insertAndGetResult(final List<SObject> objs, final Boolean isPartialDmlAllowed) {
        if (objs.isEmpty()) {
            return SuccessResult;
        }
        if (isDmlNotAllowed(objs.size())) {
            return DmlNotAllowedResult;
        }
        return new Result(convert(Database.insert(objs, !isPartialDmlAllowed)));
    }

    public Boolean updateSObject(SObject obj) {
        return updateAndGetResult(obj, true).isSuccess();
    }

    public Boolean updateSObject(List<SObject> objs) {
        return updateAndGetResult(objs, true).isSuccess();
    }

    public Boolean updateSObject(List<SObject> objs, Boolean skipFailedRecords) {
        return updateAndGetResult(objs, skipFailedRecords).isSuccess();
    }

    public Boolean updateSObject() {
        final Boolean result = updateAndGetResult(this.sObjectsForDml, true).isSuccess();
        if (result) {
            this.sObjectsForDml.clear();
        }
        return result;
    }

    public Result updateAndGetResult(final SObject obj, final Boolean isPartialDmlAllowed) {
        return updateAndGetResult(new List<sObject>{obj}, isPartialDmlAllowed);
    }

    public Result updateAndGetResult(final List<SObject> objs, final Boolean isPartialDmlAllowed) {
        if (objs.isEmpty()) {
            return SuccessResult;
        }
        if (isDmlNotAllowed(objs.size())) {
            return DmlNotAllowedResult;
        }
        return new Result(convert(Database.update(objs, !isPartialDmlAllowed)));
    }

    public Boolean upsertSObject(SObject obj) {
        return upsertAndGetResult(obj, true).isSuccess();
    }

    public Boolean upsertSObject(List<SObject> objs) {
        return upsertAndGetResult(objs, true).isSuccess();
    }

    public Result upsertAndGetResult(SObject obj, final Boolean isPartialDmlAllowed) {
        if (isDmlNotAllowed(1)) {
            return DmlNotAllowedResult;
        }
        return new Result(new List<DatabaseResult>{new DatabaseResult(Database.upsert(obj, !isPartialDmlAllowed))});
    }

    public Result upsertAndGetResult(List<SObject> objs, final Boolean isPartialDmlAllowed) {
        if (objs.isEmpty()) {
            return SuccessResult;
        }
        if (isDmlNotAllowed(objs.size())) {
            return DmlNotAllowedResult;
        }
        return new Result(convert(Database.upsert(objs, !isPartialDmlAllowed)));
    }

    public Boolean deleteSObject(String sObjectId) {
        return deleteSObject(sObjectId, true).isSuccess();
    }

    public Boolean deleteSObject(List<String> sObjectIds) {
        return deleteSObject(sObjectIds, true).isSuccess();
    }

    public Result deleteSObject(final String sObjectId, final Boolean isPartialDmlAllowed) {
        return deleteSObject(new List<String>{sObjectId}, isPartialDmlAllowed);
    }

    public Result deleteSObject(final List<String> sObjectIds, final Boolean isPartialDmlAllowed) {
        if (sObjectIds.isEmpty()) {
            return SuccessResult;
        }
        if (isDmlNotAllowed(sObjectIds.size())) {
            return DmlNotAllowedResult;
        }
        return new Result(convert(Database.delete(sObjectIds, !isPartialDmlAllowed)));
    }

    public virtual Savepoint setSavePoint() {
        return Database.setSavepoint();
    }

    public virtual void rollbackTo(final Savepoint databaseSavePoint) {
        Database.rollback(databaseSavePoint);
    }

    private Boolean isDmlNotAllowed(Integer recordsNumber) {
        return (Limits.getDMLRows() + recordsNumber) > Limits.getLimitDMLRows();
    }

    private Boolean isDmlNotAllowed() {
        return isDmlNotAllowed(1);
    }

    private List<DatabaseResult> convert(final List<Database.SaveResult> saveResults) {
        final List<DatabaseService.DatabaseResult> dbResults = new List<DatabaseResult>();
        for (Database.SaveResult saveResult : saveResults) {
            dbResults.add(new DatabaseResult(saveResult));
        }
        return dbResults;
    }

    private List<DatabaseResult> convert(final List<Database.UpsertResult> upsertResults) {
        final List<DatabaseService.DatabaseResult> dbResults = new List<DatabaseResult>();
        for (Database.UpsertResult upsertResult : upsertResults) {
            dbResults.add(new DatabaseResult(upsertResult));
        }
        return dbResults;
    }

    private List<DatabaseResult> convert(final List<Database.DeleteResult> deleteResults) {
        final List<DatabaseService.DatabaseResult> dbResults = new List<DatabaseResult>();
        for (Database.DeleteResult deleteResult : deleteResults) {
            dbResults.add(new DatabaseResult(deleteResult));
        }
        return dbResults;
    }

    public class Result {
        private final Boolean success;
        private final String errorMessage;
        
        private Result(final Boolean success, final String errorMessage) {
            this.success = success;
            this.errorMessage = errorMessage;
        }
        
        private Result(final List<DatabaseResult> dbResults) {
            final DatabaseResult failedResult = findFailedResult(dbResults);
            final Database.Error error = failedResult == null ? null : failedResult.getErrors()[0];
            this.success = (failedResult == null);
            this.errorMessage = error != null ? error.getMessage() + ' Fields: ' + error.getFields() : null;
        }
        
        private DatabaseResult findFailedResult(final List<DatabaseResult> dbResults) {
            for(DatabaseResult dbResult : dbResults) {
                if(!dbResult.getIsSuccess()) {
                    return dbResult;
                }
            }
            return null;
        }
        
        private Result(final Exception e) {
            this.success = false;
            this.errorMessage = e.getMessage();
        }
        
        public Boolean isSuccess() {
            return this.success == true;
        }
        
        public String getErrorMessage() {
            return this.errorMessage;
        }
    }

    public class DatabaseResult {

        private Boolean isSuccess;
        public List<Database.Error> errors;

        public DatabaseResult(final Database.SaveResult saveResult) {
            this.isSuccess = saveResult.isSuccess();
            this.errors = saveResult.getErrors();
        }

        public DatabaseResult(final Database.UpsertResult upsertResult) {
            this.isSuccess = upsertResult.isSuccess();
            this.errors = upsertResult.getErrors();
        }

        public DatabaseResult(final Database.DeleteResult deleteResult) {
            this.isSuccess = deleteResult.isSuccess();
            this.errors = deleteResult.getErrors();
        }

        public Boolean getIsSuccess() {
            return isSuccess;
        }

        public List<Database.Error> getErrors() {
            return errors;
        }
    }
}
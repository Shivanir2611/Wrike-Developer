public class DatabaseServiceMock extends DatabaseService{

    public override Savepoint setSavePoint() {
        return null;
    }

    public override void rollbackTo(Savepoint databaseSavePoint) {}
}
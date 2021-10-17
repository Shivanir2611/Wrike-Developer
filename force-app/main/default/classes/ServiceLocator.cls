public class ServiceLocator {

    private static final Map<Type, Type> testTypesMap = new Map<Type, Type> {
        ZuoraApi.class => ZuoraApiMock.class,
        DatabaseService.class => DatabaseServiceMock.class
    };

    private static Map<String, Object> typeNameToInstance = new Map<String, Object>();

    public static Type resolve(Type t) {
        if (Test.isRunningTest()) {
            if (testTypesMap.containsKey(t)) {
                return testTypesMap.get(t);
            }
        }
        return t;
    }

    public static Object getInstance(Type t) {
        if (typeNameToInstance.containsKey(t.getName())) {
            return typeNameToInstance.get(t.getName());
        }
        Type theType = resolve(t);
        Object requiredInstance = theType.newInstance();
        typeNameToInstance.put(t.getName(), requiredInstance);
        return requiredInstance;
    }

    public static void removeInstance(Type originalType) {
        typeNameToInstance.remove(originalType.getName());
    }

    public static void setInstance(Type originalType, Object instance) {
        typeNameToInstance.put(originalType.getName(), instance);
    }

    public static void setMock(Type originalType, Type mockType) {
        testTypesMap.put(originalType, mockType);
        typeNameToInstance.clear();
    }

    public static void removeMock(Type originalType) {
        testTypesMap.remove(originalType);
        typeNameToInstance.clear();
    }
}
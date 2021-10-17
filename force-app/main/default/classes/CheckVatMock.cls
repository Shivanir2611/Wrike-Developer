public class CheckVatMock implements WebServiceMock {

    public void doInvoke(Object stub, Object soapRequest, Map<String, Object> responseMap, String endpoint,
                         String soapAction, String requestName, String responseNamespace, String responseName,
                         String responseType) {

        CheckVatTypes.checkVat_element request = (CheckVatTypes.checkVat_element)soapRequest;

        CheckVatTypes.checkVatResponse_element responseElement = new CheckVatTypes.checkVatResponse_element();
        if (request.vatNumber == 'exception') {
            throw new MockException();
        }
        responseElement.valid = request.vatNumber.startsWith(request.countryCode);
        responseMap.put('response_x', responseElement);
    }

    public class MockException extends Exception {}
}
/*
 * Copyright 2023 FinancialForce.com
 */

 /**
 * Retrieve information about an SObjectType. Accepts the API name as the command parameter.
 */
public with sharing class GetObjectInfoCommand implements Callable {
    private static final String GET_OBJECT_INFO_ENDPOINT = '/services/data/v51.0/ui-api/object-info/';
    private static final String RESULT_KEY_OBJECT_INFO = 'metadata';
    private static final String ERROR_CODE_NO_RESULT = 'ffdc_not_found';

    public Object call(String action, Map<String, Object> args) {
        return getObjectInfo(action);
    }

    private Map<String, Object> getObjectInfo(String apiName) {
        if (!Pattern.matches('^[a-zA-Z0-9_]+$', apiName)) {
            System.debug(LoggingLevel.Error, 'Invalid name ' + apiName);
            throw AuthDemoApplicationException.builder(ERROR_CODE_NO_RESULT, Label.ObjectInfoNotFound)
                .withFormatArg(apiName)
                .build();
        }

        String token = AuthDemoApplication.getApiAccessToken();

        Object salesforceData = getSalesforceMetadata(apiName, token);
        if (salesforceData != null) {
            return new Map<String, Object>{ RESULT_KEY_OBJECT_INFO => salesforceData };
        } else {
            throw AuthDemoApplicationException.builder(ERROR_CODE_NO_RESULT, Label.ObjectInfoNotFound)
                .withFormatArg(apiName)
                .build();
        }
    }

    private Object getSalesforceMetadata(String apiName, String token) {
        HttpRequest httpRequest = createSalesforceApiGetRequest(token, GET_OBJECT_INFO_ENDPOINT + apiName);

        Http http = new Http();
        HttpResponse response = http.send(httpRequest);
        Integer status = response.getStatusCode();
        if (status == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return String.isNotBlank((string) result.get('apiName')) ? result : null;
        } else if (status / 100 == 4) {
            // Salesforce gives 403 for non-existent. I'd expect 404.
            // Maybe we can infer from the body.
            return null;
        }
        throw AuthDemoApplicationException.builder(AuthDemoApplicationException.ERROR_INTERNAL_EXCEPTION, response.getStatus()).build();
    }

    private static HttpRequest createSalesforceApiGetRequest(String token, String path) {
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();
        String restAPIURL = sfdcURL + path;

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(restAPIURL);
        httpRequest.setMethod('GET');
        httpRequest.setHeader('Authorization', 'Bearer ' + token); //NOPMD - This is not possible using Named Credentials as things stand.
        return httpRequest;
    }
}

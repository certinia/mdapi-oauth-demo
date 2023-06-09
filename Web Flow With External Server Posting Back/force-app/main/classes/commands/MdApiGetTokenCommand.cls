/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Attempt to get a Connected App Access Token using Web Flow.
 * If the system already has an Access Token then it will be returned.
 * If the system allows Refresh Tokens and has a valid Refresh Token then it is used.
 * Failing this an exception is thrown requesting redirect to the web flow.
 *
 * Argument: Map containing
 *
 *  Optional
 *    scopes: List<String> - Required scopes as defined by Salesforce OAuth, for example 'api','wave'.
 *    returnScopes: Boolean - if true then the result is a Map<String,Object> containing
 *           accessToken and scopes. Otherwise the response is a String containing the access token.
 */
public inherited sharing class MdApiGetTokenCommand implements Callable {
    private static final String TOKEN_REFRESH_ENDPOINT_PATH = 'services/oauth2/token';
    private static final String IDENTITY_SERVICE_ENDPOINT_PATH = 'id/';
    private static final String RESULT_KEY_TOKEN = 'accessToken';
    private static final String RESULT_KEY_SCOPES = 'scopes';

    private static final String SERVER_PATH_CALLBACK = '/callback';
    private static final String SERVER_PATH_START = '/start';
    private static final String SERVER_PATH_REFRESH = '/refresh';

    private Boolean allowRefreshTokens;
    private Url publicServerRoot;
    private String[] scopes;

    public Object call(String verb, Map<String, Object> arg) {
        Map<String, Object> arguments = (Map<String, Object>) arg;
        Boolean returnScopesParam = (Boolean) arguments.get('returnScopes');
        Boolean returnScopes = returnScopesParam != null ? returnScopesParam : false;

        initialise();

        Map<String, Object> result = getAccessToken();

        List<String> requiredScopes = (List<String>) arguments.get('scopes');
        if(requiredScopes != null) {
            validateScope((List<String>)result.get('scopes'), requiredScopes);
        }

        if (returnScopes) {
            return result;
        }
        return result.get('accessToken');
    }

    /**
     * Read settings into member variables.
     */
    private void initialise() {
        MDAPIClientSettings__c settings = MdApiSettingsSelector.getSettings();
        allowRefreshTokens = settings.AllowRefreshTokens__c;

        WebFlowClient__mdt metadata = getMetadata();
        publicServerRoot = new URL(metadata.PublicServerRoot__c);
        scopes = metadata.Scopes__c.split('\\s+');
        if(allowRefreshTokens) {
            scopes.add('refresh_token');
        }
    }

    /**
     * Attempt to get an access token. If unable to then throw an exception detailing the error
     * or requesting appropriate action.
     */
    public Map<String,Object> getAccessToken() {
        WebFlowClient__mdt metadata = getMetadata();

        TokenStoreService.Dto token = TokenStoreService.getToken();
        if (token?.accessToken != null && validateAccessToken(token.accessToken)) {
             return makeTokenResult(token.accessToken, null);
        }

        if (token?.refreshToken != null && allowRefreshTokens) {
            Map<String, Object> result = refreshToken(token.refreshToken);
            if(result != null) {
                return result;
            }
        }

        throw makeWebFlowRequestException();
    }

    /**
     * Check that a given Access Token is still usable.
     * Ideally a production system should not need this. It should instead detect invalid token in its
     * business logic and use the refresh token or client flow as needed.
     * This does increase the complexity of the business logic, which must now be coded to check for
     * authentication errors and allow the retry. Including it here allows existing business logic to continue
     * without these changes.
     */
    public boolean validateAccessToken(String accessToken) {
        // This needs a remote site setting to the login service, but seems an ideal endpoint for testing.
        // If we choose not to use Refresh Tokens we could find a harmless Metadata Read to do - like my own name perhaps.
        // See "Identity URLs" documentation at https://help.salesforce.com/s/articleView?id=sf.remoteaccess_using_openid.htm&type=5
        String identityUrl =
            URL.getOrgDomainUrl().toExternalForm() + '/' + IDENTITY_SERVICE_ENDPOINT_PATH +
            UserInfo.getOrganizationId() +
            '/' +
            UserInfo.getUserId();
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(identityUrl);
        httpRequest.setMethod('GET');
        httpRequest.setHeader('Authorization', 'Bearer ' + accessToken); //NOPMD - We can't ship a Named Credential for loopback

        Http http = new Http();
        HttpResponse response = http.send(httpRequest);
        Integer status = response.getStatusCode();
        // There is no scope information here, so I can't validate the scope of my token using this call.
        return status == 200;
    }

    /**
     * Trigger a refresh.
     * The result is passed back using a PUT, so will not be available in this execution context.
     * Throw an exception to request that the client retry.
     */
    private  Map<String, Object> refreshToken(String refreshToken) {
        String target = 'callout:WebFlowDemo' + SERVER_PATH_REFRESH;
        String body = JSON.serialize(new Map<String, String>{
            'state' => getStateParameter(),
            'token' => refreshToken
        });

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(target);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setBody(body);

        Http http = new Http();
        HttpResponse response = http.send(httpRequest);
        Integer status = response.getStatusCode();
        if (status == 200) {
            Map<String, Object> result = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            if(result.get('status') == true) {
                // Ask the client to retry the request (without web flow) to pick up the new token.
                throw AuthDemoApplicationException.builder(AuthDemoApplicationException.MDAPI_CLIENT_PLEASE_RETRY,
                        'Please retry to refresh connection').build();
            }
        } 
        System.debug(LoggingLevel.ERROR, response.getStatus());
        System.debug(LoggingLevel.ERROR, response.getBody());
        // Fall back to triggering a web flow
        return null;
    }

    private Map<String,Object> makeTokenResult(String token, List<String> scopes) {
        return new Map<String, Object>{ RESULT_KEY_TOKEN => token, RESULT_KEY_SCOPES => scopes };
    }

    /**
     * Create an exception to tell the client to perform a web flow request.
     */
    private Exception makeWebFlowRequestException() {
        String startUrl = getServerUrl(SERVER_PATH_START, new Map<String, String>{
            'scope' => String.join(scopes, ' '),
            'state' => getStateParameter()
        });

        String expectedCallbackUrl = getServerUrl(SERVER_PATH_CALLBACK, null);

        return AuthDemoApplicationException.builder(
            AuthDemoApplicationException.MDAPI_CLIENT_PLEASE_RETRY,
            'Web Flow login is needed'
        ).withOAuthWebFlow(startUrl, expectedCallbackUrl)
        .build();
    }

    /**
     * Return the state parameter for calls to the server.
     */
    private String getStateParameter() {
        return JSON.serialize(
            new Map<String, Object>{
                // The mandatory type tells the server whether this is a production or sandbox org.
                'type' => AuthDemoApplication.runningInASandbox ? 'test' : 'prod',
                // The optional app parameter helps in development when testing with multiple namespaces.
                // A production webflow server must whitelist or hardcode this parameter.
                // Ideally if this parameter is allowed to vary then further validation will be used.
                'app' => AuthDemoApplication.namespace
            }
        );
    }

    /**
     * Validate the returned scope parameter against the required scopes.
     */
    private void validateScope(List<String> foundScopes, List<String> requiredScopes) {
        if (requiredScopes == null || foundScopes == null) {
            return;
        }

        Set<string> missing = new Set<String>();
        for (String scope : requiredScopes) {
            missing.add(scope.toLowerCase());
        }
        missing.removeAll(foundScopes);

        if (missing.size() == 1) {
            throw AuthDemoApplicationException.builder(
                    AuthDemoApplicationException.MDAPI_CLIENT_ERROR_MISSING_SCOPES,
                    Label.MdApiClientMissingScope
                )
                .withFormatArg(missing.iterator().next())
                .build();
        }
        if (missing.size() > 1) {
            throw AuthDemoApplicationException.builder(
                    AuthDemoApplicationException.MDAPI_CLIENT_ERROR_MISSING_SCOPES,
                    Label.MdApiClientMissingScopes
                )
                .withFormatArg(String.join(new List<String>(missing), ','))
                .build();
        }
    }

    /**
     * Get the URL for a given endpoint on the public server.
     */
    private String getServerUrl(String path, Map<String, String> queryParameters) {
        PageReference pr = new PageReference(path); //NOPMD
        if(queryParameters != null) {
            for (String key : queryParameters.keySet()) {
                pr.getParameters().put(key, queryParameters.get(key));
            }
        }
        return new URL(publicServerRoot, pr.getUrl()).toExternalForm();
    }


    /**
     * Read information about the connected app from the protected custom metadata.
     */
    private WebFlowClient__mdt getMetadata() {
        final String name = 'API';
        WebFlowClient__mdt[] clientInfos = [SELECT DeveloperName, Scopes__c, PublicServerRoot__c FROM WebFlowClient__mdt WHERE DeveloperName = :name]; //NOPMD
        if(clientInfos.size() != 1) {
            throw AuthDemoApplicationException.builder(AuthDemoApplicationException.MDAPI_CLIENT_ERROR_CODE_MISCONFIGURED, Label.MdApiClientMissingMetadata)
            .withFormatArg(name)
            .build();
        } 
        return clientInfos[0];
    }
}

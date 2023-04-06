/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Attempt to get a Connected App Access Token.
 * This command selects one of two strategies depending on configuration.
 * It will attempt to use an admin provided connected app for JWT Bearer Token if a certificate and clientId are available.
 * It will attempt to use web flow if a client ID and redirect URL are available.
 *
 * Argument: Map containing
 *  To test a connection from the UI
 *    clientId: String - client consumer key
 *    certificateName: String - certificate name to use.
 *
 *  Optional
 *    scopes: List<String> - Required scopes as defined by Salesforce OAuth, for example 'api','wave'.
 *    returnScopes: Boolean - if true then the result is a Map<String,Object> containing
 *           accessToken and scopes. Otherwise the response is a String containing the access token.
 * 
 * Testing Admin Provided JWT Apps
 *     This class can redirect to the JWTAdminProvidedAppTokenStrategy to test a connection.
 *     This allows the validate scopes method in this class to be included in that test.
 *     Provide the clientId and certificateName arguments in the argument map.
 */
public inherited sharing class MdApiGetTokenCommand implements Callable {
    private static final String TOKEN_REFRESH_ENDPOINT_PATH = 'services/oauth2/token';
    private static final String IDENTITY_SERVICE_ENDPOINT_PATH = 'id/';
    private static final String RESULT_KEY_TOKEN = 'accessToken';
    private static final String RESULT_KEY_SCOPES = 'scopes';

    private Boolean allowRefreshTokens;

    public Object call(String verb, Map<String, Object> arg) {
        Map<String, Object> arguments = (Map<String, Object>) arg;
        Boolean returnScopesParam = (Boolean) arguments.get('returnScopes');
        Boolean returnScopes = returnScopesParam != null ? returnScopesParam : false;

        initialise();

        Map<String, Object> result = getAccessToken(arguments);

        List<String> requiredScopes = (List<String>) arguments.get('scopes');
        if(requiredScopes != null) {
            validateScope((List<String>)result.get('scopes'), requiredScopes);
        }

        if (returnScopes) {
            return result;
        }
        return result.get('accessToken');
    }

    private void initialise() {
        MDAPIClientSettings__c settings = MdApiSettingsSelector.getSettings();
        allowRefreshTokens = settings.AllowRefreshTokens__c;
    }

    public Map<String,Object> getAccessToken(Map<String,Object> args) {
        WebFlowClient__mdt metadata = getMetadata();

        TokenStoreService.Dto token = TokenStoreService.getToken();
        if (token?.accessToken != null && validateAccessToken(token.accessToken)) {
             return makeTokenResult(token.accessToken, null);
        }

        if (token?.refreshToken != null && allowRefreshTokens) {
            Map<String, Object> result = refreshToken(token.refreshToken, metadata);
            if(result != null) {
                return result;
            }
        }

        throw makeWebFlowRequestException(metadata);
    }

    private WebFlowClient__mdt getMetadata() {
        final String name = 'API';
        WebFlowClient__mdt[] clientInfos = [SELECT DeveloperName, Scopes__c, Callback__c, ClientId__c, ClientSecret__c FROM WebFlowClient__mdt WHERE DeveloperName = :name]; //NOPMD
        if(clientInfos.size() != 1) {
            throw AuthDemoApplicationException.builder(AuthDemoApplicationException.MDAPI_CLIENT_ERROR_CODE_MISCONFIGURED, Label.MdApiClientMissingMetadata)
            .withFormatArg(name)
            .build();
        } 
        return clientInfos[0];
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

    private  Map<String, Object> refreshToken(String refreshToken, WebFlowClient__mdt metadata) {
        String tokenUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + TOKEN_REFRESH_ENDPOINT_PATH;

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(tokenUrl);
        httpRequest.setMethod('POST');
        httpRequest.setBody(
            'grant_type=refresh_token' +
                '&client_id=' +
                EncodingUtil.urlEncode(metadata.ClientId__c, 'UTF-8') +
                '&client_secret=' +
                EncodingUtil.urlEncode(metadata.ClientSecret__c, 'UTF-8') +
                '&refresh_token=' +
                EncodingUtil.urlEncode(refreshToken, 'UTF-8')
        );

        Http http = new Http();
        HttpResponse response = http.send(httpRequest);
        Integer status = response.getStatusCode();
        if (status == 200) {
            Map<String, Object> grant = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // Salesforce will not provide a new refresh token, expecting the old one to be reused until expiry.
            // See https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_refresh_token_flow.htm&type=5
            String scope = (String) grant.get('scope');
            return makeTokenResult((String) grant.get('access_token'), scope.split('\\s'));
        } else {
            System.debug(LoggingLevel.ERROR, response.getStatus());
            System.debug(LoggingLevel.ERROR, response.getBody());
            return null;
        }
    }

    private Map<String,Object> makeTokenResult(String token, List<String> scopes) {
        return new Map<String, Object>{ RESULT_KEY_TOKEN => token, RESULT_KEY_SCOPES => scopes };
    }

    private Exception makeWebFlowRequestException(WebFlowClient__mdt metadata) {
        String initUrl = getInitUrl(metadata);
        return AuthDemoApplicationException.builder(
            AuthDemoApplicationException.MDAPI_CLIENT_PLEASE_RETRY,
            'Web Flow login is needed'
        ).withOAuthWebFlow(initUrl, metadata.Callback__c)
        .build();
    }

    private String getInitUrl(WebFlowClient__mdt metadata) {
        PageReference pr = new PageReference('/services/oauth2/authorize');
        pr.getParameters().put('client_id', metadata.ClientId__c);
        pr.getParameters().put('redirect_uri', metadata.Callback__c);
        pr.getParameters().put('response_type', 'code');
        List<String> scopes = metadata.Scopes__c.split('\\s+');
        if(allowRefreshTokens) scopes.add('refresh_token');
        pr.getParameters().put('scope', String.join(scopes, ' '));
        pr.getParameters()
            .put(
                'state',
                JSON.serialize(
                    new Map<String, Object>{
                        // The mandatory type tells the server whether this is a production or sandbox org.
                        'type' => AuthDemoApplication.runningInASandbox ? 'test' : 'prod',
                        // The optional app parameter helps in development when testing with multiple namespaces.
                        // A production webflow server must whitelist or hardcode this parameter.
                        // Ideally if this parameter is allowed to vary then further validation will be used.
                        'app' => AuthDemoApplication.namespace,
                        // Name was to allow multiple connected apps with different scopes. A lot would need to be
                        // done to make this possible.
                        'name' => metadata.DeveloperName
                    }
                )
            );
        return URL.getOrgDomainUrl().toExternalForm() + pr.getURL();
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
}

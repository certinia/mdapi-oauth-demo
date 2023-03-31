/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Attempt to get a Connected App Access Token.
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
 */
public inherited sharing class MdApiGetTokenCommand implements Callable {
    private static final String IDENTIFICATION_ENDPOINT_PATH = 'services/oauth2/token';

    private List<String> requiredScopes;
    private String clientId;
    private String keyName;
    private Boolean returnScopes = false;

    public Object call(String verb, Map<String, Object> arguments) {
        readArgs(arguments);
        HttpResponse response = performFlow();
        Map<String, Object> result = readResponse(response);
        if (returnScopes) {
            return result;
        }
        return result.get('accessToken');
    }

    /**
     * Read the command arguments and set member variables.
     */
    private void readArgs(Map<String, Object> argMap) {
        this.requiredScopes = (List<String>) argMap.get('scopes');

        Boolean returnScopesParam = (Boolean) argMap.get('returnScopes');
        if (returnScopesParam != null) {
            this.returnScopes = returnScopesParam;
        }

        if(argMap.containsKey('clientId') || argMap.containsKey('certificateName')){
            this.clientId = (String) argMap.get('clientId');
            this.keyName = (String) argMap.get('certificateName');
        } else {
            MDAPIClientSettings__c settings = MDAPIClientSettings__c.getInstance();
            this.clientId = Settings.APIClientKey__c;
            this.keyName = Settings.APICertificateName__c;
        }

        if (String.isBlank(this.clientId) || String.isBlank(this.keyName)) {
            throw AuthDemoApplicationException.builder(
                    AuthDemoApplicationException.MDAPI_CLIENT_ERROR_CODE_MISCONFIGURED,
                    Label.MdApiClientNotConfigured
                )
                .build();
        }
    }

    /**
     * Perform the oAuth flow.
     */
    private HttpResponse performFlow() {
        String tokenAudience = AuthDemoApplication.runningInASandbox
            ? 'https://test.salesforce.com/'
            : 'https://login.salesforce.com/';

        String tokenEndpoint = URL.getOrgDomainUrl().toExternalForm() + '/' + IDENTIFICATION_ENDPOINT_PATH;

        Auth.JWT claims = new Auth.JWT();
        claims.setAud(tokenAudience);
        claims.setIss(this.clientId);
        claims.setSub(UserInfo.getUserName());
        if (this.requiredScopes != null) {
            claims.setAdditionalClaims(new Map<String, Object>{ 'scope' => String.join(this.requiredScopes, ' ') });
        }

        try {
            Auth.JWS token;
            token = new Auth.JWS(claims, this.keyName);
            Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, token);
            return bearer.getHttpResponse();
        } catch (NoDataFoundException e) {
            throw AuthDemoApplicationException.builder(
                    AuthDemoApplicationException.MDAPI_CLIENT_ERROR_CODE_MISCONFIGURED,
                    Label.MdApiClientDataNotFound
                )
                .withCause(e)
                .build();
        }
    }

    /**
     * Parse the HTTP Response from the token endpoint.
     */
    @SuppressWarnings('PMD.EmptyCatchBlock')
    private Map<String, Object> readResponse(HttpResponse response) {
        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String accessToken = (String) body.get('access_token');
            String error = (String) body.get('error');
            String message = (String) body.get('error_description');
            String scope = (String) body.get('scope');
            if (String.isNotBlank(error)) {
                throw wrapResponseError(error, message);
            }
            if (String.isNotBlank(accessToken)) {
                List<String> scopes = null;
                if (scope != null) {
                    scopes = scope.split('\\s');
                    validateScope(scopes);
                }
                return new Map<String, Object>{ 'accessToken' => accessToken, 'scopes' => scopes };
            }
        } catch (JSONException e) {
            //NOPMD - Handled by the catch-all error code below.
        }

        System.debug(LoggingLevel.WARN, 'Non-JSON response from oAuth token flow:' + response.getBody());
        throw AuthDemoApplicationException.builder(
                AuthDemoApplicationException.MDAPI_CLIENT_ERROR_BAD_RESPONSE,
                Label.MdApiClientInvalidResponse
            )
            .withFormatArg(response.getStatus())
            .build();
    }

    /**
     * Try to be helpful interpreting the error from the oAuth token endpoint.
     */
    private AuthDemoApplicationException wrapResponseError(String errorCode, String message) {
        String friendlyLabel = null;
        if (errorCode == AuthDemoApplicationException.MDAPI_CLIENT_ERROR_INVALID_GRANT) {
            friendlyLabel = Label.MdApiClientInvalidGrant;
        } else if (errorCode == AuthDemoApplicationException.MDAPI_CLIENT_ERROR_INVALID_APP_ACCESS) {
            friendlyLabel = Label.MdApiClientInvalidAppAccess;
        } else if (errorCode == AuthDemoApplicationException.MDAPI_CLIENT_ERROR_INVALID_CLIENT_ID) {
            friendlyLabel = Label.MdApiClientInvalidClientId;
        } else if (errorCode == AuthDemoApplicationException.MDAPI_CLIENT_ERROR_INVALID_CLIENT) {
            friendlyLabel = Label.MdApiClientInvalidClient;
        } else if (errorCode == AuthDemoApplicationException.MDAPI_CLIENT_ERROR_INVALID_REQUEST) {
            friendlyLabel = Label.MdApiClientInvalidRequest;
        }

        if (friendlyLabel != null) {
            return AuthDemoApplicationException.builder(errorCode, friendlyLabel).withFormatArg(message).build();
        } else {
            return AuthDemoApplicationException.builder(errorCode, Label.MdApiClientUnrecognisedErrorCode)
                .withFormatArgs(new List<String>{ errorCode, message })
                .build();
        }
    }

    /**
     * Validate the returned scope parameter against the required scopes.
     */
    private void validateScope(List<String> foundScopes) {
        if (requiredScopes == null) {
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

/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

/**
 * An Exception class that adds an error code as well at the message. This allows a client to take special action for certain
 * errors. This is for a future when the client may need to retry a call after taking corrective action for the error.
 * This was not needed for the JWT example, but acts as a placeholder for future development.
 */
public inherited sharing class AuthDemoApplicationException extends Exception {
    // The following codes are our own, so have an ffdc prefix to prevent accidental collision with oAuth error codes.
    public static final String MDAPI_CLIENT_ERROR_CODE_MISCONFIGURED = 'ffdc_client_not_configured';
    public static final String MDAPI_CLIENT_ERROR_MISSING_SCOPES = 'ffdc_token_has_missing_scopes';
    public static final String MDAPI_CLIENT_ERROR_BAD_RESPONSE = 'ffdc_server_bad_response';
    public static final String MDAPI_CLIENT_PLEASE_RETRY = 'ffdc_please_retry';
    public static final String ERROR_INTERNAL_EXCEPTION = 'ffdc_internal_exception';

    // The following error codes are as returned by the oAuth server so must be preserved.
    public static final String MDAPI_CLIENT_ERROR_INVALID_GRANT = 'invalid_grant';
    public static final String MDAPI_CLIENT_ERROR_INVALID_APP_ACCESS = 'invalid_app_access';
    public static final String MDAPI_CLIENT_ERROR_INVALID_CLIENT_ID = 'invalid_client_id';
    public static final String MDAPI_CLIENT_ERROR_INVALID_CLIENT = 'invalid_client';
    public static final String MDAPI_CLIENT_ERROR_INVALID_REQUEST = 'invalid_request';

    /**
     * Factory method to create a Builder instance. This allows more fluent coding of AuthDemoApplicationExceptions.
     */
    public static AccessTokenExceptionBuilder builder(String errorCode, String label) {
        return new AccessTokenExceptionBuilder(errorCode, label);
    }

    private String errorCode;
    private String oAuthInitUrl;
    private String oAuthCallbackUrl;

    public void initErrorCode(String errorCode) {
        if (this.errorCode == null) {
            this.errorCode = errorCode;
        }
    }

    public void initOauthWebFlow(String initUrl, String callbackUrl) {
        if(this.oAuthInitUrl == null) {
           this.oAuthInitUrl = initUrl;
           this.oAuthCallbackUrl = callbackUrl;  
        }
    }

    public String getErrorCode() {
        return errorCode;
    }

    public Boolean isOAuthWebFlowAndRetryNeeded() {
        return oAuthInitUrl != null;
    }

    public String getOAuthInitUrl() {
        return oAuthInitUrl;
    }

    public String getOauthCallbackUrl() {
        return oAuthCallbackUrl;
    }

    public inherited sharing class AccessTokenExceptionBuilder {
        private String errorCode;
        private String message;
        private String oAuthCallbackUrl;
        private String oAuthInitUrl;
        private Exception cause;

        public AccessTokenExceptionBuilder(String errorCode, String label) {
            this.errorCode = errorCode;
            this.message = label;
        }

        public AccessTokenExceptionBuilder withFormatArg(String arg) {
            return this.withFormatArgs(new List<String>{ arg });
        }

        public AccessTokenExceptionBuilder withFormatArgs(List<String> args) {
            this.message = String.format(this.message, args);
            return this;
        }

        public AccessTokenExceptionBuilder withOAuthWebFlow(String initUrl, String callbackUrl) {
            this.oAuthInitUrl = initUrl;
            this.oAuthCallbackUrl = callbackUrl;
            return this;
        }

        public AccessTokenExceptionBuilder withCause(Exception cause) {
            this.cause = cause;
            return this;
        }

        public AuthDemoApplicationException build() {
            AuthDemoApplicationException e = new AuthDemoApplicationException(message);
            e.initErrorCode(errorCode);
            if (cause != null) {
                e.initCause(cause);
            }
            if (oAuthInitUrl != null) {
                e.initOauthWebFlow(oAuthInitUrl, oAuthCallbackUrl);
            }
            return e;
        }
    }
}

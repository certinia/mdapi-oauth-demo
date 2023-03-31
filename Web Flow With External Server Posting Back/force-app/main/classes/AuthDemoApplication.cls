/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

 /**
  * AuthDemoApplication provides common functionality for tha application as a whole. It knows its namespace and provides convenience
  * methods for executing Commands.
  * AuthDemoApplication has few dependencies in order to keep load time small.
  */
public inherited sharing class AuthDemoApplication {
    /** A well known key for passing error messages in results */
    public static final String RESULT_KEY_ERROR_MESSAGE = 'message';
    /** A well known key for passing programmatically recognizable error codes in results */
    public static final String RESULT_KEY_ERROR_CODE = 'errorCode';

    public static final String RESULT_KEY_OAUTH_WEB_FLOW = 'oAuthWebFlow';
    public static final String RESULT_KEY_OAUTH_WEB_FLOW_INIT = 'initUrl';
    public static final String RESULT_KEY_OAUTH_WEB_FLOW_CALLBACK = 'callbackUrl';

    /**
     * This application's namespace, or null if none applicable
     */
    public static String namespace {
        get {
            if (namespace == null) {
                String[] myNameParts = AuthDemoApplication.class.getName().split('\\.');
                namespace = myNameParts.size() == 2 ? myNameParts[0] : null;
            }
            return namespace;
        }
        private set;
    }

    /**
     * Prefix to apply to SObjectFields in the application. Either namespace__ or empty string.
     */
    public static String fieldPrefix {
        get {
            if (fieldPrefix == null) {
                fieldPrefix = namespace != null ? namespace + '__' : '';
            }
            return fieldPrefix;
        }
        private set;
    }

    /**
     * True if this application is running in a sandbox instance.
     */
    public static Boolean runningInASandbox {
        get {
            if (runningInASandbox == null) {
                runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return runningInASandbox;
        }
        set;
    }

    /**
     * Return a token for use with the Metadata API with 'api' scope.
     * @throws AuthDemoApplicationException if a token is not available
     */
    public static String getApiAccessToken() {
        return (String) callCommand(
            'MdApiGetTokenCommand',
            null,
            new Map<String, Object>{ 'scopes' => new List<String>{ 'api' } }
        );
    }

    /**
     * Call an internal Command class.
     */
    public static Object callCommand(String name, String verb, Map<String, Object> args) {
        Type commandType = Type.forName(namespace, name);
        if(commandType == null) {
            throw AuthDemoApplicationException.builder(AuthDemoApplicationException.ERROR_INTERNAL_EXCEPTION, 'Command class ' + name + ' not found').build();
        }
        Callable instance = (Callable) commandType.newInstance();
        return instance.call(verb, args);
    }

    /**
     * Call an internal Command class and wrap exceptions as needed for LWC.
     * 
     * The use of Command/Callable Pattern behind facades manages dependencies and therefore cold start cost for the facade. Lightning
     * appears to strongly encourage the use of a single Controller class as a facade for a lighting component or whole app. This is a result
     * of the need to grant class access permission to the Controller. Lots of small controllers, or LWC components picking off methods from
     * multiple domain specific controllers, would rapidly cause confusion setting up permissions. 
     * 
     * Command Pattern allows a call to the Controller  to load only
     * the command implementation that it needs along with that command's dependencies. The system does not have to class-load all possible
     * operations of the LWC component just to put the initial state on screen. Another advantage of Command Pattern is that boilerplate code
     * such as error handling can be shared.
     * 
     * Command Pattern only makes sense for facades, where different entry points branch off in very different directions. It is also used in this central
     * class to keep its dependencies down.
     */
    public static Object callCommandForLwc(String name, String verb, Map<String, Object> args) {
        try {
            Type commandType = Type.forName(namespace, name);
            if(commandType == null) {
                throw AuthDemoApplicationException.builder(AuthDemoApplicationException.ERROR_INTERNAL_EXCEPTION, 'Command class ' + name + ' not found').build();
            }
            Callable instance = (Callable) commandType.newInstance();
            return instance.call(verb, args);
        } catch (AuthDemoApplicationException e1) {
            throw formatAuraHandledException(e1);
        } catch (Exception e2) {
            System.debug(LoggingLevel.ERROR, e2.getTypeName() + ': ' + e2.getMessage() + '\n' + e2.getStackTraceString());
            throw formatAuraHandledException(AuthDemoApplicationException.ERROR_INTERNAL_EXCEPTION,e2.getMessage());
        }
    }

    private static AuraHandledException formatAuraHandledException(AuthDemoApplicationException e) {
        Map<String, Object> payload = new Map<String, Object>{
                RESULT_KEY_ERROR_CODE => e.getErrorCode(),
                RESULT_KEY_ERROR_MESSAGE => e.getMessage()
        };

        if(e.isOAuthWebFlowAndRetryNeeded()) {
            payload.put(RESULT_KEY_OAUTH_WEB_FLOW, new Map<String, String>{
                RESULT_KEY_OAUTH_WEB_FLOW_INIT => e.getOAuthInitUrl(),
                RESULT_KEY_OAUTH_WEB_FLOW_CALLBACK => e.getOauthCallbackUrl()
            });
        }

        String message = JSON.serialize(payload);
        return new AuraHandledException(message);
    }


    private static AuraHandledException formatAuraHandledException(String errorCode, String errorMessage) {
        String message = errorMessage;
        AuraHandledException e = new AuraHandledException(message);
        // We have found this necessary in some circumstances. It may not be the case now, in which case this code could be removed.
        e.setMessage(message);
        return e;
    }
}

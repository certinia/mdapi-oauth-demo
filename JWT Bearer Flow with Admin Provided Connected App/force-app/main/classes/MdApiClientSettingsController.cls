/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

 /**
  * LWC Controller Facade for the Metadata API Client Settings Component.
  */
public with sharing class MdApiClientSettingsController {
    @AuraEnabled
    public static Map<String, Object> getCurrentSettings() {
        return (Map<String, Object>) AuthDemoApplication.callCommandForLwc(
            'MdApiClientSettingsCommand',
            'load',
            null
        );
    }

    @AuraEnabled
    public static void saveSettings(Map<String, Object> config) {
        AuthDemoApplication.callCommandForLwc(
            'MdApiClientSettingsCommand',
            'save',
            config
        );
    }

    /**
     * Test the connection
     */
    @AuraEnabled
    public static Map<String, Object> testConnection(String consumerKey, String certificateName, List<String> scopes) {
        Map<String, Object> result = (Map<String, Object>) AuthDemoApplication.callCommandForLwc(
            'MdApiGetTokenCommand',
            null,
            new Map<String, Object>{
                'clientId' => consumerKey,
                'certificateName' => certificateName,
                'scopes' => scopes,
                'returnScopes' => true
            }
        );
        return new Map<String, Object>{
            // Whitelisted response keys.
            // We do not leak any other information from the response, especially the token.
            'scopes' => result.get('scopes')
        };
    }
}

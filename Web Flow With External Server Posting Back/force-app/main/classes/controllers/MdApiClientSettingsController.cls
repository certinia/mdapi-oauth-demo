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
}

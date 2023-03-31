/*
 * Copyright (c) 2023 FinancialForce.com, inc. All rights reserved.
 */

/**
 * LWC Controller Facade for the metadata invocation demo.
 */
public with sharing class MdApiInvocationDemoController {
    @AuraEnabled
    public static Map<String, Object> runDemo() {
        return (Map<String, Object>) AuthDemoApplication.callCommandForLwc('GetObjectInfoCommand', 'account', null);
    }

    @AuraEnabled
    public static Map<String,Boolean> getCacheStatus() {
        return (Map<String,Boolean>) AuthDemoApplication.callCommandForLwc('CachedTokenCommand', 'read', null);
    }

    @AuraEnabled
    public static Map<String,Boolean> clearAccessToken() {
        return (Map<String,Boolean>) AuthDemoApplication.callCommandForLwc('CachedTokenCommand', 'clearAccessToken', null);
    }

    @AuraEnabled
    public static Map<String,Boolean> clearRefreshToken() {
        return (Map<String,Boolean>) AuthDemoApplication.callCommandForLwc('CachedTokenCommand', 'clearRefreshToken', null);
    }

}

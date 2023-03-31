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
}

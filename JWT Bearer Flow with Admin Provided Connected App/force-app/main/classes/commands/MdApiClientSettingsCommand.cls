/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Read and write configuration and return the following structure.
 *
 * consumerKey: string
 * consumerKeyLabel: string field label for the consumer key
 * certificate: string
 * certificateLabel: string field label for the certificate name
 * requiredScopes: string[]
 */
public inherited sharing class MdApiClientSettingsCommand implements Callable {
    /**
     * Describe the configuration known to this system.
     * Provide the scopes that it needs.
     */
    private static final List<string> REQUIRED_SCOPES = new List<String>{ 'api' };

    /**
     * Implement the Callable Interface for this Command Object.
     */
    public Object call(String verb, Map<String, Object> arguments) {
        switch on verb {
            when 'load' {
                return loadSettings();
            }
            when 'save' {
                return saveSettings(arguments);
            }
            when else {
                return null;
            }
        }
    }

    /**
     * Read configuration and return the following structure
     *
     * settingsTitle: string
     * configs: array of Config
     *
     * where Config is
     *
     * key: string
     * title: string
     * consumerKey: string
     * consumerKeyLabel: string
     * certificate: string
     * certificateLabel: string
     * requiredScopes: string[]
     */
    private Object loadSettings() {
        Map<String, Object> result = new Map<String, Object>();

        MDAPIClientSettings__c settings = MDAPIClientSettings__c.getInstance();
        if (settings == null) {
            settings = (MDAPIClientSettings__c) MDAPIClientSettings__c.SObjectType.newSObject(null, true);
        }

        DescribeSObjectResult describe = MDAPIClientSettings__c.SObjectType.getDescribe();
        result.put('settingsTitle', describe.getLabel());

        result.putAll(new Map<String, Object>{
            'consumerKey' => settings.APIClientKey__c,
            'consumerKeyLabel' => MDAPIClientSettings__c.APIClientKey__c.getDescribe().getLabel(),
            'certificate' => settings.APICertificateName__c,
            'certificateLabel' =>MDAPIClientSettings__c.APICertificateName__c.getDescribe().getLabel(),
            'requiredScopes' => REQUIRED_SCOPES
        });

        return result;
    }

    private Object saveSettings(Map<String, Object> config) {
        MDAPIClientSettings__c settings = MDAPIClientSettings__c.getOrgDefaults();
        if (settings == null) {
            settings = (MDAPIClientSettings__c) MDAPIClientSettings__c.SObjectType.newSObject(null, true);
        }

        settings.APIClientKey__c = (String) config.get('consumerKey');
        settings.APICertificateName__c = (String) config.get('certificate');

        upsert settings; //NOPMD - Protected Custom Setting does not have CRUD

        return null;
    }
}

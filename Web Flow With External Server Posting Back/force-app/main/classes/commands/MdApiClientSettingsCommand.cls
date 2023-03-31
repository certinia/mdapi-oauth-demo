/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Read and write configuration and return the following structure.
 *
 * allowWebFlow: boolean
 * allowRefreshTokens: boolean
 */
public inherited sharing class MdApiClientSettingsCommand implements Callable {
	private static final String KEY_ALLOW_REFRESH_TOKENS = 'allowRefreshTokens';
	private static final String KEY_USE_LARGE_TOKEN_STORE = 'useLargeTokenStore';

    /**
     * Implement the Callable Interface for this Command Object.
     */
    public Object call(String verb, Map<String, Object> arguments) {
        switch on verb {
            when 'load' {
                return loadSettings();
            }
            when 'save' {
                saveSettings(arguments);
                return null;
            }
            when else {
                return null;
            }
        }
    }

    /**
     * Read configuration
     */
    private Object loadSettings() {
        Map<String, Object> result = new Map<String, Object>();
        MDAPIClientSettings__c settings = MdApiSettingsSelector.getSettings();
        result.put(KEY_USE_LARGE_TOKEN_STORE, settings.UseLargeTokenStore__c);
        result.put(KEY_ALLOW_REFRESH_TOKENS, settings.AllowRefreshTokens__c);
        return result;
    }

    private void saveSettings(Map<String, Object> config) {
        MDAPIClientSettings__c settings = MdApiSettingsSelector.getSettings();

        Boolean useLargeTokenStore = (Boolean) config.get(KEY_USE_LARGE_TOKEN_STORE);
        if(useLargeTokenStore != null) {
            settings.UseLargeTokenStore__c = useLargeTokenStore;
        }

        Boolean allowRefreshTokens = (Boolean) config.get(KEY_ALLOW_REFRESH_TOKENS);
        if(allowRefreshTokens != null) {
            settings.AllowRefreshTokens__c = allowRefreshTokens;
        }

        upsert settings; //NOPMD - Protected Custom Setting does not have CRUD
    }
}

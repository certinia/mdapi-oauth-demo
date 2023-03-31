/*
 * Copyright 2023 FinancialForce.com
 */

 /**
  * Selector Enterprise Pattern for the Client Settings custom setting.
  * Selector is needed here in order to provide correct defaulting behavior when no setting has been
  * created.
  */
public inherited sharing class MdApiSettingsSelector
{
    /**
     * Load the current settings in a repeatable way that handles the situation where no settings have been saved.
     */
    public static MDAPIClientSettings__c getSettings() {
        MDAPIClientSettings__c settings = MDAPIClientSettings__c.getOrgDefaults();
        if(settings.Id == null) {
             settings =  (MDAPIClientSettings__c) MDAPIClientSettings__c.SObjectType.newSObject(null, true);
        }
        return settings;
    }
}
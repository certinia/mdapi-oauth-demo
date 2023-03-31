@IsTest
public inherited sharing class MdApiSettingsSelectorTest
{
    @IsTest
    public static void givenNoSavedSettings_ICanGetCorrectDefaults() {
        MDAPIClientSettings__c settings = MdApiSettingsSelector.getSettings();
        System.assertEquals(true, settings.AllowRefreshTokens__c);
    }

        @IsTest
    public static void givenSavedSettings_ICanGetCorrectValues() {

        MDAPIClientSettings__c newInstance = new MDAPIClientSettings__c(
            AllowRefreshTokens__c = false
        );
        insert newInstance;

        Test.startTest();
        MDAPIClientSettings__c settings = MdApiSettingsSelector.getSettings();      
        System.assertEquals(false, settings.AllowRefreshTokens__c);
        Test.stopTest();
    }

    @IsTest
    public static void ifAPartialSettingsHasBeenSaved_defaultsArePreserved() {

        MDAPIClientSettings__c newInstance = new MDAPIClientSettings__c(
            UseLargeTokenStore__c = true
        );
        insert newInstance;

        Test.startTest();
        MDAPIClientSettings__c settings = MdApiSettingsSelector.getSettings();      
        System.assertEquals(true, settings.AllowRefreshTokens__c);
        Test.stopTest();
    }

}
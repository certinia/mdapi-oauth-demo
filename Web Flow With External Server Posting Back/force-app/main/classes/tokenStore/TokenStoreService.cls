/*
 * Copyright 2023 FinancialForce.com
 */

/**
 * Provide storage for OAuth Tokens.
 * This class uses the Service Facade pattern from Enterprise Patterns, though unlike
 * Enterprise Patterns it allows the implementation to be chosen at runtime.
 */
public inherited sharing class TokenStoreService {

    @TestVisible
    private static API instance {
        get {
            if(instance == null) {
                MDAPIClientSettings__c settings = MdApiSettingsSelector.getSettings();
                instance = settings.UseLargeTokenStore__c ? 
                    (TokenStoreService.API ) new SObjectTokenStore() : 
                    (TokenStoreService.API ) new ProtectedSettingTokenStore();
            }
            return instance;
        }
        private set;
    }

    /**
     * Load the current user's tokens
     */
    public static Dto getToken() {
        return instance.getToken();
    }

    /**
     * Store the current user's tokens
     */
    public static void storeToken(Dto token) {
        instance.storeToken(token);
    }

    /**
     * Factory method to create a DTO for an access token only
     */
    public static Dto newAccessToken(String accessToken) {
        return new Dto(accessToken, null);
    }

    /**
     * Factory method to create a DTO for a refresh token only
     */
    public static Dto newRefreshToken(String refreshToken) {
        return new Dto(null, refreshToken);
    }

    /**
     * Factory method to create a DTO with both access and refresh tokens
     */
    public static Dto newTokenPair(String accessToken, String refreshToken) {
        return new Dto(accessToken, refreshToken);
    }

    /**
     * Factory method to create an empty DTO.
     */
    public static Dto newEmptyToken() {
        return new Dto(null, null);
    }

    /**
     * API interface for implementations of the service.
     */
    public interface API {
        Dto getToken();
        void storeToken(Dto token);
    }

    /**
     * Represent a user's OAuth tokens.
     */
    public inherited sharing class Dto {
        /** The short lived OAuth access token used to access services */
        public final String accessToken;
        /** The long lived OAuth refresh token used to request a new Access Token */
        public final String refreshToken;

        public Dto(String accessToken, String refreshToken) {
            this.accessToken = accessToken;
            this.refreshToken = refreshToken;
        }

        public Boolean isEmpty() {
            return String.isBlank(accessToken) && String.isBlank(refreshToken);
        }
    }
}
